seconds=10

while true; do
	emlp1=$(mysql -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	sleep $seconds
	emlp2=$(mysql -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	[[ $emlp1 -gt $emlp2 ]] && diff=$(( $emlp1 - $emlp2 )) && echo "$(( $diff/$seconds )) (-$diff) $emlp2"
	[[ $emlp2 -gt $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) && echo "$(( $diff/$seconds )) (+$diff) $emlp2"
	[[ $emlp2 -eq $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) && echo "0 (+$diff) $emlp2"
done
