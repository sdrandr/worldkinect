#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="terraform-admin"
AWS_REGION="us-east-1"
DEFAULT_CLUSTER="wk-dev-eks"

divider() { echo "------------------------------------------------------------"; }

echo "🧭 Checking Terraform environment..."
cd ~/worldkinect/terraform/environments/dev
terraform workspace show || true
divider

echo "🧩 Detecting EKS clusters in AWS ($AWS_REGION)..."
CLUSTERS=$(AWS_PROFILE=$AWS_PROFILE aws eks list-clusters --region $AWS_REGION --query "clusters[]" --output text 2>/dev/null || echo "")

if [[ -z "$CLUSTERS" ]]; then
  echo "❌ No EKS clusters found in region $AWS_REGION."
  echo "💡 You may need to deploy with ./deploy.sh or ./clean_rebuild.sh"
  divider
  exit 0
fi

echo "✅ Found clusters:"
i=1
for c in $CLUSTERS; do
  echo "  [$i] $c"
  ((i++))
done
divider

read -p "Select a cluster number to inspect (default 1): " choice
choice=${choice:-1}
SELECTED_CLUSTER=$(echo "$CLUSTERS" | awk -v n="$choice" '{print $n}')
if [[ -z "$SELECTED_CLUSTER" ]]; then
  SELECTED_CLUSTER="$DEFAULT_CLUSTER"
fi

echo "📦 Using cluster: $SELECTED_CLUSTER"
divider

# --- Check cluster status ---
CLUSTER_STATUS=$(AWS_PROFILE=$AWS_PROFILE aws eks describe-cluster \
  --region $AWS_REGION \
  --name "$SELECTED_CLUSTER" \
  --query "cluster.status" \
  --output text 2>/dev/null || echo "MISSING")

if [[ "$CLUSTER_STATUS" == "MISSING" ]]; then
  echo "❌ Cluster '$SELECTED_CLUSTER' not found in AWS."
  echo "💡 Try rebuilding the cluster with Terraform."
  divider
  exit 0
else
  echo "✅ Cluster status: $CLUSTER_STATUS"
fi
divider

# --- Validate and refresh kubeconfig ---
EKS_ENDPOINT=$(AWS_PROFILE=$AWS_PROFILE aws eks describe-cluster \
  --region $AWS_REGION \
  --name "$SELECTED_CLUSTER" \
  --query "cluster.endpoint" --output text 2>/dev/null || echo "none")

if [[ "$EKS_ENDPOINT" == "none" || -z "$EKS_ENDPOINT" ]]; then
  echo "⚠️ Could not retrieve endpoint for cluster."
else
  if ! grep -q "$EKS_ENDPOINT" ~/.kube/config 2>/dev/null; then
    echo "⚠️ kubeconfig does not match the current cluster endpoint."
    read -p "🔄 Refresh kubeconfig from AWS? (y/n): " refresh
    if [[ "$refresh" == "y" ]]; then
      echo "🔧 Updating kubeconfig..."
      AWS_PROFILE=$AWS_PROFILE aws eks update-kubeconfig \
        --name "$SELECTED_CLUSTER" \
        --region $AWS_REGION
      echo "✅ kubeconfig refreshed for cluster: $SELECTED_CLUSTER"
    else
      echo "Skipping kubeconfig refresh."
    fi
  else
    echo "✅ kubeconfig matches current cluster endpoint."
  fi
fi
divider

# --- Node health check ---
echo "🧠 Checking Kubernetes node health..."
if ! kubectl get nodes >/dev/null 2>&1; then
  echo "⚠️ Unable to connect to Kubernetes API for '$SELECTED_CLUSTER'."
else
  kubectl get nodes -o wide
fi
divider

# --- Helm releases ---
echo "📦 Listing Helm releases..."
if ! helm ls -A >/dev/null 2>&1; then
  echo "⚠️ Helm cannot connect to cluster '$SELECTED_CLUSTER'."
else
  helm ls -A
fi
divider

# --- Events ---
echo "🔍 Recent Kubernetes events (last 10):"
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -n 10 2>/dev/null || true
divider

echo "✅ Status check complete for cluster: $SELECTED_CLUSTER"
