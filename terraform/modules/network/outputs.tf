output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "Private subnet IDs"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "Public subnet IDs"
}

output "nat_gateway_ids" {
  value       = module.vpc.natgw_ids
  description = "NAT Gateway IDs"
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}
