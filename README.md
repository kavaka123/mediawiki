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

########################################################
# Terraform
########################################################

1. terraform init
2.  terraform plan -var="mediawiki_url=https://releases.wikimedia.org/mediawiki/1.35/mediawiki-core-1.35.0-rc.2.tar.gz" -out mediawiki.tfplan  
3.  terraform apply "mediawiki.tfplan"

########################################################   
# Ansible
######################################################## 
export AWS_ACCESS_KEY_ID='YOUR_AWS_API_KEY'
export AWS_SECRET_ACCESS_KEY='YOUR_AWS_API_SECRET_KEY'
export ANSIBLE_HOSTS=./ec2.py 
export EC2_INI_PATH=./ec2.ini
ssh-agent bash
ssh-add ~/.ssh/<pem.key>


####### Blue version deployment ################
ansible-playbook -i ./ec2.py Blue_deployment_playbook.yml --extra-vars "mediawiki_url=https://releases.wikimedia.org/mediawiki/1.35/mediawiki-core-1.35.0-rc.2.tar.gz"

######## Green version deployment ###############
ansible-playbook -i ./ec2.py Green_deployment_playbook.yml --extra-vars "mediawiki_url=https://releases.wikimedia.org/mediawiki/1.35/mediawiki-core-1.35.0-rc.2.tar.gz"




