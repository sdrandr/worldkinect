########################################
# OUTPUTS — ACCOUNTS-API ENVIRONMENT
########################################

output "summary" {
  description = "Deployment summary"
  value = <<-EOT
  
  ========================================
  Accounts API Deployment Summary
  ========================================
  
  ECR Repository:  ${module.accounts_api.ecr_repository_url}
  Service Account: ${module.accounts_api.service_account_role_arn}
  Service URL:     ${module.accounts_api.service_endpoint}
  Namespace:       ${module.accounts_api.namespace}
  
  Next Steps:
  1. Build and push image: ./scripts/build-and-push.sh
  2. Restart deployment:   kubectl rollout restart deployment/accounts-api -n ${module.accounts_api.namespace}
  3. Check status:         kubectl get pods -n ${module.accounts_api.namespace} -l app=accounts-api
  
  EOT
}

output "ecr_push_command" {
  description = "Command to authenticate and push to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.accounts_api.ecr_repository_url}"
}

output "kubectl_commands" {
  description = "Useful kubectl commands"
  value = {
    get_pods    = "kubectl get pods -n ${module.accounts_api.namespace} -l app=accounts-api"
    logs        = "kubectl logs -f deployment/accounts-api -n ${module.accounts_api.namespace}"
    describe    = "kubectl describe deployment/accounts-api -n ${module.accounts_api.namespace}"
    port_forward = "kubectl port-forward svc/accounts-api 4000:4000 -n ${module.accounts_api.namespace}"
    restart     = "kubectl rollout restart deployment/accounts-api -n ${module.accounts_api.namespace}"
  }
}
