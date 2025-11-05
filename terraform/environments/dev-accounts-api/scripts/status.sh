#!/usr/bin/env bash
set -euo pipefail

########################################
# Status Script — Accounts API
# Check deployment status
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo " Accounts API Status Check"
echo "============================================"
echo ""

cd "${SCRIPT_DIR}"

# Check Terraform state
echo ">>> Terraform State:"
if terraform state list 2>/dev/null | grep -q "module.accounts_api"; then
  echo "✓ Terraform resources exist"
else
  echo "✗ No Terraform resources found"
  echo "  Run: ./deploy.sh"
  exit 1
fi
echo ""

# Check Kubernetes resources
echo ">>> Kubernetes Resources:"
echo ""

echo "Pods:"
kubectl get pods -n apollo-system -l app=accounts-api 2>/dev/null || echo "No pods found"
echo ""

echo "Service:"
kubectl get svc accounts-api -n apollo-system 2>/dev/null || echo "No service found"
echo ""

echo "Service Account:"
kubectl get sa accounts-api -n apollo-system 2>/dev/null || echo "No service account found"
echo ""

# Check ECR
echo ">>> ECR Repository:"
aws ecr describe-repositories \
  --repository-names worldkinect/accounts-api \
  --region us-east-1 \
  --query 'repositories[0].repositoryUri' \
  --output text 2>/dev/null || echo "Repository not found"
echo ""

# Get latest images
echo ">>> Recent Images:"
aws ecr describe-images \
  --repository-name worldkinect/accounts-api \
  --region us-east-1 \
  --query 'sort_by(imageDetails,& imagePushedAt)[-5:].[imageTags[0], imagePushedAt]' \
  --output table 2>/dev/null || echo "No images found"
echo ""

# Check pod health
echo ">>> Pod Health:"
PODS=$(kubectl get pods -n apollo-system -l app=accounts-api -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -n "$PODS" ]; then
  for pod in $PODS; do
    echo "Pod: $pod"
    kubectl get pod "$pod" -n apollo-system -o jsonpath='  Status: {.status.phase}{"\n"}' 2>/dev/null
    kubectl get pod "$pod" -n apollo-system -o jsonpath='  Restarts: {.status.containerStatuses[0].restartCount}{"\n"}' 2>/dev/null
    echo ""
  done
else
  echo "No pods found"
fi

echo "============================================"
echo " Quick Commands:"
echo "============================================"
echo "View logs:        kubectl logs -f deployment/accounts-api -n apollo-system"
echo "Port forward:     kubectl port-forward svc/accounts-api 4000:4000 -n apollo-system"
echo "Restart:          kubectl rollout restart deployment/accounts-api -n apollo-system"
echo "Describe:         kubectl describe deployment/accounts-api -n apollo-system"
echo "============================================"
