########################################
# Variables — Ingress Module
########################################

variable "namespace" {
  description = "Kubernetes namespace where Apollo Router is deployed"
  type        = string
}

variable "service_name" {
  description = "Name of the Kubernetes service to expose"
  type        = string
}

variable "service_port" {
  description = "Port on which the Apollo Router service listens"
  type        = number
  default     = 8080
}

variable "domain_name" {
  description = "Fully qualified domain name (e.g., router.dev.sdrandr.local)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
}

variable "aws_region" {
  description = "AWS region for ALB and ACM"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for ALB and DNS resources"
  type        = string
  default     = "wk-dev"
}

variable "environment" {
  description = "Environment label (e.g., dev, stage, prod)"
  type        = string
  default     = "dev"
}
variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}