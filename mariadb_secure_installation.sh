#!/bin/bash
set -ex

if [ $# -ne 2 ];then
	echo "incorrect usage. Use $0 <root password> <wiki password>"
	exit 1
fi

rootpass=$1 # CHANGEME
wikipass=$2 # wikipass

cat > mysql_secure_install.sql <<EOF
UPDATE mysql.user SET Password=PASSWORD('${rootpass}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

mysql -sfu root < mysql_secure_install.sql

cat > mysql_wiki_install.sql <<EOF
CREATE USER 'wiki'@'localhost' IDENTIFIED BY '${wikipass}';
CREATE DATABASE wikidatabase;
GRANT ALL PRIVILEGES ON wikidatabase.* TO 'wiki'@'localhost';
FLUSH PRIVILEGES;
EOF

mysql -sfu root -p"${rootpass}" < mysql_wiki_install.sql