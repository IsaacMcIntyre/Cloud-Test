output "nat_gateway_ids" {
  value = [module.subnet_1.nat_gateway_id, module.subnet_2.nat_gateway_id]
}
