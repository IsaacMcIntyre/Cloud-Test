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

  tags = {
    Name = "igw"
  }
}

data "template_file" "fe_user_data" {
  template          = file("../scripts/run-front-end.yaml")
  vars = {
    ecr_account_id  = var.ecr_account_id
    ecr_image_name  = var.ecr_fe_image_name
  }
}

data "template_file" "be_user_data" {
  template          = file("../scripts/run-back-end.yaml")
  vars = {
    ecr_account_id  = var.ecr_account_id
    ecr_image_name  = var.ecr_be_image_name
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer_key"
  public_key = var.ssh_key
}

resource "aws_security_group" "sg" {
  name        = "lb_security_group"
  description = "Load balancer security group"
  vpc_id      = aws_vpc.vpc.id

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

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "presentation" {
  source            = "./modules/presentation"
  vpc_id            = aws_vpc.vpc.id
  subnet_cidr_block = ["10.0.0.0/28", "10.0.0.16/28"]
  availability_zone = ["eu-west-2a", "eu-west-2b"]
  key_name          = aws_key_pair.deployer.key_name
  user_data         = data.template_file.fe_user_data.rendered
  gateway_id        = aws_internet_gateway.igw.id
  security_group_id = aws_security_group.sg.id
}

module "application" {
  source              = "./modules/application"
  vpc_id              = aws_vpc.vpc.id
  subnet_cidr_blocks  = ["10.0.0.32/28", "10.0.0.48/28"]
  availability_zones  = ["eu-west-2a", "eu-west-2b"]
  user_data           = data.template_file.be_user_data.rendered
  nat_gateway_ids     = module.presentation.nat_gateway_ids
  key_name            = aws_key_pair.deployer.key_name
  security_group_id   = aws_security_group.sg.id
}
