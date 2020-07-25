#!/bin/bash
domain=$1
siteroot=$2
phpv=$3
sitename=${domain%%,*}
domains=${domain//,/ }
cat >/www/panel/nginx/vhost/${sitename}.conf <<EOF
server
{
	listen 80;
	server_name ${domains};
	index index.php index.html index.htm default.php default.htm default.html;
	root ${siteroot};

	include enable-${phpv}.conf;
	access_log  /www/wwwlogs/${sitename}.log;
        error_log  /www/wwwlogs/${sitename}.log;
}
EOF
mkdir -p ${siteroot}
chown -R www.www ${siteroot} 
