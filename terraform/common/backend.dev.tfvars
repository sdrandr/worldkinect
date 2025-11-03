###############################################
# backend.dev.tfvars
# Remote S3 Backend — Terraform 1.13+ format
# World Kinect — Dev Environment
###############################################

bucket         = "kinect-terraform-state"
key            = "env/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
profile        = "terraform-admin"

# Encrypt the Terraform state with a KMS CMK
kms_key_id     = "arn:aws:kms:us-east-1:891377181070:key/95c3ed54-e836-48a5-9bd6-5ea8fff56126"

# New backend locking mechanism (replaces DynamoDB)
# If you're the only Terraform user, this is preferred.
use_lockfile   = true
