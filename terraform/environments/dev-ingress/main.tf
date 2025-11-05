########################################
# Main Terraform — dev-ingress
# Purpose: Public exposure of Apollo Router via ALB + Route53 + ACM
# Terraform 1.13.x | AWS Provider 5.x | Kubernetes Provider 2.x
########################################

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0, < 6.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

########################################
# AWS Provider
########################################

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

########################################
# Remote State (core dev environment)
# - Retrieves EKS outputs from the dev stack
########################################

data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket  = "kinect-terraform-state"
    key     = "env/dev/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-admin"
  }
}

########################################
# EKS Authentication (for Kubernetes provider)
########################################

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.dev.outputs.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.dev.outputs.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.dev.outputs.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

########################################
# Ingress Module — ALB + ACM + Route53
########################################

module "ingress" {
  source = "../../modules/ingress"

  # AWS & Environment
  aws_region      = var.aws_region
  environment     = "dev"
  name_prefix     = "wk-dev"

  # DNS / Routing
  domain_name     = "router.dev.sdrandr.local"
  route53_zone_id = var.route53_zone_id

  # K8s Service Routing
  namespace    = "apollo-system"            # or use data.terraform_remote_state.dev.outputs.apollo_router_namespace
  service_name = "wk-dev-apollo-router"     # or use data.terraform_remote_state.dev.outputs.apollo_router_service_name
  service_port = 8080

  # Common metadata
  tags = var.tags
}
