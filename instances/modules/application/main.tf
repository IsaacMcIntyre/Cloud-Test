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

resource "aws_route_table" "private_route_1" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_ids[0]
    # gateway_id = var.gateway_id
  }
}

resource "aws_route_table" "private_route_2" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_ids[1]
    # gateway_id = var.gateway_id
  }
}

resource "aws_route_table_association" "association_1" {
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.private_route_1.id
}

resource "aws_route_table_association" "association_2" {
  subnet_id = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.private_route_2.id
}


resource "aws_instance" "application_1" {
  ami           = "ami-05cfdc5fa2fc958ac" //Amazon Linux 2 w/ BE
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_1.id
  user_data     = var.user_data
  key_name      = var.key_name

  security_groups = [var.security_group_id]
}

resource "aws_instance" "application_2" {
  ami           = "ami-05cfdc5fa2fc958ac" //Amazon Linux 2 w/ BE
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_2.id
  user_data     = var.user_data
  key_name      = var.key_name  
  
  security_groups = [var.security_group_id]
}
