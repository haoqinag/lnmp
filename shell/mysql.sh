#!/bin/bash
#
#
cd /root/
sqlver=5.7.30
[ -d "/www" ] || mkdir /www
[ -f "/www/flag/MYSQL.lock" ] && exit
yum install libaio ncurses-libs* -y
id mysql >/dev/null 2>&1
[ $? -ne 0 ] && useradd -s /usr/sbin/nologin -M mysql
cd /root/
[ -f "/root/mysql.tar.gz" ] || wget -t 0 -O mysql.tar.gz http://www.testcn.top/hao_soft/mysql/mysql-${sqlver}-linux-glibc2.12-x86_64.tar.gz

tar -zxf /root/mysql.tar.gz -C /www/
sqlname=`ls -l /www/ | awk 'END{print $NF}'`
mv /www/${sqlname} /www/mysql
[ -f "/etc/my.cnf" ] && mv /etc/my.cnf /etc/my.cnf_bak
cat >/etc/my.cnf <<EOF
[client]
port = 3306
socket = /tmp/mysql.sock

[mysqld]
port = 3306
socket = /tmp/mysql.sock
datadir = /www/mysql/data
default_storage_engine = MyISAM
performance_schema_max_table_instances = 400
table_definition_cache = 400
skip-external-locking
key_buffer_size = 128M
max_allowed_packet = 10G
table_open_cache = 512
sort_buffer_size = 2M
net_buffer_length = 4K
read_buffer_size = 2M
read_rnd_buffer_size = 256K
myisam_sort_buffer_size = 32M
thread_cache_size = 64
query_cache_size = 64M
sql-mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES

explicit_defaults_for_timestamp = true
#skip-name-resolve
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id = 1
expire_logs_days = 10
slow_query_log=1
slow-query-log-file=/www/mysql/data/mysql-slow.log
long_query_time=3
#log_queries_not_using_indexes=on
early-plugin-load = ""

innodb_data_home_dir = /www/mysql/data
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = /www/mysql/data
innodb_buffer_pool_size = 512M
innodb_log_file_size = 256M
innodb_log_buffer_size = 64M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
innodb_max_dirty_pages_pct = 90
innodb_read_io_threads = 24
innodb_write_io_threads = 24

[mysqldump]
quick
max_allowed_packet = 500M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 128M
sort_buffer_size = 2M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF

cp /www/mysql/support-files/mysql.server /etc/init.d/mysql
sed -i '46c basedir=/www/mysql' /etc/init.d/mysql
sed -i '47c datadir=/www/mysql/data' /etc/init.d/mysql
[ -d "/www/mysql/data" ] || mkdir -p /www/mysql/data
chown mysql:mysql /www/mysql/data
/www/mysql/bin/mysqld --initialize --datadir=/www/mysql/data >/tmp/mysql.log --user=mysql 2>&1
echo "export PATH=$PATH:/www/mysql/bin" >/etc/profile.d/mysql.sh
source /etc/profile.d/mysql.sh
mysqlpassword=`cat /tmp/mysql.log |awk 'END{print $NF}'`
/etc/init.d/mysql start
[ $? -eq 0 ] && mysqladmin -uroot -p${mysqlpassword} password "12344321" >/dev/null 2>&1
[ -d "/www/flag/" ] || mkdir -p /www/flag/
[ $? -eq 0 ] && [ $? -eq 0 ] && touch /www/flag/MYSQL.lock
curl 'http://127.0.0.1:8000/success_install?softname=MYSQL&dir=/www/mysql' >/www/install.log







