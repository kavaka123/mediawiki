#####################################################
# Variables
#####################################################
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "region" {
    default = "ap-south-1"
}
variable rootpass {
    default = "rootpass"
}

variable wikipass {
    default = "wikipass"
}

######################################################
# providers
######################################################
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.region
}


######################################################
# Data for filtering ami id
######################################################
data "aws_ami" "rhel-linux" {
    most_recent = true
    name_regex = "^RHEL-8.2.0_HVM-*"
    owners = ["309956199498"]
    
    filter {
        name = "name"
        values = ["RHEL-8.2.0_HVM-*"]
    }

    filter {
        name = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
# ami id : ami-052c08d70def0ac62

######################################################
# resources
######################################################
resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "allow-ssh-http" {
    name = "allow-ssh-http"
    description = "Allow ssh and http from anywhere"
    vpc_id = aws_default_vpc.default.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "mediawiki" {
    ami = data.aws_ami.rhel-linux.id
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.allow-ssh-http.id]

    tags = {
        Name = "MediaWiki"
    }

    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = file(var.private_key_path)
    }

    provisioner "remote-exec" {
        inline = [
            "sudo dnf install -y wget httpd php php-mysqlnd php-gd php-xml mariadb-server mariadb php-mbstring php-json",
            "sudo systemctl enable mariadb",
            "sudo systemctl enable httpd",
            "sudo systemctl start mariadb"
        ]
    }

    provisioner "file" {
        source = "./mariadb_secure_installation.sh"
        destination = "~/mariadb_secure_installation.sh"
    }

    provisioner "file" {
        source = "./mediawiki_apache_config.sh"
        destination = "~/mediawiki_apache_config.sh"
    }

    provisioner "file" {
        source = "./httpd.conf"
        destination = "~/httpd.conf"
    }

    provisioner "file" {
        source = "./selinux_config"
        destination = "~/selinux_config"
    }

    provisioner "remote-exec" {
       inline = [
           "sudo chmod a+x ./mariadb_secure_installation.sh",
           "sudo ./mariadb_secure_installation.sh ${var.rootpass} ${var.wikipass}"
       ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo chmod a+x ./mediawiki_apache_config.sh",
            "sudo ./mediawiki_apache_config.sh"
        ]
        
    }
}

#####################################################
# Output
#####################################################
output "aws_instance_public_dns" {
    value = aws_instance.mediawiki.public_dns
}