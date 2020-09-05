########################################################
# Pre reqs on your workstation
########################################################
1. terraform >=0.12.24
2. python3 (preferrable)
3. ansible >=2.9.0 (if not installed, follow below steps)
   sudo pip3 install ansible boto boto3
   sudo ln -s /usr/bin/python3 /usr/local/bin/python
4. Env variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY
5. ec2 instance private key(pem file)
6. Add the instance private key to ssh-agent for hassle free deployments with ansible (see instructions below)
   ssh-agent bash
   ssh-add ~/.ssh/<PrivateKey.pem>
7. chmod a+x *.sh *.py


########################################################
# Terraform
########################################################
Terraform default vars: (All of these can be overwritten by passing as command line args)
   rootpass = rootpass
   wikipass = wikipass
   mediawiki_tar = mediawiki-core-1.34.2.tar.gz
   instance_count = 2
   subnet_count = 2
   network_address_space = 10.1.0.0./16 


1. terraform init
2. terraform plan -out mediawiki.tfplan  ## deploys default  mediawiki version 1.34.2
3. terraform apply "mediawiki.tfplan"

Note: wait for few minutes until lb is fully operational.
########################################################   
# Ansible
######################################################## 
1. Blue version deployment 
ansible-playbook -i ./ec2.py Blue_deployment_playbook.yml --extra-vars "mediawiki_tar=mediawiki-core-1.33.4.tar.gz"

2. Green version deployment 
ansible-playbook -i ./ec2.py Green_deployment_playbook.yml --extra-vars "mediawiki_tar=mediawiki-core-1.34.0.tar.gz"



