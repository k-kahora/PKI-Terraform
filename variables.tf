variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "ExampleAppServerInstance"
}
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.16.0.0/20", "10.16.16.0/20", "10.16.32.0/20", "10.16.48.0/20"]
}
variable "azs" {
  type        = list(string)
  description = "availability zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

}
variable "db_password" {
  type        = string
  description = "admin password for the db instance"
  sensitive   = true
  default     = "6wQ3DgAi3TWqTxSQcWF5"

}
variable "db_username" {
  type        = string
  description = "admin username for the db instance"
  sensitive   = true
  default     = "ejbca_admin"
}


variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    custom_ipv6       = number # use 0 to 11
  }))





  default = {
    sn-reserved-A = { cidr_block = "10.16.0.0/20", availability_zone = "us-east-1a", custom_ipv6 = 0 }
    sn-db-A       = { cidr_block = "10.16.16.0/20", availability_zone = "us-east-1a", custom_ipv6 = 1 }
    sn-app-A      = { cidr_block = "10.16.32.0/20", availability_zone = "us-east-1a", custom_ipv6 = 2 }
    sn-web-A      = { cidr_block = "10.16.48.0/20", availability_zone = "us-east-1a", custom_ipv6 = 3 }

    sn-reserved-B = { cidr_block = "10.16.64.0/20", availability_zone = "us-east-1b", custom_ipv6 = 4 }
    sn-db-B       = { cidr_block = "10.16.80.0/20", availability_zone = "us-east-1b", custom_ipv6 = 5 }
    sn-app-B      = { cidr_block = "10.16.96.0/20", availability_zone = "us-east-1b", custom_ipv6 = 6 }
    sn-web-B      = { cidr_block = "10.16.112.0/20", availability_zone = "us-east-1b", custom_ipv6 = 7 }

    sn-reserved-C = { cidr_block = "10.16.128.0/20", availability_zone = "us-east-1c", custom_ipv6 = 8 }
    sn-db-C       = { cidr_block = "10.16.144.0/20", availability_zone = "us-east-1c", custom_ipv6 = 9 }
    sn-app-C      = { cidr_block = "10.16.160.0/20", availability_zone = "us-east-1c", custom_ipv6 = 10 }
    sn-web-C      = { cidr_block = "10.16.176.0/20", availability_zone = "us-east-1c", custom_ipv6 = 11 }
  }
}
