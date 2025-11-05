#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# IAM Setup Script - Accounts API EKS Deployment
# Creates IAM users, roles, and policies needed for deployment
# ============================================================

echo "============================================================"
echo " IAM Setup - Accounts API EKS Deployment"
echo "============================================================"

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REPOSITORY="worldkinect/accounts-api"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-wk-dev-eks}"
NAMESPACE="${NAMESPACE:-default}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IAM_POLICIES_DIR="${PROJECT_ROOT}/terraform/bootstrap/policies"

echo ""
echo "Configuration:"
echo "  AWS_REGION      = ${AWS_REGION}"
echo "  AWS_ACCOUNT_ID  = ${AWS_ACCOUNT_ID}"
echo "  EKS_CLUSTER     = ${EKS_CLUSTER_NAME}"
echo ""

# Create IAM policies directory if it doesn't exist
mkdir -p "${IAM_POLICIES_DIR}"

# ============================================================
# Step 1: Create IAM Policy for CI/CD User
# ============================================================

echo ">>> [1/5] Creating IAM policy for CI/CD deployment..."

cat > "${IAM_POLICIES_DIR}/accounts-api-cicd-policy.json" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKSAccess",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:DescribeNodegroup",
        "eks:ListNodegroups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSAssumeRole",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create or update the policy
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AccountsAPI-CICD-Policy"

if aws iam get-policy --policy-arn "${POLICY_ARN}" >/dev/null 2>&1; then
  echo "Policy exists, creating new version..."
  aws iam create-policy-version \
    --policy-arn "${POLICY_ARN}" \
    --policy-document "file://${IAM_POLICIES_DIR}/accounts-api-cicd-policy.json" \
    --set-as-default
else
  echo "Creating new policy..."
  aws iam create-policy \
    --policy-name "AccountsAPI-CICD-Policy" \
    --policy-document "file://${IAM_POLICIES_DIR}/accounts-api-cicd-policy.json" \
    --description "Policy for Accounts API CI/CD deployments"
fi

echo "✓ CI/CD policy created: ${POLICY_ARN}"
echo ""

# ============================================================
# Step 2: Create IAM User for CI/CD (Optional - for Jenkins/GitHub Actions)
# ============================================================

echo ">>> [2/5] Creating IAM user for CI/CD..."

CI_USER_NAME="accounts-api-cicd"

if aws iam get-user --user-name "${CI_USER_NAME}" >/dev/null 2>&1; then
  echo "User ${CI_USER_NAME} already exists"
else
  echo "Creating user ${CI_USER_NAME}..."
  aws iam create-user \
    --user-name "${CI_USER_NAME}" \
    --tags "Key=Purpose,Value=CI/CD" "Key=Service,Value=accounts-api"
fi

# Attach policy to user
aws iam attach-user-policy \
  --user-name "${CI_USER_NAME}" \
  --policy-arn "${POLICY_ARN}"

echo "✓ User created and policy attached"
echo ""

# ============================================================
# Step 3: Create Access Keys for CI/CD User
# ============================================================

echo ">>> [3/5] Creating access keys..."

# Check if user already has access keys
EXISTING_KEYS=$(aws iam list-access-keys --user-name "${CI_USER_NAME}" --query 'AccessKeyMetadata[].AccessKeyId' --output text)

if [ -z "${EXISTING_KEYS}" ]; then
  echo "Creating new access key for ${CI_USER_NAME}..."
  
  # Create access key
  ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "${CI_USER_NAME}" --output json)
  
  ACCESS_KEY_ID=$(echo "${ACCESS_KEY_OUTPUT}" | jq -r '.AccessKey.AccessKeyId')
  SECRET_ACCESS_KEY=$(echo "${ACCESS_KEY_OUTPUT}" | jq -r '.AccessKey.SecretAccessKey')
  
  # Save to secure file
  CREDENTIALS_FILE="${PROJECT_ROOT}/.aws-credentials-${CI_USER_NAME}.txt"
  cat > "${CREDENTIALS_FILE}" << EOF
# AWS Credentials for ${CI_USER_NAME}
# Created: $(date)
# KEEP THIS FILE SECURE - DO NOT COMMIT TO GIT

AWS_ACCESS_KEY_ID=${ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY}
AWS_REGION=${AWS_REGION}

