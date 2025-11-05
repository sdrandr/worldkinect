########################################
# VARIABLES — ACCOUNTS-API ENVIRONMENT
########################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "terraform-admin"
}

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for accounts-api"
  type        = string
  default     = "apollo-system"
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "accounts-api"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "worldkinect/accounts-api"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "wk-dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "worldkinect"
    Component   = "accounts-api"
    ManagedBy   = "terraform"
  }
}
