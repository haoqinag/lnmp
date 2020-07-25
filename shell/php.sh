#!/bin/bash
#author:lhq
##site:www.testcn.top
#
cd /root/
check_os()
{
	grep 'CentOS' /etc/redhat-release
	[ $? -ne 0 ] && echo "本脚本适合centos系统！" && exit
	[ -n "$(grep ' 7\.' /etc/redhat-release 2> /dev/null)" ] && os=7
	[ -n "$(grep ' 6\.' /etc/redhat-release 2> /dev/null)" ] && os=6
}
up_cmake(){
	cmake_ver=$(cmake --version |awk '/^cmake/{print $3}')
	ver=${cmake_ver:0:1}
	if [ "$ver" -lt 3 ];then
		yum remove -y cmake
		wget http://www.testcn.top/hao_soft/php/cmake-3.6.2.tar.gz
		tar zxf cmake-3.6.2.tar.gz && cd cmake-3.6.2
		./bootstrap && gmake && gmake install
		cmake >/dev/null 2>&1
		[ "$?" -eq 0 ] && echo "cmake install success"
	fi
		cd /root/
}
install_libzip(){
	libver=`rpm -qa libzip`
	ver=$(echo ${libver:9:2})
	if [ "$ver" -le 10 ];then
		yum remove -y libzip
		wget http://www.testcn.top/hao_soft/php/libzip-1.5.2.tar.gz
		tar zxf libzip-1.5.2.tar.gz && cd libzip-1.5.2
		mkdir build && cd build && cmake .. && make && make install
		echo "/usr/lib64" > /etc/ld.so.conf
		echo "/usr/local/lib64" >> /etc/ld.so.conf
		echo "/usr/local/lib" >> /etc/ld.so.conf
		echo "/usr/lib" >> /etc/ld.so.conf
		ldconfig
	fi
	cd /root/
}
check_os
cd /root/
[ ! -n "$1" ] && phpver=5.6.40 || phpver=$1
phpflag=$(echo ${phpver:0:3}|sed 's/\.//')
[ -f "/www/flag/php${phpflag}.lock" ] && exit
if [ "$phpflag" == "73" ];then
	yum install cmake libzip -y
	up_cmake
	install_libzip

fi
wget http://www.testcn.top/hao_soft/php/php-${phpver}.tar.gz
tar zxf php-${phpver}.tar.gz
cd /root/php-${phpver}
./configure --prefix=/www/php-${phpver} --with-config-file-scan-dir=/www/php-${phpver}/php.d --with-config-file-path=/www/php-${phpver}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql --with-mysqli --with-pdo-mysql --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext  --enable-opcache --enable-intl
make -j `cat /proc/cpuinfo |grep processor |wc -l` && make install
cp /root/php-${phpver}/php.ini-production /www/php-${phpver}/etc/php.ini
sed -i 's@;date.timezone =@date.timezone =Asia/Shanghai@' /www/php-${phpver}/etc/php.ini
sed -i 's@disable_functions =@disable_functions =passthru,exec,system,shell_exec,proc_open,popen,pcntl_exec,socket_bind,stream_socket_server@' /www/php-${phpver}/etc/php.ini
cp /www/php-${phpver}/etc/php-fpm.conf.default /www/php-${phpver}/etc/php-fpm.conf
mv /www/php-${phpver}/etc/php-fpm.conf /www/php-${phpver}/etc/php-fpm.conf_bak
cat >/www/php-${phpver}/etc/php-fpm.conf<<EOF
[global]
log_level = notice

[www]
listen = /tmp/php${phpflag}.sock
listen.backlog = 2048
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_${phpflag}_status
pm.max_children = 150
pm.start_servers = 10
pm.min_spare_servers = 10
pm.max_spare_servers = 30
request_terminate_timeout = 100
slowlog = log/\$pool.log.slow
request_slowlog_timeout = 30
EOF
[ -d "/www/php-${phpver}/log" ] || mkdir /www/php-${phpver}/log
cp /root/php-${phpver}/sapi/fpm/init.d.php-fpm /etc/init.d/php${phpflag}-fpm
chmod +x /etc/init.d/php${phpflag}-fpm
if [ "${os}" -eq 6 ];then
	chkconfig --add php${phpflag}-fpm
	chkconfig php${phpflag}-fpm on
	service php${phpflag}-fpm start
else
	chmod +x /etc/rc.d/rc.local
	echo "/etc/init.d/php${phpflag}-fpm start" >>/etc/rc.d/rc.local
	/etc/init.d/php${phpflag}-fpm start
fi
rm -rf php-${phpver}.tar.gz
[ -d "/www/flag/" ] || mkdir -p /www/flag/
[ $? -eq 0 ] && touch /www/flag/php${phpflag}.lock
curl "http://127.0.0.1:8000/success_install?softname=php${phpflag}&dir=/www/${phpver}" >/www/install.log
