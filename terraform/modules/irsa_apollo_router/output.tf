########################################
# outputs.tf — IRSA Apollo Router
########################################

output "iam_role_arn" {
  description = "IAM Role ARN created for Apollo Router via IRSA"
  value       = aws_iam_role.apollo_router_irsa.arn
}

