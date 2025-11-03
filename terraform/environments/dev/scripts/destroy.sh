#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="terraform-admin"
AWS_REGION="us-east-1"

cd ~/worldkinect/terraform/environments/dev

echo "⚠️ WARNING: This will destroy ALL resources in the dev environment!"
read -p "Type 'yes' to continue: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Destroy aborted."
  exit 1
fi

echo "💣 Running Terraform destroy..."
terraform destroy -auto-approve -lock=false

echo "✅ All Terraform-managed resources destroyed."
