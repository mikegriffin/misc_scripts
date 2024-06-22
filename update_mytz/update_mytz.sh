#!/usr/bin/env bash

# note, current mysql/mariadb docs indicate that a restart of daemon will be required to take effect

tzdir=/usr/share/zoneinfo/
cmd="/usr/bin/mysql_tzinfo_to_sql --skip-write-binlog /usr/share/zoneinfo | mysql -u root mysql"

while true; do
	/usr/bin/inotifywait \
		--event=modify \
		--event=attrib \
		--event=create \
		--event=delete \
	        --recursive \
		"${tzdir}" &> /dev/null
        while pgrep -x 'dnf|rpm|yum' &> /dev/null;
		do sleep 1
	done
		eval "${cmd}"
done
