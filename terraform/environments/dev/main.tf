########################################
# MAIN.TF — DEV ENVIRONMENT (Stable stack)
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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
    }
  }

  backend "s3" {
    bucket         = "kinect-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    profile        = "terraform-admin"
  }
}

########################################
# AWS PROVIDERS
########################################

# Default AWS provider (used by EKS and root resources)
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Aliased provider for network and IRSA resources
provider "aws" {
  alias   = "root"
  region  = var.aws_region
  profile = var.aws_profile
}

########################################
# KUBERNETES / HELM PROVIDERS
########################################

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}


########################################
# 1. NETWORKING (uses aws.root)
########################################

module "network" {
  source = "../../modules/network"

  providers = {
    aws.root = aws.root
  }

  cluster_name       = "wk-dev-eks"
  project_name       = "worldkinect"
  env_name           = var.env_name
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = ["us-east-1a", "us-east-1b"]

  tags = merge(var.tags, { Component = "network" })
}

########################################
# 2. EKS CLUSTER (uses default aws provider)
########################################

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.1"

  # NOTE: v20.x naming convention
  cluster_name    = "wk-dev-eks"
  cluster_version = "1.29"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnets

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["${chomp(data.http.my_ip.response_body)}/32"]

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      name           = "wk-dev-ng-default"
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      ami_type       = "AL2_x86_64"

      iam_role_additional_policies = {
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  tags = merge(var.tags, { Component = "eks" })
}

########################################
# FIX: Allow nodegroup → cluster API communication
########################################

#resource "aws_security_group_rule" "eks_api_ingress_from_nodes" {
# description              = "Allow EKS nodes to talk to cluster API on 443"
# type                     = "ingress"
# from_port                = 443
# to_port                  = 443
# protocol                 = "tcp"

# Source = Node group security group
# source_security_group_id = module.eks.node_security_group_id

# Target = Cluster security group
# security_group_id        = module.eks.cluster_security_group_id
#}

########################################
# 3. EKS AUTH
########################################

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

########################################
# 4. APOLLO ROUTER (uses aws.root)
########################################

module "irsa_apollo_router" {
  depends_on = [module.eks]
  source     = "../../modules/irsa_apollo_router"

  enable_github_oidc = var.enable_github_oidc
  account_id         = var.account_id
  github_repo        = var.github_repo


  providers = {
    aws.root   = aws.root
    kubernetes = kubernetes
    helm       = helm
  }

  eks_cluster_name       = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  token                  = data.aws_eks_cluster_auth.this.token

  aws_region           = var.aws_region
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_issuer = module.eks.cluster_oidc_issuer_url

  namespace            = "apollo-system"
  service_account_name = "apollo-router"
  name_prefix          = "wk-dev"
  domain               = "dev.sdrandr.local"

  subgraphs       = ["content", "auth", "user"]
  oidc_jwt_issuer = "https://dev.sdrandr.local"
  oidc_audience   = "apollo-router"

  tags = merge(var.tags, {
    Component  = "apollo-router"
    Compliance = "NIST800-53"
    DataClass  = "internal"
  })
}

# 4.b. INGRESS FOR APOLLO ROUTER
module "ingress" {
  source = "../../modules/ingress"

  namespace          = "apollo-system"
  service_name       = "wk-dev-apollo-router"
  service_port       = 8080
  domain_name        = "router.dev.sdrandr.local"
  route53_zone_id    = var.route53_zone_id
  aws_region         = var.aws_region
}


########################################
# 5. SECRETS
########################################

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}
