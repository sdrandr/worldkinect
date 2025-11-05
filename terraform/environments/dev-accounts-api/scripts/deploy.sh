#!/usr/bin/env bash
set -euo pipefail

########################################
# Deploy Script — Accounts API
# Deploys accounts-api to EKS
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "============================================"
echo " Deploying Accounts API to EKS"
echo "============================================"
echo ""
echo "Terraform directory: ${TERRAFORM_DIR}"
echo ""

cd "${TERRAFORM_DIR}"

# Step 1: Initialize Terraform
echo ">>> [1/3] Initializing Terraform..."
terraform init
echo "✓ Terraform initialized"
echo ""

# Step 2: Plan
echo ">>> [2/3] Planning deployment..."
terraform plan -out=tfplan
echo "✓ Plan created"
echo ""

# Step 3: Apply
echo ">>> [3/3] Applying changes..."
read -p "Continue with deployment? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
  terraform apply tfplan
  echo ""
  echo "✓ Deployment complete!"
  echo ""
  
  # Show outputs
  terraform output summary
else
  echo "Deployment cancelled"
  rm -f tfplan
  exit 0
fi

echo ""
echo "============================================"
echo " Next Steps:"
echo "============================================"
echo "1. Check status:"
echo "   kubectl get pods -n apollo-system -l app=accounts-api"
echo ""
echo "2. View logs:"
echo "   kubectl logs -f deployment/accounts-api -n apollo-system"
echo ""
echo "3. To update image:"
echo "   cd ~/worldkinect && ./scripts/build-and-push.sh"
echo "   kubectl rollout restart deployment/accounts-api -n apollo-system"
echo "============================================"