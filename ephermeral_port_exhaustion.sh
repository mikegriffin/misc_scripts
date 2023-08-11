for i in $(ss -nlt | awk 'NR>1 {if($4 ~ /]/) {split($4, a, "]:"); print a[2]} else {if($4 ~ /*/) {split($4, a, ":"); print a[2]} else {split($4, a, ":"); print a[2]}}}' |
                     awk '{ tot[$0]++ } END {for (i in tot) print i}');
do
          ss -nt sport "${i}" |
                     awk 'NR> 1 {if($4 ~ /\[/) {printf $4" "; split($5, a, "]"); print a[1]"]"} else {printf $4" "; split($5, a, ":"); print a[1]}}';
done |
awk -v x=$(sysctl -n net.ipv4.ip_local_port_range | awk '{print $2-$1}') '{ tot[$0]++ } END {for (i in tot) if(tot[i]>x/2) print tot[i],i}'
