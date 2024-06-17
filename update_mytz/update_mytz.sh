#!/usr/bin/env bash

tzdir=/usr/share/zoneinfo/
cmd="/usr/bin/mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql"

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
