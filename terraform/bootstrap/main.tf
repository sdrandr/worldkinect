terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# -------------------------------
# S3 Bucket for Terraform state
# -------------------------------
resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.project_name}-terraform-state"
  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "terraform_key" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = {
    Name        = "${var.project_name}-tf-key"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "terraform_alias" {
  name          = "alias/terraform"
  target_key_id = aws_kms_key.terraform_key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_key.arn
    }
  }
}

# -------------------------------
# DynamoDB Table for state locking
# -------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-terraform-locks"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
