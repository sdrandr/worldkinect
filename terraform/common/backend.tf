########################################
# backend.tf
# Remote backend configuration (S3 + DynamoDB + KMS)
########################################

terraform {
  backend "s3" {
    bucket         = ""   # Filled via -backend-config
    key            = ""   # Filled via -backend-config
    region         = ""   # Filled via -backend-config
    dynamodb_table = ""   # Filled via -backend-config
    encrypt        = true
    profile        = ""   # Filled via -backend-config
    kms_key_id     = ""   # Filled via -backend-config
  }
}
