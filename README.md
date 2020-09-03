1. sudo dnf install -y wget httpd php php-mysqlnd php-gd php-xml mariadb-server mariadb php-mbstring php-json

2. sudo systemctl start mariadb
   cp mariadb_secure_installation.sh ~/
   chmod a+x mariadb_secure_installation.sh
   ./mariadb_secure_installation.sh <rootpass> <wikipass>

3. sudo systemctl enable mariadb
   sudo systemctl enable httpd   

4. cp mediawiki_apache_config.sh ~/
    chmod a+x mediawiki_apache_config.sh
    sudo ./mediawiki_apache_config.sh
