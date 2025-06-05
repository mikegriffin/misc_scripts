# user configuration
seconds=2 # increase this if output is too bouncy
socket=/mnt/data/mysqldata/mysql.sock

# internal variables
counter=0
output_description="binlog, offset, bytes/s, sbm, sbm_delta, eta, error"
echo "Using: $socket"
while true; do
	emlp1=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	sleep $seconds
	rmlf=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Relay_Master_Log_File/ {print $2}')
	emlp2=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Exec_Master_Log_Pos/ {print $2}')
	[[ $counter -eq 0 ]] && old_rls=$rls
	old_rls=${old_rls:=0}
	rls=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Relay_Log_Space/ {print $2}')
	mrls=$(mysql -S $socket -ss -e "select @@max_relay_log_size")
	sbm=${sbm:=0}
        old_sbm=$sbm
	sbm=$(mysql -S $socket -ss -e "show slave status\G" | awk '/Seconds_Behind_Master/ {print $2}')
	[[ $counter -eq 0 ]] && [[ $old_rls -gt 0 && $rls -gt $old_rls && $(echo "scale=2; $rls / $mrls > 1" | bc -lq) -eq 1 &&
					$(echo "scale=2; (($rls-$old_rls))>($mrls/100)" | bc -lq) -eq 1 ]] &&
			echo "##############" &&
			echo "Relay log space grew to $rls - eta likely to climb due to Replica_IO backlog" &&
			echo "##############" &&
			echo
	[[ $counter -eq 0 ]] && echo -e "\n##########################################\n$output_description" && counter=1 && continue
	date
	[[ $emlp1 -gt $emlp2 ]] && echo -ne "##############\nrecalculating since we switched to next log during check\n##############" &&
		                   echo -ne "\n\n##########################################\n$output_description"
	[[ $emlp2 -gt $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) &&
			echo -n "$rmlf $emlp2 $(( $diff/$seconds )) Seconds_Behind_Master: $sbm (advanced $(echo "scale=2; $old_sbm - $sbm" | bc -lq)" &&
			echo -en " seconds in $seconds seconds) eta: " &&
			ETA=$(echo "scale=2; ($rls - $emlp2)/($diff/$seconds)/3600" | bc -lq) &&
			{ ISNEG=$(echo "${ETA}<0" | bc -lq) ;} &&
			{ [[ "${ISNEG}" -eq 0 ]] || ETA=0 ;} &&
			echo -en "${ETA} hours\n"
	[[ $emlp2 -eq $emlp1 ]] && diff=$(( $emlp2 - $emlp1 )) &&
	  echo "0 $rmlf $emlp2"
	counter=$((counter+1)) && [[ $counter -gt $seconds && $counter -gt 10 ]] && counter=0
done
