# APPLICATION

resource "aws_subnet" "subnet_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_blocks[0]
  availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_blocks[1]
  availability_zone = var.availability_zones[1]
}

resource "aws_instance" "application_1" {
  ami                         = "ami-05cfdc5fa2fc958ac" //Amazon Linux 2 w/ BE
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_1.id
  user_data                   = var.user_data
}

resource "aws_instance" "application_2" {
  ami                         = "ami-05cfdc5fa2fc958ac" //Amazon Linux 2 w/ BE
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_2.id
  user_data                   = var.user_data
}