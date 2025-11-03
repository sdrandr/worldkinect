########################################
# variables.tf — irsa_apollo_router
# Defines input variables used to deploy Apollo Router
# on EKS with IRSA and Helm.
########################################


########################################
# 🌍 AWS & Regional Settings
########################################
variable "aws_region" {
  description = "AWS region where EKS cluster and related resources reside (e.g., us-east-1)"
  type        = string
}


########################################
# CI/CD & OIDC Integration
########################################

variable "enable_github_oidc" {
  description = "Enable GitHub Actions OIDC trust for this IRSA role."
  type        = bool
  default     = false
}

variable "account_id" {
  description = "AWS account ID for constructing ARNs and OIDC provider URLs."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the role via OIDC (e.g., sdrandr/worldkinect)."
  type        = string
  default     = false
}


########################################
# ☸️ EKS Cluster Connection (for both AWS + Helm)
########################################
variable "eks_cluster_name" {
  description = "Name of the target EKS cluster (must already exist)"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint (used by Kubernetes/Helm providers to connect)"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded EKS cluster CA certificate for API authentication"
  type        = string
}

variable "token" {
  description = "Temporary EKS authentication token obtained from aws_eks_cluster_auth"
  type        = string
}


########################################
# 🔐 OIDC / IRSA Configuration
########################################
variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC identity provider (for IRSA trust relationship)"
  type        = string
}

variable "oidc_provider_issuer" {
  description = "Issuer URL for the EKS OIDC provider (used in AssumeRoleWithWebIdentity condition)"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes ServiceAccount name bound to the IRSA IAM role for Apollo Router"
  type        = string
  default     = "apollo-router"
}

variable "namespace" {
  description = "Kubernetes namespace in which to deploy Apollo Router and IRSA service account"
  type        = string
  default     = "apollo-system"
}


########################################
# ⚙️ Apollo Router Configuration
########################################
variable "name_prefix" {
  description = "Prefix identifying environment or project (e.g., wk-dev, wk-prod)"
  type        = string
}

variable "domain" {
  description = "Base domain for ingress or routing (e.g., dev.worldkinect.local)"
  type        = string
}

variable "subgraphs" {
  description = "List of subgraphs the Apollo Router federates (e.g., ['auth','content','user'])"
  type        = list(string)
  default     = []
}

variable "oidc_jwt_issuer" {
  description = "OIDC JWT issuer used for Apollo Federation authentication"
  type        = string
}

variable "oidc_audience" {
  description = "OIDC JWT audience for Apollo Router (matches federated services)"
  type        = string
}


########################################
# 🪪 IAM & Tagging Metadata
########################################
variable "tags" {
  description = "Map of common tags to apply to all created AWS resources"
  type        = map(string)
  default     = {}
}
