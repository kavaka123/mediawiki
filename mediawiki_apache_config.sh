#!/bin/bash
set -x
# run as sudo

if [ $# -ne 1 ];then
    echo "Incorrect usage. Correct usage $0 <https://releases.wikimedia.org/mediawiki/1.34/mediawiki-core-1.34.2.tar.gz>"
    exit 1
fi

media_wiki_url="$1"

if ! command -v wget &> /dev/null;then
    dnf install -y wget
fi

rm -r mediawiki-*.tar.gz* /var/www/mediawiki* || true  
wget -q ${media_wiki_url} || exit 1
tar -zxf  mediawiki-*.tar.gz -C /var/www 

ln -s /var/www/mediawiki-* /var/www/mediawiki
chown -R apache:apache /var/www/mediawiki
chown -R apache:apache /var/www/mediawiki-*

if [ ! -s ./httpd.conf ] || [ ! -s ./selinux_config ];then
    echo "httpd.conf or selinux_config files are missing or zero"
    exit 1
fi

cp -v ./httpd.conf /etc/httpd/conf/httpd.conf
cp -v ./selinux_config /etc/selinux/config

systemctl start httpd
sleep 10
if [ ! $(curl -sSfI localhost | head -1 | grep -q "200 OK") ];then
    echo "apache started successfully..."
else
    echo "Apache failed to start..."
    exit 1
fi
