output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "subnet-ids" {
  value = [module.subnet-1.subnet-id, module.subnet-2.subnet-id]
}