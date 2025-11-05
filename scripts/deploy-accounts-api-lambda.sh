#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# CI/CD Deployment Script — Accounts API (Lambda + ApolloQL)
# Terraform 1.13+ | AWS Lambda + API Gateway
# ============================================================

echo "============================================================"
echo " World Kinect — Deploy Accounts API"
echo "============================================================"

# Resolve project root no matter where this script runs from
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${ENVIRONMENT:-dev}"
SERVICE_DIR="${PROJECT_ROOT}/services/accounts-api"
DIST_DIR="${SERVICE_DIR}/dist"
BUILD_DIR="${PROJECT_ROOT}/build"
ZIP_FILE="${BUILD_DIR}/accounts-api.zip"
TF_DIR="${PROJECT_ROOT}/terraform/environments/${ENVIRONMENT}-lambda"
LOG_FILE="${BUILD_DIR}/deploy-accounts-api.log"
BUILD_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
START_TIME=$(date +%s)

# Parse command line arguments
AUTO_APPROVE="${1:-false}"

echo ""
echo "Resolved variables:"
echo "  PROJECT_ROOT  = ${PROJECT_ROOT}"
echo "  ENVIRONMENT   = ${ENVIRONMENT}"
echo "  SERVICE_DIR   = ${SERVICE_DIR}"
echo "  DIST_DIR      = ${DIST_DIR}"
echo "  BUILD_DIR     = ${BUILD_DIR}"
echo "  ZIP_FILE      = ${ZIP_FILE}"
echo "  TF_DIR        = ${TF_DIR}"
echo "  LOG_FILE      = ${LOG_FILE}"
echo "  BUILD_TIME    = ${BUILD_TIMESTAMP}"
echo "  AUTO_APPROVE  = ${AUTO_APPROVE}"
echo ""

# Error handling
error_exit() {
  echo ""
  echo "============================================================"
  echo "ERROR: $1"
  echo "============================================================"
  echo "Deployment failed at $(date)"
  echo "Check logs: ${LOG_FILE}"
  exit 1
}

trap 'error_exit "Deployment failed"' ERR

# Quick existence checks (fail fast with clear messages)
echo "Checking expected directories and files..."

[ -d "${SERVICE_DIR}" ] || error_exit "SERVICE_DIR does not exist: ${SERVICE_DIR}. Expected a TypeScript service at services/accounts-api"

[ -f "${SERVICE_DIR}/package.json" ] || error_exit "package.json not found in ${SERVICE_DIR}. Make sure your accounts API service has a Node/TypeScript project there."

[ -d "${TF_DIR}" ] || error_exit "Terraform environment directory does not exist: ${TF_DIR}. Expected Terraform config at terraform/environments/${ENVIRONMENT}-lambda"

echo "✓ Environment looks structurally OK."
echo ""

# Step 1 — Clean old artifacts
echo ">>> [1/6] Cleaning build directories..."
echo "Removing: ${DIST_DIR} and ${ZIP_FILE} (if they exist)"
rm -rf "${DIST_DIR}" "${ZIP_FILE}"
mkdir -p "${BUILD_DIR}"
echo "✓ Build directory ready: ${BUILD_DIR}"
echo ""

# Step 2 — Build TypeScript project
echo ">>> [2/6] Building TypeScript project..."
echo "Changing directory to: ${SERVICE_DIR}"
cd "${SERVICE_DIR}"

echo "Running: npm ci (this may take a minute...)"
if ! npm ci 2>&1 | tee -a "${LOG_FILE}"; then
  error_exit "npm ci failed. Check dependencies in package.json and log file."
fi

echo "Running: npm run build"
if ! npm run build 2>&1 | tee -a "${LOG_FILE}"; then
  error_exit "TypeScript build failed. Check compilation errors in log file."
fi

# Validate build output
[ -d "${DIST_DIR}" ] || error_exit "Build failed - ${DIST_DIR} was not created"

if [ -z "$(ls -A ${DIST_DIR} 2>/dev/null)" ]; then
  error_exit "Build succeeded but ${DIST_DIR} is empty"
fi

echo "✓ TypeScript build completed."
echo ""

# Step 3 — Install production dependencies
echo ">>> [3/6] Installing production dependencies..."
cd "${DIST_DIR}"

