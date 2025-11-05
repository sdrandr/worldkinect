########################################
# variables.tf — dev-ingress
# Defines input variables for the ingress environment.
# Terraform 1.13.x | AWS Provider 5.x
########################################

########################################
# 🌍 AWS Provider Settings
########################################

variable "aws_region" {
  description = "AWS region for ingress resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile used for authentication."
  type        = string
  default     = "terraform-admin"
}

########################################
# 🌐 Networking & Domain
########################################

variable "domain_name" {
  description = "Fully qualified domain name for the ingress (e.g., dev.sdrandr.local)."
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the domain (e.g., Z0EXAMPLE123)."
  type        = string
}

########################################
# ☸️ Kubernetes Integration
########################################

variable "namespace" {
  description = "Kubernetes namespace where Apollo Router runs."
  type        = string
  default     = "apollo-system"
}

variable "service_name" {
  description = "Kubernetes service name for the Apollo Router deployment."
  type        = string
}

variable "service_port" {
  description = "Port exposed by the Apollo Router Kubernetes service."
  type        = number
  default     = 8080
}

########################################
# 🏷️ Environment Metadata
########################################

variable "name_prefix" {
  description = "Prefix for resource naming (e.g., wk-dev)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, stage, prod)."
  type        = string
  default     = "dev"
}

########################################
# 🔖 Common Tagging
########################################

variable "tags" {
  description = "Common tags applied to all ingress resources."
  type        = map(string)
  default = {
    Project     = "WorldKinect"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
