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

module "subnet-1" {
  source = "../subnet"
  vpc-id = aws_vpc.vpc.id
  cidr-block = var.subnet_cidr_block[0] #"10.0.0.0/28"
  availability-zone = var.availability_zone[0] #"eu-west-2a"
  route-table-id = aws_route_table.rtb_public.id
}

module "subnet-2" {
  source = "../subnet"
  vpc-id = aws_vpc.vpc.id
  cidr-block = var.subnet_cidr_block[1] #"10.0.0.16/28"
  availability-zone = var.availability_zone[1]#"eu-west-2b"
  route-table-id = aws_route_table.rtb_public.id
}