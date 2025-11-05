########################################
# outputs.tf — dev-ingress
# Exposes key public endpoints and metadata for the Apollo Router ingress layer.
########################################

# ALB DNS name (raw, internal AWS DNS endpoint)
output "apollo_router_alb_dns_name" {
  description = "DNS name of the Application Load Balancer created by ingress."
  value       = module.ingress.apollo_router_alb_dns_name
}

# Route53 record (FQDN) for the router service
output "apollo_router_route53_record" {
  description = "Route53 DNS record pointing to the ALB."
  value       = module.ingress.apollo_router_route53_record
}

# TLS certificate ARN
output "apollo_router_acm_certificate_arn" {
  description = "ARN of the ACM certificate used for TLS termination at the ALB."
  value       = module.ingress.apollo_router_acm_certificate_arn
}

# Public URL
output "apollo_router_ingress_url" {
  description = "Public HTTPS URL where the Apollo Router is accessible."
  value       = module.ingress.apollo_router_ingress_url
}
