variable "project_name" {
  description = "Project or system name"
  type        = string
}

variable "env_name" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the DB password"
  type        = string
}

variable "db_engine" {
  description = "Database engine (postgres, mysql, etc.)"
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
}

variable "db_instance" {
  description = "DB instance class (e.g., db.t3.micro)"
  type        = string
}

variable "db_storage" {
  description = "Storage size (GB)"
  type        = number
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group for private subnets"
  type        = string
}

variable "security_group_ids" {
  description = "List of security groups that allow database access"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}
