resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc-id
  cidr_block        = var.cidr-block
  availability_zone = var.availability-zone
}

resource "aws_route_table_association" "rta_subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route-table-id
}