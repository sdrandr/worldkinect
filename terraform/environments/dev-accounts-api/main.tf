########################################
# MAIN.TF — ACCOUNTS-API ENVIRONMENT
# Separate deployment for accounts-api subgraph
# Terraform 1.13.4  |  AWS Provider 5.x
########################################

terraform {
  required_version = ">= 1.13.4"

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

  backend "s3" {
    bucket         = "kinect-terraform-state"
    key            = "env/dev-accounts-api/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    profile        = "terraform-admin"
  }
}

########################################
# AWS PROVIDER
########################################

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "root"
  region  = var.aws_region
  profile = var.aws_profile
}

########################################
# DATA SOURCES - Reference Existing EKS
########################################

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get existing EKS cluster details
data "aws_eks_cluster" "existing" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "existing" {
  name = var.eks_cluster_name
}

########################################
# KUBERNETES PROVIDER
########################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.existing.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.existing.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.existing.token
}

########################################
# ACCOUNTS API MODULE
########################################

module "accounts_api" {
  source = "../../modules/accounts_api"

  providers = {
    aws.root   = aws.root
    kubernetes = kubernetes
  }

  eks_cluster_name     = var.eks_cluster_name
  namespace            = var.namespace
  service_account_name = var.service_account_name
  
  aws_region = var.aws_region
  
  # FIXED: Construct proper OIDC provider ARN
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.existing.identity[0].oidc[0].issuer, "https://", "")}"
  
  # OIDC issuer is the URL
  oidc_provider_issuer = data.aws_eks_cluster.existing.identity[0].oidc[0].issuer

  ecr_repository_name = var.ecr_repository_name
  image_tag           = var.image_tag
  replicas            = var.replicas
  
  name_prefix = var.name_prefix

  tags = var.tags
}
