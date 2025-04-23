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
  tags = {
    Name         = each.key
    CustomIPV6ID = format("%02X", each.value.custom_ipv6)
  }

}

