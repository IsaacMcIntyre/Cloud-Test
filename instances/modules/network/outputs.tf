output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = [module.subnet_1.subnet_id, module.subnet_2.subnet_id]
}