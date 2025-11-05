#!/bin/bash
set -e

echo "============================================"
echo " Fixing Terraform State Issues"
echo "============================================"
echo ""

cd ~/worldkinect/terraform/environments/dev-accounts-api

# Issue 1: Import existing ECR repository
echo ">>> [1/3] Importing existing ECR repository..."
terraform import module.accounts_api.aws_ecr_repository.accounts_api worldkinect/accounts-api
echo "✓ ECR repository imported"
echo ""

# Issue 2: Import existing namespace
echo ">>> [2/3] Importing existing namespace..."
terraform import module.accounts_api.kubernetes_namespace.apollo_system apollo-system
echo "✓ Namespace imported"
echo ""

# Issue 3: Check OIDC provider ARN
echo ">>> [3/3] Checking OIDC provider ARN..."
CLUSTER_NAME="wk-dev-eks"
OIDC_ARN=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region us-east-1 --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')

echo "OIDC Provider URL: ${OIDC_ARN}"
echo ""
echo "Now check your terraform.tfvars:"
echo "  eks_cluster_name should be: ${CLUSTER_NAME}"
echo ""

# Try plan again
echo ">>> Trying terraform plan again..."
terraform plan

echo ""
echo "============================================"
echo "If plan succeeds, run:"
echo "  terraform apply"
echo "============================================"