#!/usr/bin/env bash
set -euo pipefail

########################################
# Destroy Script — Accounts API
# Removes accounts-api from EKS
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo " ⚠️  DESTROY Accounts API Deployment"
echo "============================================"
echo ""
echo "This will remove:"
echo "  - Kubernetes deployment and service"
echo "  - Service account and IAM role"
echo "  - ECR repository (optional)"
echo ""

cd "${SCRIPT_DIR}"

read -p "Are you sure you want to destroy? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Destroy cancelled"
  exit 0
fi

# Destroy infrastructure
echo ""
echo ">>> Destroying Terraform resources..."
terraform destroy

echo ""
echo "✓ Accounts API removed from EKS"
echo ""
echo "Note: ECR images may still exist. To clean up:"
echo "  aws ecr delete-repository --repository-name worldkinect/accounts-api --force --region us-east-1"
echo ""
