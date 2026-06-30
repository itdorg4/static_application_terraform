terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state keeps provisioning idempotent across CI runs.
  # Pass bucket/key/region via `terraform init -backend-config=...`.
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "ap-south-1"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair"
  default     = "june2026"
}

variable "instance_name" {
  default = "june2026-static-tf"
}

variable "instance_type" {
  default = "t3.micro"
}

# Latest Canonical Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "web" {
  name        = "${var.instance_name}-sg"
  description = "SSH/HTTP/HTTPS for ${var.instance_name}"

  dynamic "ingress" {
    for_each = [22, 80, 443]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = var.instance_name
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}
