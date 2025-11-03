#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────
# ENVIRONMENT SETTINGS
# ────────────────────────────────────────────────
AWS_PROFILE="terraform-admin"
AWS_REGION="us-east-1"
CLUSTER_NAME="wk-dev-eks"
NODEGROUP_NAME="wk-dev-ng-default"
LOCK_TABLE="worldkinect-terraform-locks"
S3_BUCKET="worldkinect-terraform-state"

cd ~/worldkinect/terraform/environments/dev

echo "🔍 Step 1: Checking AWS connectivity..."
aws sts get-caller-identity --profile $AWS_PROFILE >/dev/null || {
  echo "❌ AWS profile $AWS_PROFILE not valid."; exit 1;
}

# ────────────────────────────────────────────────
# Step 2: Attempt Terraform destroy
# ────────────────────────────────────────────────
echo "💣 Step 2: Running terraform destroy for EKS and Apollo Router..."
terraform destroy -auto-approve -lock=false || true

# ────────────────────────────────────────────────
# Step 3: Manually ensure AWS EKS cleanup
# ────────────────────────────────────────────────
echo "🧼 Step 3: Ensuring cluster and nodegroup are deleted..."
aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$NODEGROUP_NAME" \
  --region $AWS_REGION --profile $AWS_PROFILE 2>/dev/null || true

aws eks delete-cluster --name "$CLUSTER_NAME" --region $AWS_REGION --profile $AWS_PROFILE 2>/dev/null || true

# Wait until cluster gone
while aws eks describe-cluster --name "$CLUSTER_NAME" --region $AWS_REGION --profile $AWS_PROFILE >/dev/null 2>&1; do
  echo "⏳ Waiting for EKS cluster to delete..."
  sleep 30
done

echo "✅ Cluster deletion confirmed."

# ────────────────────────────────────────────────
# Step 4: Remove Terraform state traces
# ────────────────────────────────────────────────
echo "🧾 Step 4: Cleaning stale Terraform state..."
terraform state rm module.eks 2>/dev/null || true
terraform state rm module.irsa_apollo_router 2>/dev/null || true
terraform state rm module.network 2>/dev/null || true

# ────────────────────────────────────────────────
# Step 5: Refresh backend connectivity
# ────────────────────────────────────────────────
echo "🔄 Step 5: Re-initializing Terraform backend..."
rm -rf .terraform .terraform.lock.hcl
terraform init -backend-config="../../common/backend.dev.tfvars" -reconfigure

# ────────────────────────────────────────────────
# Step 6: Rebuild from scratch
# ────────────────────────────────────────────────
echo "🚀 Step 6: Rebuilding full environment..."
terraform plan -out=tfplan
terraform apply tfplan

# ────────────────────────────────────────────────
# Step 7: Validate
# ────────────────────────────────────────────────
echo "🧠 Step 7: Validating cluster nodes..."
AWS_PROFILE=$AWS_PROFILE aws eks list-clusters --region $AWS_REGION
kubectl get nodes || echo "⚠️ Cluster not yet ready — give it 3-5 minutes."

echo "🎉 Rebuild complete!"
