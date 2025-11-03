# 🚀 IRSA Apollo Router Module

[![Terraform](https://github.com/<YOUR_GITHUB_ORG>/<YOUR_REPO>/actions/workflows/terraform.yml/badge.svg)](https://github.com/<YOUR_GITHUB_ORG>/<YOUR_REPO>/actions/workflows/terraform.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](./LICENSE)
[![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-623CE4.svg)](https://registry.terraform.io/modules/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![Apollo Router](https://img.shields.io/badge/Apollo-Router-000000?logo=apollo-graphql&logoColor=white)](https://www.apollographql.com/router)

> Terraform module for deploying **Apollo Router** on **Amazon EKS** with **IRSA**, Helm, and dynamic supergraph ingestion.

# 🚀 IRSA Apollo Router Module

Terraform module that deploys **Apollo Router** into an existing **Amazon EKS cluster** using **IRSA (IAM Roles for Service Accounts)**.  
This module is designed for the **World Kinect AWS Replica Environment**, providing a secure, production-grade deployment aligned with **NIST 800-53** and enterprise AWS best practices.

---

## 📘 Overview

This module:
- Connects to an existing **EKS cluster** via provided endpoint and credentials.
- Creates an **IAM Role for Service Account (IRSA)** for the Apollo Router pod.
- Grants AWS permissions (Secrets Manager, KMS, CloudWatch Logs).
- Dynamically fetches a **demo Apollo Federation supergraph** for testing.
- Deploys the **Apollo Router Helm chart** (`oci://ghcr.io/apollographql/helm-charts`) using Terraform’s Helm provider.

---

## 🧩 Architecture Diagram
---

## ⚙️ Usage Example

```hcl
module "irsa_apollo_router" {
  source = "../../modules/irsa_apollo_router"

  # AWS / EKS
  aws_region              = var.aws_region
  eks_cluster_name        = module.eks.cluster_name
  cluster_endpoint        = module.eks.cluster_endpoint
  cluster_ca_certificate  = module.eks.cluster_certificate_authority_data
  token                   = data.aws_eks_cluster_auth.this.token

  # OIDC / IRSA
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider_issuer    = module.eks.cluster_oidc_issuer_url
  namespace               = "apollo-system"
  service_account_name    = "apollo-router"

  # Apollo Router Config
  name_prefix             = "wk-dev"
  domain                  = "dev.worldkinect.local"
  subgraphs               = ["auth", "content", "user"]
  oidc_jwt_issuer         = "https://dev.worldkinect.local"
  oidc_audience           = "apollo-router"

  tags = {
    Environment = "dev"
    Project     = "WorldKinect"
    Component   = "ApolloRouter"
  }
}

