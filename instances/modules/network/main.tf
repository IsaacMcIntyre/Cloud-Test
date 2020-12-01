resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block#"10.0.0.0/24"
  enable_dns_support   = var.enable_dns_support #true
  enable_dns_hostnames = var.enable_dns_hostnames #true
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

module "subnet_1" {
  source = "../subnet"
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr_block[0]
  availability_zone = var.availability_zone[0]
  route_table_id = aws_route_table.rtb_public.id
}

module "subnet_2" {
  source = "../subnet"
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr_block[1]
  availability_zone = var.availability_zone[1]
  route_table_id = aws_route_table.rtb_public.id
}