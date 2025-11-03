output "backend_s3_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state"
  value       = aws_s3_bucket.tf_state.bucket
}

output "backend_dynamodb_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_kms_key_id" {
  description = "KMS Key ID for Terraform state encryption"
  value       = aws_kms_key.terraform_key.key_id
}

output "backend_kms_key_arn" {
  description = "KMS Key ARN for Terraform state encryption"
  value       = aws_kms_key.terraform_key.arn
}

output "backend_kms_alias" {
  description = "KMS Alias for Terraform state encryption"
  value       = aws_kms_alias.terraform_alias.name
}

output "terraform_admin_policy_arn" {
  description = "ARN of Terraform Admin IAM policy"
  value       = aws_iam_policy.terraform_admin_policy.arn
}
