#!/bin/bash
#author:hao
#auto install lnmp
#

#优化系统
Men=`free -m |awk '/Mem:/{print $2}'`
Swap=`free -m |awk '/Swap:/{print $2}'`
#关闭selinux
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
#调整dns
echo -e "nameserver 114.114.114.114\nnameserver 61.139.2.69" >/etc/resolv.conf
#检查wget
which wget >/dev/null 2>&1
[ $? -ne 0 ] && yum install wget -y
#添加交换分区
makeswap()
{
	dd if=/dev/zero of=/home/swapfile bs=1M count=$1
	mkswap /home/swapfile
	swapon /home/swapfile
	echo "/home/swapfile swap swap defaults 0 0" >>/etc/fstab
	#内存低于10%时开始使用交换分区
	echo 'vm.swappiness=10' >>/etc/sysctl.conf
	sysctl -p

}
init_os7()
{
	#禁用不要的服务
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	systemctl stop NetworkManager.service
	systemctl disable NetworkManager.service
	systemctl stop postfix
	systemctl disable postfix
	#调整yum源
	date_repo=`date +%Y%m%d`
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo$date_repo
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all
	yum makecache
	yum install libmcrypt libmcrypt-devel mhash mhash-devel bzip2 bzip2-devel gcc gcc-c++ openssl-devel openssl ncurses-devel cmake libxml2 libxml2-devel curl-devel libpng libpng-devel  libjpeg-devel freetype-devel libicu-devel libmcrypt-devel mhash mhash-devel sqlite-devel sqlite zip unzip -y
	#安装iptables-services
	yum install iptables-services -y
	systemctl restart iptables.service
	systemctl enable iptables.service
	#开放端口
	iptables -t filter -I INPUT 5 -p tcp -m multiport --dport 21,80,8000,443 -j ACCEPT
	#icmp限制
	iptables -t filter -I INPUT 1 -p icmp -m limit --limit 10/min --limit-burst 10 -j ACCEPT
	iptables -I INPUT 2 -p icmp -j DROP
	#syn-flood
	iptables -N syn-flood
	iptables -A INPUT -p tcp --syn -j syn-flood
	iptables -A syn-flood -p tcp -m limit --limit 3/s --limit-burst 50 -j ACCEPT
	iptables -A syn-flood -j DROP
	service iptables save
	#内核优化
	#对于本端断开的socket连接，TCP保持在FIN-WAIT-2状态的时间
	echo 'net.ipv4.tcp_fin_timeout=2' > /etc/sysctl.conf
	#该文件表示是否允许重新应用处于TIME-WAIT状态的socket用于新的TCP连接，1开启。
	echo 'net.ipv4.tcp_tw_reuse=1' >> /etc/sysctl.conf
	#默认即可
	echo 'net.ipv4.tcp_tw_recycle=0' >> /etc/sysctl.conf
	#设置SYN Cookie，就是给每一个请求连接的IP地址分配一个Cookie，如果短时间内连续受到某个IP的重复SYN报文，就认定是受到了攻击，以后从这个IP地址来的包会被丢弃
	echo 'net.ipv4.tcp_syncookies=1' >> /etc/sysctl.conf
	#该文件表示从不再传送数据到向连接上发送保持连接信号之间所需的秒数
	echo 'net.ipv4.tcp_keepalive_time=30' >> /etc/sysctl.conf
	#该文件表示TCP／UDP协议打开的本地端口号
	echo 'net.ipv4.ip_local_port_range=32768 60999' >> /etc/sysctl.conf
	#对于那些依然还未获得客户端确认的连接请求，需要保存在队列中SYN_RECV的TCP最大连接数
	echo 'net.ipv4.tcp_max_syn_backlog=8182' >> /etc/sysctl.conf
	#定义了系统中每一个端口最大的监听队列的长度
	echo 'net.core.somaxconn=2048' >> /etc/sysctl.conf
	#系统在同时所处理的最大timewait sockets 数目。如果超过此数的话，time-wait socket 会被立即砍除并且显示警告信息
	echo 'net.ipv4.tcp_max_tw_buckets=5000' >> /etc/sysctl.conf
	#该文件表示本机向外发起TCP SYN连接超时重传的次数，不应该高于255
	echo 'net.ipv4.tcp_syn_retries=1' >> /etc/sysctl.conf
	#第二次握手发送确认包的个数，默认5
	echo 'net.ipv4.tcp_synack_retries=1' >> /etc/sysctl.conf
	#网卡接收数据包的速度远大于内核处理,允许发送到队列的数据包最大数,默认1000
	echo 'net.core.netdev_max_backlog=1000' >> /etc/sysctl.conf
	echo -e 'net.nf_conntrack_max=200000\nnet.netfilter.nf_conntrack_max = 200000\nnet.netfilter.nf_conntrack_tcp_timeout_established = 180\nnet.netfilter.nf_conntrack_tcp_timeout_time_wait = 120\nnet.netfilter.nf_conntrack_tcp_timeout_close_wait = 60\nnet.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120' >> /etc/sysctl.conf
	sysctl -p
	#修改文件描述符重启生效
	echo "* soft nofile 100001" >> /etc/security/limits.conf
	echo "* hard nofile 100002" >> /etc/security/limits.conf

	#添加交换分区
	if [ "$swap" == "0" ]; then
		if [ "$swap" -le "1024" ]; then
			makeswap 1024
		else
			makeswap 2048
		fi
	else
		echo "交换分区已设置,跳过..."
	fi
}

#判断是否centos系统
check_os()
{
	grep 'CentOS' /etc/redhat-release
	[ $? -ne 0 ] && echo "本脚本适合centos系统！" && exit
	[ -n "$(grep ' 7\.' /etc/redhat-release 2> /dev/null)" ] && os=7
	[ -n "$(grep ' 6\.' /etc/redhat-release 2> /dev/null)" ] && os=6
	if [ "${os}" -eq "7" ];then
		init_os7
	else
		init_os6
	fi
}
check_os

init_os7
if [ $? -eq "0" ];then
	echo "系统优化成功!"
else
	echo "系统优化失败！"
fi

cd
. ./config.conf
wget ${source_add}lnmp/Python-3.7.5.tgz
tar -zxf Python-3.7.5.tgz
cd Python-3.7.5
./configure --prefix=${lnmp_root}/python3
make -j `cat /proc/cpuinfo |grep processor |wc -l` && make install
${lnmp_root}/python3/bin/pip3 install django==2.1.8 -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
cd
wget ${source_add}lnmp/lnmp.zip
unzip -qo lnmp.zip -d ${lnmp_root}
cp ${lnmp_root}/lnmp/shell/lnmp /etc/init.d/lnmp
chmod +x /etc/init.d/lnmp
/etc/init.d/lnmp start
chmod +x /etc/rc.d/rc.local
echo "/etc/init.d/lnmp start" >>/etc/rc.d/rc.local
