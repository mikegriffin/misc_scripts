#!/usr/bin/env bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
set -euf -o pipefail

# Some inspiration form https://gist.github.com/jaytaylor/6802090

# Install to root user's cron, like so:
# 1 0 * * * /root/rotate_pg_log.sh | /usr/bin/logger -t /root/rotate_pg_log.sh
#
# This script will overwrite last week's compressed log each morning
# gzip, coreutils, lsof, logger, and sudo are assumed to be installed. pigz is optional.

# Script must run as root.
cd / && test "${EUID}" -ne 0 && echo "[ERROR] this script must be run as root" && exit 1

# Best effort discover bindir via longest running postmaster
pg_bindir=$(dirname $(readlink -f /proc/$(pgrep -o postmaster)/exe))
test "${pg_bindir}" == "/proc" && echo "[ERROR] postmaster not found to be running" && exit 1
pg_psql="psql"
test -f "${pg_bindir}/psql" && pg_psql="${pg_bindir}/psql"

# Validate connection to PostgreSQL
set +e
pg_testcon=$(sudo -u postgres "${pg_psql}" -qt -c "select 456" 2> /dev/null)
set -e
test -z "${pg_testcon}" && echo "[ERROR] Unable to connect to PostgreSQL" && exit 1

# Validate default log_filename configuration value is in use
pg_log_filename=$(sudo -u postgres "${pg_psql}" -qt -c "show log_filename" | tr -d ' ')
test "${pg_log_filename}" != "postgresql-%a.log" && echo "[ERROR] this script expects log_filename='postgresql-%a.log'" && exit 1

# Discover full path to log_directory
pg_logdir=$(sudo -u postgres "${pg_psql}" -qt -c "select string_agg(setting,'/' order by name asc) from pg_settings where name in ('data_directory','log_directory')" | tr -d ' ')

# Make sure the log file is no longer in use before compressing.
yesterday=$(date -d"yesterday" +"%a")
if lsof -nn "${pg_logdir}/postgresql-${yesterday}.log" &> /dev/null; then
   echo "[WARNING] ${pg_logdir}/postgresql-${yesterday}.log still in use; Sleeping 30 seconds before retry"; sleep 30
   lsof -nn "${pg_logdir}/postgresql-${yesterday}.log" &> /dev/null && echo "[ERROR] ${pg_logdir}/postgresql-${yesterday}.log still in use" && exit 1
fi

# Discover pigz or fallback to gzip # FIXME style
compressor="pigz"
[[ -x $(type -fP pigz) ]] || compressor="gzip"

# Next week, "postgres: logger" will create a new uncompressed file.
test -f "${pg_logdir}/postgresql-${yesterday}.log" && ${compressor} -f "${pg_logdir}/postgresql-${yesterday}.log"
