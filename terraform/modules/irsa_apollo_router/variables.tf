########################################
# variables.tf — Apollo Router (IRSA + Ingress)
# Enterprise Terraform Module
# Supports EKS, Helm, IRSA, GitHub OIDC, and AWS Route53 ingress
########################################


########################################
# 🌍 AWS Region and Global Settings
########################################
variable "aws_region" {
  description = "AWS region where EKS cluster and related resources reside (e.g., us-east-1)."
  type        = string
}


########################################
# 🧩 CI/CD & OIDC Integration (GitHub Actions)
########################################
variable "enable_github_oidc" {
  description = "Enable GitHub Actions OIDC trust for IRSA role (for CI/CD automation)."
  type        = bool
  default     = false
}

variable "account_id" {
  description = "AWS account ID used for constructing ARNs and OIDC provider URLs."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the role via OIDC (e.g., sdrandr/worldkinect)."
  type        = string
  default     = ""
}


########################################
# ☸️ EKS Cluster Connectivity
########################################
variable "eks_cluster_name" {
  description = "Name of the target EKS cluster where Apollo Router will be deployed."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint (used by Kubernetes and Helm providers)."
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded EKS cluster CA certificate for authentication."
  type        = string
}

variable "token" {
  description = "Temporary EKS authentication token obtained from aws_eks_cluster_auth."
  type        = string
}


########################################
# 🔐 OIDC / IRSA Configuration
########################################
variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC identity provider (used in IRSA trust relationship)."
  type        = string
}

variable "oidc_provider_issuer" {
  description = "Issuer URL of the EKS OIDC provider (used for AssumeRoleWithWebIdentity conditions)."
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount name bound to the IRSA IAM role for Apollo Router."
  type        = string
  default     = "apollo-router"
}

variable "namespace" {
  description = "Kubernetes namespace in which to deploy Apollo Router and related resources."
  type        = string
  default     = "apollo-system"
}


########################################
# ⚙️ Apollo Router Configuration
########################################
variable "name_prefix" {
  description = "Prefix identifying environment or project (e.g., wk-dev, wk-prod)."
  type        = string
}

variable "domain" {
  description = "Base domain for ingress or routing (e.g., dev.sdrandr.local)."
  type        = string
}

variable "subgraphs" {
  description = "List of subgraphs (federated services) that the Apollo Router composes into the supergraph."
  type        = list(string)
  default     = ["content", "auth", "user"]
}

variable "oidc_jwt_issuer" {
  description = "OIDC JWT issuer used for Apollo Federation authentication."
  type        = string
}

variable "oidc_audience" {
  description = "OIDC JWT audience for Apollo Router (matches federated services)."
  type        = string
  default     = "apollo-router"
}


########################################
# 🌐 Ingress and DNS (Route53 Integration)
########################################
variable "route53_zone_id" {
  description = "AWS Route53 hosted zone ID used for creating DNS records for Apollo Router ingress."
  type        = string
}


########################################
# 🏗️ Environment Metadata
########################################
variable "env_name" {
  description = "Environment name or identifier (e.g., dev, stage, prod)."
  type        = string
}


########################################
# 🪪 IAM & Tagging Metadata
########################################
variable "tags" {
  description = "Map of common tags to apply to all AWS and Kubernetes-managed resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "WorldKinect"
    Compliance = "NIST-800-53"
  }
}