# For GitHub Actions Secrets:
AWS_ACCESS_KEY_ID: ${ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY: ${SECRET_ACCESS_KEY}

# For Jenkins Credentials:
# Go to Jenkins > Credentials > Add Credentials
# Kind: AWS Credentials
# ID: aws-credentials
# Access Key ID: ${ACCESS_KEY_ID}
# Secret Access Key: ${SECRET_ACCESS_KEY}
EOF
  
  chmod 600 "${CREDENTIALS_FILE}"
  
  echo "✓ Access keys created and saved to: ${CREDENTIALS_FILE}"
  echo "⚠️  IMPORTANT: Store these credentials securely!"
  echo "⚠️  Add ${CREDENTIALS_FILE} to .gitignore"
else
  echo "⚠️  User already has access keys:"
  echo "${EXISTING_KEYS}"
  echo "If you need new keys, delete existing ones first:"
  echo "  aws iam delete-access-key --user-name ${CI_USER_NAME} --access-key-id <KEY_ID>"
fi

echo ""

# ============================================================
# Step 4: Create IAM Role for EKS Service Account
# ============================================================

echo ">>> [4/5] Creating IAM role for EKS service account..."

# Get OIDC provider for the cluster
OIDC_PROVIDER=$(aws eks describe-cluster \
  --name "${EKS_CLUSTER_NAME}" \
  --region "${AWS_REGION}" \
  --query "cluster.identity.oidc.issuer" \
  --output text | sed -e "s/^https:\/\///")

echo "OIDC Provider: ${OIDC_PROVIDER}"

# Create trust policy for service account
cat > "${IAM_POLICIES_DIR}/eks-service-account-trust-policy.json" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${NAMESPACE}:accounts-api",
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

# Create the role
ROLE_NAME="AccountsAPI-EKS-ServiceAccount-Role"

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "Role ${ROLE_NAME} already exists, updating trust policy..."
  aws iam update-assume-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-document "file://${IAM_POLICIES_DIR}/eks-service-account-trust-policy.json"
else
  echo "Creating role ${ROLE_NAME}..."
  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document "file://${IAM_POLICIES_DIR}/eks-service-account-trust-policy.json" \
    --tags "Key=Service,Value=accounts-api" "Key=Cluster,Value=${EKS_CLUSTER_NAME}"
fi

# Create inline policy for the role (if your app needs AWS service access)
cat > "${IAM_POLICIES_DIR}/eks-service-account-permissions.json" << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:accounts-api/*"
    },
    {
      "Sid": "RDSAccess",
      "Effect": "Allow",
      "Action": [
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:${AWS_REGION}:${AWS_ACCOUNT_ID}:table/accounts*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name "AccountsAPI-Permissions" \
  --policy-document "file://${IAM_POLICIES_DIR}/eks-service-account-permissions.json"

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo "✓ Service account role created: ${ROLE_ARN}"
echo ""

# ============================================================
# Step 5: Update Kubernetes Service Account
# ============================================================

echo ">>> [5/5] Creating Kubernetes service account..."

cat > "${PROJECT_ROOT}/services/accounts-api/kubernetes/serviceaccount.yaml" << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: accounts-api
  namespace: ${NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: ${ROLE_ARN}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: accounts-api
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: accounts-api
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: accounts-api
subjects:
- kind: ServiceAccount
  name: accounts-api
  namespace: ${NAMESPACE}
EOF

echo "✓ Kubernetes service account manifest created"
echo ""

# ============================================================
# Summary
# ============================================================

echo "============================================================"
echo "✓ IAM Setup Complete!"
echo "============================================================"
echo ""
echo "Created Resources:"
echo ""
echo "1. IAM Policy:"
echo "   Name: AccountsAPI-CICD-Policy"
echo "   ARN:  ${POLICY_ARN}"
echo ""
echo "2. IAM User (for CI/CD):"
echo "   Name: ${CI_USER_NAME}"
echo "   Credentials saved to: ${CREDENTIALS_FILE:-N/A}"
echo ""
echo "3. IAM Role (for EKS pods):"
echo "   Name: ${ROLE_NAME}"
echo "   ARN:  ${ROLE_ARN}"
echo ""
echo "4. Kubernetes ServiceAccount:"
echo "   File: services/accounts-api/kubernetes/serviceaccount.yaml"
echo ""
echo "============================================================"
echo "Next Steps:"
echo "============================================================"
echo ""
echo "For Local Development (Mac):"
echo "  1. Your current AWS credentials should work"
echo "  2. Ensure you have EKS access:"
echo "     aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}"
echo ""
echo "For GitHub Actions:"
echo "  1. Go to: GitHub Repo > Settings > Secrets and variables > Actions"
echo "  2. Add secrets from: ${CREDENTIALS_FILE:-credentials file}"
echo "     - AWS_ACCESS_KEY_ID"
echo "     - AWS_SECRET_ACCESS_KEY"
echo "     - AWS_REGION"
echo ""
echo "For Jenkins:"
echo "  1. Go to: Jenkins > Credentials > Add Credentials"
echo "  2. Kind: AWS Credentials"
echo "  3. Use values from: ${CREDENTIALS_FILE:-credentials file}"
echo ""
echo "Deploy Kubernetes ServiceAccount:"
echo "  kubectl apply -f services/accounts-api/kubernetes/serviceaccount.yaml"
echo ""
echo "Update Deployment to use ServiceAccount:"
echo "  Add to deployment.yaml under spec.template.spec:"
echo "    serviceAccountName: accounts-api"
echo ""
echo "============================================================"