#!/bin/bash

# Skip a specific table that pt-table-checksum tried to check
# Should print 0 when sleep() is called and then 1 when skip counter is set before starting slave

my_slave_socket='/foo/mysql.sock'
my_opts_file='/root/.foo.tmp.my.cnf'

my_checksum_db='percona_checksum_01'
my_skip_table_dbname='db_name_01'
my_skip_table_tablename='table_name_01'

while true; do
mysql --defaults-file="${my_opts_file}" -A -S "${my_slave_socket}" -ss <<< 
                                                                           "SELECT CONCAT('KILL ',ID,'; KILL ',ID,'; SELECT SLEEP(1); STOP SLAVE SQL_THREAD; SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; SELECT @@SQL_SLAVE_SKIP_COUNTER; START SLAVE;')
                                                                            FROM information_schema.PROCESSLIST 
                                                                            WHERE USER='system user' AND INFO LIKE 'REPLACE INTO \`"${my_checksum_db}"\`.\`checksum\`%$"{my_skip_table_dbname}"%$"{my_skip_table_tablename}"%'" |
mysql --defaults-file="${my_opts_file}" -A -S "${my_slave_socket}" -ss;
sleep 0.5;
done
