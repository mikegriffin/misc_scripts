seconds=10
socket=/mnt/cbs/mariadb/mysql.sock

while true; do
	emlp1=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	sleep $seconds
	emlp2=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	rls=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Relay_Log_Space/ {print $2}')
	#[[ $emlp1 -gt $emlp2 ]] && diff=$(( $emlp1 - $emlp2 )) &&
	  #echo "$(( $diff/$seconds )) $emlp2 eta: $(echo "scale=2; ($rls - $emlp2)/($diff/$seconds)/3600" | bc -lq) hours"
	[[ $emlp1 -gt $emlp2 ]] && echo "recalculating"
	[[ $emlp2 -gt $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) &&
	  echo "$(( $diff/$seconds )) $emlp2 eta: $(echo "scale=2; ($rls - $emlp2)/($diff/$seconds)/3600" | bc -lq) hours"
	[[ $emlp2 -eq $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) &&
	  echo "0 $emlp2"
done
