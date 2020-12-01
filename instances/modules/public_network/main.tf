resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id
}

resource "aws_route_table" "rtb_public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

module "subnet_1" {
  source = "../subnet"
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cidr_block[0]
  availability_zone = var.availability_zone[0]
  route_table_id = aws_route_table.rtb_public.id
}

module "subnet_2" {
  source = "../subnet"
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cidr_block[1]
  availability_zone = var.availability_zone[1]
  route_table_id = aws_route_table.rtb_public.id
}