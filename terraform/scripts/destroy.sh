#!/usr/bin/env bash
set -e

# Usage: ./destroy.sh <environment>
ENV=$1

if [[ -z "$ENV" ]]; then
  echo "Usage: $0 <environment>"
  exit 1
fi

echo "==== Destroying Terraform resources for $ENV ===="

cd "environments/$ENV"

# Initialize backend
terraform init -backend-config="backend.$ENV.tfvars"

# Destroy
terraform destroy -auto-approve

echo "Resources destroyed for $ENV."
