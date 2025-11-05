#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Build and Push Script - Accounts API (Multi-Stage Build)
# Builds Docker image and pushes to AWS ECR
# TypeScript compilation happens INSIDE Docker
# ============================================================

echo "============================================================"
echo " Build and Push - Accounts API"
echo "============================================================"

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo '')}"
ECR_REPOSITORY="${ECR_REPOSITORY:-worldkinect/accounts-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BUILD_TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICE_DIR="${PROJECT_ROOT}/services/accounts-api"

echo ""
echo "Configuration:"
echo "  AWS_REGION     = ${AWS_REGION}"
echo "  AWS_ACCOUNT_ID = ${AWS_ACCOUNT_ID}"
echo "  ECR_REPOSITORY = ${ECR_REPOSITORY}"
echo "  IMAGE_TAG      = ${IMAGE_TAG}"
echo "  BUILD_TIME     = ${BUILD_TIMESTAMP}"
echo "  SERVICE_DIR    = ${SERVICE_DIR}"
echo ""

# Validation
if [ -z "${AWS_ACCOUNT_ID}" ]; then
  echo "ERROR: Unable to determine AWS Account ID"
  echo "Make sure AWS CLI is configured: aws configure"
  exit 1
fi

if [ ! -d "${SERVICE_DIR}" ]; then
  echo "ERROR: Service directory not found: ${SERVICE_DIR}"
  exit 1
fi

if [ ! -f "${SERVICE_DIR}/Dockerfile" ]; then
  echo "ERROR: Dockerfile not found in ${SERVICE_DIR}"
  exit 1
fi

# Full image name
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE_NAME="${ECR_URI}/${ECR_REPOSITORY}:${IMAGE_TAG}"
FULL_IMAGE_NAME_TIMESTAMPED="${ECR_URI}/${ECR_REPOSITORY}:${BUILD_TIMESTAMP}"

# Step 1: Ensure ECR repository exists
echo ">>> [1/5] Checking ECR repository..."

if ! aws ecr describe-repositories --repository-names "${ECR_REPOSITORY}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "ECR repository does not exist. Creating..."
  aws ecr create-repository \
    --repository-name "${ECR_REPOSITORY}" \
    --region "${AWS_REGION}" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
  echo "✓ ECR repository created"
else
  echo "✓ ECR repository exists"
fi

echo ""

# Step 2: Authenticate Docker to ECR
echo ">>> [2/5] Authenticating Docker to ECR..."

aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${ECR_URI}"

echo "✓ Docker authenticated to ECR"
echo ""

# Step 3: Build Docker image (TypeScript builds INSIDE Docker)
echo ">>> [3/5] Building Docker image with multi-stage build..."
echo "Note: TypeScript compilation happens inside Docker container"
echo ""

cd "${SERVICE_DIR}"

docker build \
  --platform linux/amd64 \
  --build-arg BUILD_DATE="${BUILD_TIMESTAMP}" \
  --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
  -t accounts-api:${IMAGE_TAG} \
  -t accounts-api:${BUILD_TIMESTAMP} \
  -t ${FULL_IMAGE_NAME} \
  -t ${FULL_IMAGE_NAME_TIMESTAMPED} \
  .

echo ""
echo "✓ Docker image built"
echo ""

# Step 4: Test image locally
echo ">>> [4/5] Testing Docker image..."

# Start container in background
CONTAINER_ID=$(docker run -d -p 14000:4000 accounts-api:${IMAGE_TAG})

# Wait for container to be ready
echo "Waiting for container to start..."
sleep 5

# Test health endpoint
if curl -f http://localhost:14000/.well-known/apollo/server-health >/dev/null 2>&1; then
  echo "✓ Health check passed"
else
  echo "⚠  Health check failed, but continuing..."
  docker logs "${CONTAINER_ID}"
fi

# Stop test container
docker stop "${CONTAINER_ID}" >/dev/null
docker rm "${CONTAINER_ID}" >/dev/null

echo ""

# Step 5: Push to ECR
echo ">>> [5/5] Pushing images to ECR..."

# Push with latest tag
docker push ${FULL_IMAGE_NAME}
echo "✓ Pushed ${FULL_IMAGE_NAME}"

# Push with timestamp tag
docker push ${FULL_IMAGE_NAME_TIMESTAMPED}
echo "✓ Pushed ${FULL_IMAGE_NAME_TIMESTAMPED}"

echo ""

# Get image digest
IMAGE_DIGEST=$(aws ecr describe-images \
  --repository-name "${ECR_REPOSITORY}" \
  --image-ids imageTag="${IMAGE_TAG}" \
  --region "${AWS_REGION}" \
  --query 'imageDetails[0].imageDigest' \
  --output text)

# Summary
echo "============================================================"
echo "✓ Build and Push Complete!"
echo "============================================================"
echo ""
echo "Image Details:"
echo "  Repository:  ${ECR_REPOSITORY}"
echo "  Tags:        ${IMAGE_TAG}, ${BUILD_TIMESTAMP}"
echo "  Digest:      ${IMAGE_DIGEST}"
echo "  Full URI:    ${FULL_IMAGE_NAME}"
echo ""
echo "To deploy to EKS, run:"
echo "  cd terraform/environments/dev-accounts-api"
echo "  ./scripts/deploy.sh"
echo ""
echo "Or restart existing deployment:"
echo "  kubectl rollout restart deployment/accounts-api -n apollo-system"
echo "============================================================"