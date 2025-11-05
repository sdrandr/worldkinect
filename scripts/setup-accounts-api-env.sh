#!/usr/bin/env bash
set -euo pipefail

########################################
# Setup Script — Accounts API Separate Environment
# Creates directory structure and copies files
# This is only needed if directory structure has not been created
#... and files are in correct location
########################################

echo "============================================"
echo " Setting Up Accounts API Environment"
echo "============================================"
echo ""

# Determine project root (assuming script is in project root or downloaded files)
if [ -d "terraform" ]; then
  PROJECT_ROOT="$(pwd)"
elif [ -d "../terraform" ]; then
  PROJECT_ROOT="$(cd .. && pwd)"
else
  echo "ERROR: Cannot find terraform directory."
  echo "Please run this script from your project root (~/worldkinect)"
  exit 1
fi

TERRAFORM_ROOT="${PROJECT_ROOT}/terraform"
DOWNLOADS_DIR="$(pwd)"

echo "Project root: ${PROJECT_ROOT}"
echo "Terraform root: ${TERRAFORM_ROOT}"
echo ""

# Check if required files exist in current directory
REQUIRED_FILES=(
  "terraform-module-accounts-api.tf"
  "dev-accounts-api-main.tf"
  "dev-accounts-api-variables.tf"
  "dev-accounts-api-terraform.tfvars"
  "dev-accounts-api-outputs.tf"
  "deploy.sh"
  "destroy.sh"
  "status.sh"
)

echo ">>> Checking for required files..."
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "${file}" ]; then
    echo "ERROR: Required file not found: ${file}"
    echo "Please make sure all downloaded files are in the current directory"
    exit 1
  fi
  echo "  ✓ ${file}"
done
echo ""

# Create directory structure
echo ">>> Creating directory structure..."

mkdir -p "${TERRAFORM_ROOT}/modules/accounts_api"
mkdir -p "${TERRAFORM_ROOT}/environments/dev-accounts-api/scripts"

echo "  ✓ Created terraform/modules/accounts_api"
echo "  ✓ Created terraform/environments/dev-accounts-api"
echo "  ✓ Created terraform/environments/dev-accounts-api/scripts"
echo ""

# Copy module file
echo ">>> Copying module file..."
cp terraform-module-accounts-api.tf "${TERRAFORM_ROOT}/modules/accounts_api/main.tf"
echo "  ✓ Copied to modules/accounts_api/main.tf"
echo ""

# Copy environment files
echo ">>> Copying environment files..."
cp dev-accounts-api-main.tf "${TERRAFORM_ROOT}/environments/dev-accounts-api/main.tf"
cp dev-accounts-api-variables.tf "${TERRAFORM_ROOT}/environments/dev-accounts-api/variables.tf"
cp dev-accounts-api-terraform.tfvars "${TERRAFORM_ROOT}/environments/dev-accounts-api/terraform.tfvars"
cp dev-accounts-api-outputs.tf "${TERRAFORM_ROOT}/environments/dev-accounts-api/outputs.tf"
echo "  ✓ Copied main.tf"
echo "  ✓ Copied variables.tf"
echo "  ✓ Copied terraform.tfvars"
echo "  ✓ Copied outputs.tf"
echo ""

# Copy scripts
echo ">>> Copying deployment scripts..."
cp deploy.sh "${TERRAFORM_ROOT}/environments/dev-accounts-api/scripts/"
cp destroy.sh "${TERRAFORM_ROOT}/environments/dev-accounts-api/scripts/"
cp status.sh "${TERRAFORM_ROOT}/environments/dev-accounts-api/scripts/"

# Make scripts executable
chmod +x "${TERRAFORM_ROOT}/environments/dev-accounts-api/scripts/"*.sh
echo "  ✓ Copied deploy.sh"
echo "  ✓ Copied destroy.sh"
echo "  ✓ Copied status.sh"
echo "  ✓ Made scripts executable"
echo ""

# Copy README
if [ -f "README-SEPARATE-SETUP.md" ]; then
  cp README-SEPARATE-SETUP.md "${TERRAFORM_ROOT}/environments/dev-accounts-api/README.md"
  echo "  ✓ Copied README.md"
  echo ""
fi

# Verify structure
echo ">>> Verifying directory structure..."
echo ""
tree -L 3 "${TERRAFORM_ROOT}/environments/dev-accounts-api" 2>/dev/null || \
  find "${TERRAFORM_ROOT}/environments/dev-accounts-api" -type f -o -type d | sort
echo ""
tree -L 2 "${TERRAFORM_ROOT}/modules/accounts_api" 2>/dev/null || \
  find "${TERRAFORM_ROOT}/modules/accounts_api" -type f | sort
echo ""

# Success message
echo "============================================"
echo " ✓ Setup Complete!"
echo "============================================"
echo ""
echo "Directory structure created:"
echo "  ${TERRAFORM_ROOT}/modules/accounts_api/"
echo "  ${TERRAFORM_ROOT}/environments/dev-accounts-api/"
echo ""
echo "Next steps:"
echo ""
echo "1. Review configuration:"
echo "   cd ${TERRAFORM_ROOT}/environments/dev-accounts-api"
echo "   cat terraform.tfvars"
echo ""
echo "2. Build and push Docker image:"
echo "   cd ${PROJECT_ROOT}"
echo "   ./scripts/build-and-push.sh"
echo ""
echo "3. Deploy to EKS:"
echo "   cd ${TERRAFORM_ROOT}/environments/dev-accounts-api"
echo "   ./scripts/deploy.sh"
echo ""
echo "4. Check status:"
echo "   ./scripts/status.sh"
echo ""
echo "For detailed instructions, see:"
echo "  ${TERRAFORM_ROOT}/environments/dev-accounts-api/README.md"
echo "============================================"
