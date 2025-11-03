########################################
# variables.tf
# Shared input variables for all environments
########################################

# Load shared variables (acts as import)
terraform {
  required_version = ">= 1.6.0"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project    = "worldkinect"
    ManagedBy  = "Terraform"
    Compliance = "NIST800-53"
  }
}

variable "account_id" {
  description = "AWS Account ID for the current environment"
  type        = string
  default     = "891377181070"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "terraform-admin"
}

variable "env_name" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

########################################
# CI/CD & OIDC Variables
########################################

variable "enable_github_oidc" {
  description = "Enable GitHub Actions OIDC trust for Terraform and application IRSA roles."
  type        = bool
  default     = false
}


variable "github_repo" {
  description = "GitHub repository allowed to assume the OIDC role (e.g., sdrandr/worldkinect)."
  type        = string
  default     = "sdrandr/worldkinect"
}


variable "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the DB password"
  type        = string
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnets for the VPC"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnets for the VPC"
}

variable "ecs_container_port" {
  type        = number
  description = "Port for ECS container"
  default     = 4000
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_user" {
  type = string
}

variable "db_instance" {
  type = string
}

variable "db_storage" {
  type = number
}

variable "db_engine" {
  type = string
}

variable "db_engine_version" {
  type = string
}

variable "region" {
  type = string
}

variable "dynamodb_table" {
  type = string
}

variable "kms_key_alias" {
  type = string
}

variable "kms_key_id" {
  type = string
}
