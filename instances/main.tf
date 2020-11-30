# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 2.70"
#     }
#   }
# }
data "aws_availability_zones" "available" {}

resource "aws_key_pair" "deployer" {
  # source = "terraform-aws-modules/key-pair/aws"
  key_name = "deployer-key"
  public_key = var.ssh_key
}

provider "aws" {
  region  = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/28"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "subnet_public-2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.16/28"
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "rtb_public-2" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table_association" "rta_subnet_public-2" {
  subnet_id      = aws_subnet.subnet_public-2.id
  route_table_id = aws_route_table.rtb_public-2.id
}

resource "aws_security_group" "sg_22_80" {
  name   = "sg_22"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
  template = file("../scripts/install-docker.yaml")

  vars = {
    ecr_account_id        = var.ecr_account_id
    ecr_image_name        = var.ecr_image_name
  }
}