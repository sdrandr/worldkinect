variable "aws_region" {
  description = "AWS region to deploy bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "terraform-admin"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "kinect"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "policy_file_path" {
  description = "Path to IAM policy JSON for bootstrap"
  default     = "policies/iam-policy.json"
}
