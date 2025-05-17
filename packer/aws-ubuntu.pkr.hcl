variable "tls_mode" {
  type    = string
  default = "simple"
}

variable "hostname" {
  type    = string
  default = "mycahostname"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "ubuntu-base-ejbca-{{timestamp}}"
  instance_type = "t2.medium"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]  # Canonical
  }
  ssh_username = "ubuntu"
}

build {
  name    = "ubuntu-ami"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    scripts = [
      "./packer/docker-engine.sh"
    ]
  }

  provisioner "file" {
    source      = "./packer/ejbca.service"
    destination = "/tmp/ejbca.service"
  }
  provisioner "shell" {
    script = "./packer/setup-ejbca.sh"
    environment_vars = [
      "TLS_MODE=${var.tls_mode}",
      "HOSTNAME=${var.hostname}"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

}

