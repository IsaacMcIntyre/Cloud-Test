data "aws_availability_zones" "available" {}


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

module "autoscaling-group" {
  source = "./modules/autoscaling-group"
  ssh-key = var.ssh_key
  ami = "ami-053b5dc3907b8bd31"
  instance-type = "t2.micro"
  user-data = data.template_file.user_data.rendered
  public-ip = false
  delete-on-termination = true
  sg-id = [module.load-balancer.sg-id]
  max-size = 4
  min-size = 1
  hc-grace-period = 300
  hc-check-type = "ELB"
  desired-capacity = 2
  force-delete = true
  subnets = [aws_subnet.subnet_public.id, aws_subnet.subnet_public-2.id]
  tg-arn = [module.load-balancer.alb-tg-arn]
}
