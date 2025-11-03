#!/usr/bin/env bash
set -e

# Usage: ./init-backend.sh <environment>
ENV=$1

if [[ -z "$ENV" ]]; then
  echo "Usage: $0 <environment>"
  exit 1
fi

BUCKET="${ENV}-kinect-tfstate"
DYNAMODB_TABLE="terraform-locks"
REGION="us-east-1"
PROFILE="terraform-admin"
KMS_KEY_ALIAS="alias/terraform"

echo "==== Initializing backend for $ENV ===="

# Create S3 bucket if not exists
aws s3api create-bucket \
  --bucket $BUCKET \
  --region $REGION \
  --profile $PROFILE \
  --create-bucket-configuration LocationConstraint=$REGION 2>/dev/null || echo "Bucket $BUCKET already exists"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET \
  --versioning-configuration Status=Enabled \
  --profile $PROFILE

# Enable KMS encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET \
  --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"aws:kms\",\"KMSMasterKeyID\":\"$KMS_KEY_ALIAS\"}}]}" \
  --profile $PROFILE

# Create DynamoDB table for state locking if not exists
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION \
  --profile $PROFILE 2>/dev/null || echo "DynamoDB table $DYNAMODB_TABLE already exists"

echo "Backend initialization complete for $ENV."
