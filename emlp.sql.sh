seconds=5
socket=/mnt/data/mysqldata/mysql.sock

echo $socket
counter=0
sbm=0
while true; do
	emlp1=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	sleep $seconds
	rmlf=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Relay_Master_Log_File/ {print $2}')
	emlp2=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	rls=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Relay_Log_Space/ {print $2}')
	mrls=$(mysql -S $socket -ss -e "select @@max_relay_log_size")
        old_sbm=$sbm
	sbm=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Seconds_Behind_Master/ {print $2}')
	[[ $counter -eq 0 ]] && echo -e "\nprocessed/s, binlog, offset, sbm, sbm_delta, eta, info"
	date
	[[ $emlp1 -gt $emlp2 ]] && echo "recalculating"
	[[ $emlp2 -gt $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) &&
	  echo -n "$(( $diff/$seconds )) $rmlf $emlp2 Seconds_Behind_Master: $sbm (change: $(echo "scale=2; $old_sbm - $sbm" | bc -lq)) eta: $(echo "scale=2; ($rls - $emlp2)/($diff/$seconds)/3600" | bc -lq) hours" &&
	  [[ $(( $mrls * 2 ))  -gt $rls ]] && echo " (eta probably wrong due to Replica_IO backlog - sleeping 5 extra seconds)" && sleep 5 || echo
	[[ $emlp2 -eq $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) &&
	  echo "0 $rmlf $emlp2"
	counter=$((counter+1)) && [[ $counter -gt $seconds && $counter -gt 30 ]] && counter=0
done
