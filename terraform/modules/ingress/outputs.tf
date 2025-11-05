########################################
# Outputs — ALB Ingress
########################################

output "apollo_router_alb_dns_name" {
  description = "DNS name of the ALB created by the ingress."
  value       = local.ingress_lb_dns
}

output "apollo_router_route53_record" {
  description = "Full Route53 DNS record for Apollo Router ingress."
  value       = aws_route53_record.router_dns.fqdn
}

output "apollo_router_acm_certificate_arn" {
  description = "ARN of the ACM certificate used for the ingress ALB."
  value       = aws_acm_certificate.router_cert.arn
}

output "apollo_router_ingress_url" {
  description = "Public HTTPS URL for Apollo Router after ALB + DNS propagation."
  value       = "https://${aws_route53_record.router_dns.fqdn}"
}
