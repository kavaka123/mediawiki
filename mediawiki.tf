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
variable "rootpass" {
    default = "rootpass"
}

variable "wikipass" {
    default = "wikipass"
}

variable "mediawiki_url" {
    default = "https://releases.wikimedia.org/mediawiki/1.34/mediawiki-core-1.34.2.tar.gz"
}

variable "instance_count" {
    default = 2
}

variable "subnet_count" {
    default = 2
}

variable "network_address_space" {
    default = "10.1.0.0/16"
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

data "aws_availability_zones" "available" {}

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
resource "aws_vpc" "vpc" {
    cidr_block = var.network_address_space
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet" {
    count = var.subnet_count
    cidr_block = cidrsubnet(var.network_address_space, 8, count.index)
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "rta-subnet" {
    count = var.subnet_count
    subnet_id = aws_subnet.subnet[count.index].id
    route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "elb-sg" {
    name = "elb_sg"
    vpc_id = aws_vpc.vpc.id

    # Allow HTTP from anywhere
    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #Allow all outbound
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "allow-ssh-http" {
    name = "allow-ssh-http"
    description = "Allow ssh and http from anywhere"
    vpc_id = aws_vpc.vpc.id

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
        cidr_blocks = [var.network_address_space]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create loadbalancer
resource "aws_elb" "web" {
    name = "mediawiki-lb"

    subnets = aws_subnet.subnet[*].id
    security_groups = [aws_security_group.elb-sg.id]
    instances = aws_instance.mediawiki[*].id

    listener {
        instance_port = "80"
        instance_protocol = "http"
        lb_port = "80"
        lb_protocol = "http"
    }
}

resource "aws_instance" "mediawiki" {
    count = var.instance_count
    ami = data.aws_ami.rhel-linux.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet[count.index % var.subnet_count].id
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.allow-ssh-http.id]

    tags = {
        Name = "${count.index}" % 2 == 0 ? "MediaWiki-Blue" : "MediaWiki-Green"
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
            "sudo ./mediawiki_apache_config.sh ${var.mediawiki_url}"
        ]
        
    }
}

#####################################################
# Output
#####################################################
output "mediawiki_url" {
    value = "http://${aws_elb.web.dns_name}"
}

