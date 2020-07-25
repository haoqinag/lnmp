#!/bin/bash
#author:hao
#site:www.testcn.top
#auto install nginx
#
#判断是否centos系统
cd /root/
[ -f "/www/flag/Nginx.lock" ] && curl 'http://127.0.0.1:8000/success_install?softname=Nginx&dir=/www/nginx' >/www/install.log && exit
nginx_ver=1.17.9
check_os()
{
	grep 'CentOS' /etc/redhat-release
	[ $? -ne 0 ] && echo "本脚本适合centos系统！" && exit
	[ -n "$(grep ' 7\.' /etc/redhat-release 2> /dev/null)" ] && os=7
	[ -n "$(grep ' 6\.' /etc/redhat-release 2> /dev/null)" ] && os=6
}
check_os
#install nginx
id www >/dev/null 2>&1
[ $? -ne 0 ] && useradd -s /sbin/nologin -M www
[ -d '/www' ] || mkdir /www
yum install gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel unzip psmisc -y
cd /root/
wget http://www.testcn.top/hao_soft/nginx/nginx-${nginx_ver}.tar.gz
wget http://www.testcn.top/hao_soft/nginx/headers-more-nginx-module-0.33.zip
[ -f "nginx-${nginx_ver}.tar.gz" ] || exit
[ -f "headers-more-nginx-module-0.33.zip" ] || exit
unzip headers-more-nginx-module-0.33.zip
tar -zxvf nginx-${nginx_ver}.tar.gz
cd /root/nginx-${nginx_ver}
./configure --prefix=/www/nginx-${nginx_ver} --user=www --group=www --with-pcre --with-http_v2_module --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-mail --with-mail_ssl_module --with-file-aio --with-threads --with-stream --with-stream_ssl_module --add-module=/root/headers-more-nginx-module-0.33
make -j `cat /proc/cpuinfo |grep processor |wc -l` && make install
ln -s /www/nginx-${nginx_ver} /www/nginx
[-d '/www/panel/nginx/vhost' ] || mkdir -p /www/panel/nginx/vhost
wget -O /etc/init.d/nginx http://www.testcn.top/hao_soft/nginx/nginx.zip
mv /www/nginx/conf/nginx.conf /www/nginx/conf/nginx.conf_bak
wget -O /www/nginx/conf/nginx.conf http://www.testcn.top/hao_soft/nginx/nginx_set.zip
chmod a+x /etc/init.d/nginx
if [ "${os}" -eq 6 ];then
	chkconfig --add nginx
	chkconfig --level 3 nginx on
	service nginx start
else
	chmod +x /etc/rc.d/rc.local
	echo '/etc/init.d/nginx restart' >>/etc/rc.d/rc.local
	/etc/init.d/nginx start
fi
[ -d "/www/flag/" ] || mkdir -p /www/flag/
[ $? -eq 0 ] && touch /www/flag/Nginx.lock
curl 'http://127.0.0.1:8000/success_install?softname=Nginx&dir=/www/nginx' >/www/install.log
