terraform {
  # cloud {
  #   organization = "PKI-Industries"
  #   workspaces {
  #     name = "learn-terraform-aws"
  #   }
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "admin-pki"
}
# main VPC
resource "aws_vpc" "main" {
  cidr_block                       = "10.16.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags = {
    Name = "Main VPC"
  }
}
data "aws_vpc" "main" {
  id = aws_vpc.main.id
}

# all subnets, check variable.tf
resource "aws_subnet" "private_subnets" {
  for_each = var.subnets

  vpc_id                          = aws_vpc.main.id
  cidr_block                      = each.value.cidr_block
  availability_zone               = each.value.availability_zone
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, each.value.custom_ipv6)
  map_public_ip_on_launch         = can(regex("^sn-web", each.key))
  tags = {
    Name         = each.key
    CustomIPV6ID = format("%02X", each.value.custom_ipv6)
  }

}


# Route all traffic outside the vpc to the internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Project VPC IG"
  }
}
resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "pki-vpc1-rt-web"
  }
}

# only apply this route table to the public subnets
resource "aws_route_table_association" "web_subnet_associations" {
  for_each = {
    for key, subnet in aws_subnet.private_subnets :
    key => subnet if can(regex("^sn-web", key))
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.second_rt.id
}


# Websever EC2 needs inbound on ipv4 and ipv6
resource "aws_security_group" "allow_ssh_and_https" {
  name        = "allow_ssh_and_https"
  description = "Allow SSH inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere (not secure for prod)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # or restrict to your IP
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTP"
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_and_https"
  }
}
resource "aws_security_group" "rds_sg" {
  name        = "rds-mariadb-sg"
  description = "Allows incoming traffic only from insances that have the web security group associated with them"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "Allow MariaDB from EC2 instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh_and_https.id] # <-- referencing existing EC2 SG here
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# Should only deploy these into web subnets
# This currently uses a custom AMI made ahead of time with docker installed
resource "aws_instance" "app_ec2_instances" {
  for_each = {
    for key, value in aws_subnet.private_subnets :
    key => value if can(regex("^sn-web-A", key))
  }
  ami                    = "ami-0a33bff80f6ad8914"
  key_name               = "SSO-Key-malcolm"
  vpc_security_group_ids = [aws_security_group.allow_ssh_and_https.id]
  instance_type          = "t3.medium"
  subnet_id              = each.value.id
  # NOTE user data is broken
  # user_data = <<-EOF
  # #!/bin/bash
  # set -e
  #
  # # Add Docker's official GPG key:
  # sudo apt-get update
  # sudo apt-get install -y ca-certificates curl
  # sudo install -m 0755 -d /etc/apt/keyrings
  # sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  # sudo chmod a+r /etc/apt/keyrings/docker.asc
  #
  # # Add the repository to Apt sources:
  # echo \
  #   "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  #   $$(. /etc/os-release && echo $${UBUNTU_CODENAME:-$${VERSION_CODENAME}}) stable" | \
  #   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  #
  # sudo apt-get update
  # EOF

}

resource "aws_db_subnet_group" "ejbac-db-subnet-group" {
  name = "db-subnet-group"
  subnet_ids = [
    for subnet_name, subnet in var.subnets : aws_subnet.private_subnets[subnet_name].id if contains(split("-", subnet_name), "db")
  ]
}

resource "aws_db_instance" "ejbca" {
  identifier             = "ejbca"
  instance_class         = "db.t3.micro" # free tier 
  allocated_storage      = 20
  engine                 = "mariadb"
  engine_version         = "11.4.4" # most recent version on rds
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = "true" # do not save backup when terraform destroys
  db_subnet_group_name   = aws_db_subnet_group.ejbac-db-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

