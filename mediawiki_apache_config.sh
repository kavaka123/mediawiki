#!/bin/bash
set -x
# run as sudo


if ! command -v wget &> /dev/null;then
    dnf install -y wget
fi

rm mediawiki-1.34.2.tar.gz* || true  
wget -q https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.2.tar.gz &&
tar -zxf  mediawiki-1.34.2.tar.gz -C /var/www

ln -s /var/www/mediawiki-1.34.2 /var/www/mediawiki
chown -R apache:apache /var/www/mediawiki
chown -R apache:apache /var/www/mediawiki-1.34.2

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