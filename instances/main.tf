provider "aws" {
  region  = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
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

module "presentation" {
  source            = "./modules/presentation"
  vpc_id            = aws_vpc.vpc.id
  subnet_cidr_block = ["10.0.0.0/28", "10.0.0.16/28"]
  availability_zone = ["eu-west-2a", "eu-west-2b"]
  ssh_key           = var.ssh_key
  user_data         = data.template_file.fe_user_data.rendered
}

module "application" {
  source            = "./modules/application"
  vpc_id            = aws_vpc.vpc.id
  subnet_cidr_blocks  = ["10.0.0.32/28", "10.0.0.48/28"]
  availability_zones = ["eu-west-2a", "eu-west-2b"]
  user_data         = data.template_file.be_user_data.rendered
}
