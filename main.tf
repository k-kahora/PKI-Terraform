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
  profile = "admin"
}
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
resource "aws_route_table_association" "web_subnet_associations" {
  for_each = {
    for key, subnet in aws_subnet.private_subnets :
    key => subnet if can(regex("^sn-web", key))
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.second_rt.id

}

