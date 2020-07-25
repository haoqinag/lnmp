#!/bin/bash
domain=$1
sitename=${domain%%,*}
[ -d "/www/panel/trashsite/" ] || mkdir -p /www/panel/trashsite/
mv -f /www/panel/nginx/vhost/${sitename}.conf /www/panel/trashsite
