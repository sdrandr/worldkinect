########################################
# backend.tf
# Remote backend configuration (S3 + DynamoDB + KMS)
########################################

terraform {
  backend "s3" {
    # All parameters supplied dynamically via -backend-config
    bucket         = ""
    key            = ""
    region         = ""
    dynamodb_table = ""
    encrypt        = true
    profile        = ""
    kms_key_id     = ""
  }
}
