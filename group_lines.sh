### Usage
## cat generate_sorted_table_list.sql
# select concat('OPTIMIZE LOCAL TABLE `', table_schema, '`', '`', table_name, '`;') from information_schema.tables where table_schema='foo' order by data_length desc;

## mysql -s < generate_sorted_table_list.sql > tables

## ./group_lines.sh 3 tables

### pass in a number of files you want
### and the original file name
### unlike split, each line goes to the next file in a ring

[[ $1 -gt 0 ]] || exit
[[ -f $2 ]] || exit
[[ $# -eq 2 ]] || exit

groups=$1
file=$2
i=1
epoch=$(date +'%s')

for j in $(seq 1 $groups); do
[[ -f "$file.$j.txt" ]] &&
 mv $file.$j.txt $file.$j.txt.old.$epoch &&
 echo "renaming $file.$j.txt to $file.$j.txt.old.$epoch";
done

if find . -name "$file"'\.[0-9]*txt' -exec false {} + &> /dev/null
then true
else
 echo 'fail: files larger than group size found: ' &&
 echo -n "ls -l $file" && echo '\.[0-9]*txt' &&
 exit
fi

write_line() {
echo "Writing $line to $file.$i.txt";
echo "$line" >> $file.$i.txt
i=$((i+1))
[[ $i -gt $groups ]] && i=1
}

while read -r line; do
write_line $i
done <$file
