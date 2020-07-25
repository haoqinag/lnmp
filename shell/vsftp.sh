#!/bin/bash
[ -f "/www/flag/vsftp.lock" ] && exit
yum install vsftpd -y
mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_bak
cat >/etc/vsftpd/vsftpd.conf <<EOF
anonymous_enable=NO
#允许本地用户登录
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
allow_writeable_chroot=YES
listen=NO
listen_ipv6=YES
pasv_enable=YES
pasv_min_port=30010
pasv_max_port=30015
pam_service_name=vsftpd
EOF
echo "/sbin/nologin" >> /etc/shells
[-d "/www/flag"] || mkdir -p /www/flag
touch /www/flag/vsftp.lock
curl 'http://127.0.0.1:8000/success_install?softname=vsftp&dir=/etc/vsftpd' >/www/install.log
