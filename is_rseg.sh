while true; do
	rseg1=$(mysql -ss -e "select count from information_schema.innodb_metrics where name = 'trx_rseg_history_len';")
	sleep 1
	rseg2=$(mysql -ss -e "select count from information_schema.innodb_metrics where name = 'trx_rseg_history_len';")
	[[ $rseg1 -gt $rseg2 ]] && diff=$(( $rseg1 - $rseg2 )) && echo "(-$diff) $rseg2"
	[[ $rseg2 -gt $rseg1 ]] && diff=$(( $rseg2 - $rseg1 )) && echo "(+$diff) $rseg2"
	[[ $rseg2 -eq $rseg1 ]] && diff=$(( $rseg2 - $rseg1 )) && echo "(+$diff) $rseg2"
done
