########################################
# outputs.tf — Apollo Router Module
# Enterprise Terraform Module Outputs
# Provides IRSA, Helm, and Ingress visibility to parent environments
########################################

########################################
# 🪪 IAM / IRSA Outputs
########################################

output "apollo_router_irsa_role_name" {
  description = "Name of the IAM role associated with Apollo Router IRSA."
  value       = aws_iam_role.apollo_router_irsa.name
}

output "apollo_router_irsa_role_arn" {
  description = "ARN of the IAM role used by Apollo Router via IRSA."
  value       = aws_iam_role.apollo_router_irsa.arn
}

output "apollo_router_policy_arn" {
  description = "ARN of the IAM policy attached to the Apollo Router IRSA role."
  value       = aws_iam_policy.apollo_router_policy.arn
}


########################################
# ☸️ Kubernetes / Helm Outputs
########################################

output "apollo_router_namespace" {
  description = "Namespace where the Apollo Router has been deployed."
  value       = var.namespace
}

output "apollo_router_service_account" {
  description = "Service account name used by the Apollo Router Helm release."
  value       = var.service_account_name
}

output "apollo_router_release_name" {
  description = "Helm release name for the Apollo Router deployment."
  value       = helm_release.apollo_router.name
}


########################################
# 🌐 Ingress / Networking Outputs
########################################

output "apollo_router_service_name" {
  description = "Kubernetes service name provisioned by the Apollo Router Helm release."
  value       = "wk-dev-apollo-router"
}

output "apollo_router_service_url" {
  description = "Internal cluster URL for the Apollo Router service."
  value       = "http://${helm_release.apollo_router.name}.${var.namespace}.svc.cluster.local:8080"
}

output "apollo_router_public_url" {
  description = "Externally accessible URL for Apollo Router (via Ingress or Route53)."
  value       = "https://router.${var.domain}"
}

output "apollo_router_dns_zone_id" {
  description = "Route53 hosted zone ID used for Apollo Router DNS entries."
  value       = var.route53_zone_id
}


########################################
# 🏗️ Environment Metadata
########################################

output "environment_name" {
  description = "Name of the environment (e.g., dev, stage, prod) this module was deployed to."
  value       = var.env_name
}

output "deployment_summary" {
  description = "Summary map of key details for easy reference or pipeline output."
  value = {
    Environment   = var.env_name
    Namespace     = var.namespace
    Service       = "apollo-router"
    Region        = var.aws_region
    RoleArn       = aws_iam_role.apollo_router_irsa.arn
    Domain        = var.domain
    PublicURL     = "https://router.${var.domain}"
    Route53ZoneID = var.route53_zone_id
  }
}
