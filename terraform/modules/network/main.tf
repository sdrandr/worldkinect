########################################
# Network Module — NIST / Enterprise Ready
# Terraform 1.13.4 | AWS Provider 5.x
########################################

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0, < 6.0.0"

      # Accept aliased provider from root module
      configuration_aliases = [aws.root]
    }
  }
}

########################################
# AWS VPC MODULE (terraform-aws-modules/vpc/aws v5.8.1)
########################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.project_name}-${var.env_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_support   = true
  enable_dns_hostnames = true

  ########################################
  # TAGGING FOR KUBERNETES DISCOVERY
  ########################################
  public_subnet_tags = {
    "map-public-ip-on-launch"                   = "true"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  ########################################
  # ROUTE TABLE TAGS
  ########################################
  public_route_table_tags = {
    Name = "${var.project_name}-${var.env_name}-public-rt"
  }

  private_route_table_tags = {
    Name = "${var.project_name}-${var.env_name}-private-rt"
  }

  ########################################
  # GLOBAL TAGS
  ########################################
  tags = merge(
    var.tags,
    {
      Component = "network"
      ManagedBy = "terraform"
      Compliance = "NIST800-53"
    }
  )
}
