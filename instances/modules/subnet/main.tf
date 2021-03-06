resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block
  availability_zone = var.availability_zone
}

resource "aws_route_table_association" "rta_subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route_table_id
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "eip" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.subnet.id
}
