########################################
# outputs.tf — DEV Environment
# Restrict outputs to provisioned modules only
########################################

output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID for EKS and dependent services"
}

output "private_subnets" {
  value       = module.network.private_subnets
  description = "Private subnet IDs for internal workloads"
}

output "public_subnets" {
  value       = module.network.public_subnets
  description = "Public subnet IDs for external access"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "EKS OIDC provider ARN for IRSA integration"
}

output "apollo_router_irsa_role_arn" {
  value       = module.irsa_apollo_router.iam_role_arn
  description = "IAM role ARN used by Apollo Router via IRSA"
}

output "apollo_router_url" {
  value       = module.irsa_apollo_router.router_url
  description = "Apollo Router ingress URL"
}
# Uncomment when later modules are created
# output "rds_endpoint" {
#   value       = module.database.rds_endpoint
#   description = "Database endpoint for Apollo Router"
# }

# output "graphql_endpoint" {
#   value       = "https://${aws_lb.kinect_alb.dns_name}/graphql"
#   description = "GraphQL endpoint exposed via ALB"
# }

# output "waf_acl_arn" {
#   value       = module.waf.web_acl_arn
#   description = "Web ACL ARN for perimeter protection"
# }