# Copy package files to dist for production install
cp "${SERVICE_DIR}/package.json" "${DIST_DIR}/"
cp "${SERVICE_DIR}/package-lock.json" "${DIST_DIR}/" 2>/dev/null || true

echo "Running: npm ci --only=production"
if ! npm ci --only=production 2>&1 | tee -a "${LOG_FILE}"; then
  error_exit "Failed to install production dependencies"
fi

echo "✓ Production dependencies installed."
echo ""

# Step 4 — Package Lambda artifact
echo ">>> [4/6] Packaging Lambda function..."

echo "Creating ZIP: ${ZIP_FILE}"
if ! zip -r "${ZIP_FILE}" . >/dev/null 2>&1; then
  error_exit "Failed to create ZIP file"
fi

[ -f "${ZIP_FILE}" ] || error_exit "ZIP file was not created: ${ZIP_FILE}"

ZIP_SIZE=$(du -h "${ZIP_FILE}" | cut -f1)
ZIP_HASH=$(sha256sum "${ZIP_FILE}" | cut -d' ' -f1)

echo "✓ ZIP created at: ${ZIP_FILE}"
echo "  Size: ${ZIP_SIZE}"
echo "  SHA256: ${ZIP_HASH}"

# Store build metadata
echo "${BUILD_TIMESTAMP},${ZIP_HASH},${ZIP_FILE},${ENVIRONMENT}" >> "${BUILD_DIR}/build-history.csv"
echo ""

# Step 5 — Terraform deployment (infra)
echo ">>> [5/6] Deploying via Terraform..."
echo "Changing directory to: ${TF_DIR}"
cd "${TF_DIR}"

echo "Running: terraform init"
if ! terraform init -input=false -no-color 2>&1 | tee -a "${LOG_FILE}"; then
  error_exit "terraform init failed"
fi

echo "Running: terraform plan"
if ! terraform plan -out=tfplan -input=false -no-color 2>&1 | tee -a "${LOG_FILE}"; then
  error_exit "terraform plan failed"
fi

if [ "${AUTO_APPROVE}" = "--auto" ]; then
  echo "Auto-approving terraform apply..."
  if ! terraform apply -auto-approve tfplan -no-color 2>&1 | tee -a "${LOG_FILE}"; then
    error_exit "terraform apply failed"
  fi
else
  echo ""
  echo "Terraform plan created. Press Enter to apply, or Ctrl+C to cancel..."
  read -r
  
  if ! terraform apply tfplan -no-color 2>&1 | tee -a "${LOG_FILE}"; then
    error_exit "terraform apply failed"
  fi
fi

echo ""
echo "✓ Terraform apply complete."
echo ""

# Step 6 — Print Lambda + API info and run smoke test
echo ">>> [6/6] Fetching deployed API info and running smoke test..."

LAMBDA_ARN="$(terraform output -raw lambda_function_arn 2>/dev/null || echo "N/A")"
API_URL="$(terraform output -raw api_gateway_url 2>/dev/null || echo "N/A")"

# Run smoke test if API URL is available
if [ "${API_URL}" != "N/A" ]; then
  echo "Running smoke test against: ${API_URL}"
  
  # Wait a moment for API to be ready
  sleep 3
  
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/health" 2>/dev/null || echo "000")
  
  if [ "${HTTP_CODE}" = "200" ]; then
    echo "✓ Health check passed (HTTP ${HTTP_CODE})"
  else
    echo "⚠ Health check returned HTTP ${HTTP_CODE}"
    echo "  API may need time to warm up, or there may be an issue"
    echo "  Try: curl ${API_URL}/health"
  fi
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "============================================================"
echo "Deployment Summary"
echo "------------------------------------------------------------"
echo "  Environment:    ${ENVIRONMENT}"
echo "  Lambda ARN:     ${LAMBDA_ARN}"
echo "  API URL:        ${API_URL}"
echo "  Build artifact: ${ZIP_FILE}"
echo "  ZIP SHA256:     ${ZIP_HASH}"
echo "  Duration:       ${DURATION} seconds"
echo "------------------------------------------------------------"
echo "  Terraform logs: ${LOG_FILE}"
echo ""
echo "To view logs:"
echo "  cat ${LOG_FILE}"
echo "  tail -f ${LOG_FILE}"
echo "============================================================"
echo "✓ Deployment completed at: $(date +"%Y-%m-%d %H:%M:%S")"
echo "============================================================"