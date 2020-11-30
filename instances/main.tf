data "aws_availability_zones" "available" {}

resource "aws_key_pair" "deployer" {
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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "rtb_public" {
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
  route_table_id = aws_route_table.rtb_public.id
}

data "template_file" "user_data" {
  template = file("../scripts/install-docker.yaml")

  vars = {
    ecr_account_id        = var.ecr_account_id
    ecr_image_name        = var.ecr_image_name
  }
}

module "load-balancer" {
  source = "./modules/load-balancer"
  sg-vpc-id = aws_vpc.vpc.id
  port = 80
  sg-ingress-protocol = "tcp"
  alb-name = "my-alb"
  alb-subnet-ids = [aws_subnet.subnet_public.id, aws_subnet.subnet_public-2.id]
  tg-name = "my-alb-target-group"
  tg-protocol = "HTTP"
  tg-vpc-id = aws_vpc.vpc.id
  tg-hc-path = "/"
  l-protocol = "HTTP"
  l-da-type = "forward"
}

resource "aws_launch_template" "launch_template" {
image_id                        = "ami-053b5dc3907b8bd31"
  instance_type                 = "t2.micro"
  user_data                     = base64encode(data.template_file.user_data.rendered)
  network_interfaces {
    # associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [module.load-balancer.sg-id]
  }
  key_name                      = aws_key_pair.deployer.key_name
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                          = "autoscaling_group"
  max_size                      = 4
  min_size                      = 1
  health_check_grace_period     = 300
  health_check_type             = "ELB"
  desired_capacity              = 2
  force_delete                  = true
  launch_template {
    id                          = aws_launch_template.launch_template.id
  }
  vpc_zone_identifier           = [aws_subnet.subnet_public.id, aws_subnet.subnet_public-2.id] #said to remove
  target_group_arns             = [module.load-balancer.alb-tg-arn]
}