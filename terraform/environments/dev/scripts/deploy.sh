#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="terraform-admin"
AWS_REGION="us-east-1"

cd ~/worldkinect/terraform/environments/dev

echo "🚀 Running Terraform PLAN..."
terraform plan -out=tfplan

echo "🚀 Running Terraform APPLY..."
terraform apply tfplan

echo "✅ Terraform apply complete."
echo "💡 Validate with: kubectl get nodes -A"
