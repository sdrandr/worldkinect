########################################
# IRSA Apollo Router Module — NIST / Enterprise Ready
# Terraform 1.13.4 | AWS Provider 5.x | K8s Provider 2.x | Helm Provider 2.x
########################################

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0, < 6.0.0"

      # Accept aliased provider (aws.root) passed from root
      configuration_aliases = [aws.root]
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }

    local = {
      source = "hashicorp/local"
    }

    null = {
      source = "hashicorp/null"
    }
  }
}

########################################
# EKS CLUSTER DATA SOURCES
########################################

data "aws_eks_cluster" "this" {
  provider = aws.root
  name     = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  provider = aws.root
  name     = var.eks_cluster_name
}

########################################
# IRSA TRUST POLICY (OIDC → IAM)
########################################

data "aws_iam_policy_document" "irsa_assume_role" {
  provider = aws.root

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "${var.oidc_provider_issuer}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

########################################
# DOWNLOAD AND LOAD SUPERGRAPH FILE
########################################

resource "null_resource" "download_supergraph" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "curl -sSL https://supergraph.demo.starstuff.dev/ -o ${path.module}/supergraph.graphql"
  }
}

data "local_file" "supergraph" {
  filename   = "${path.module}/supergraph.graphql"
  depends_on = [null_resource.download_supergraph]
}

########################################
# KUBERNETES CONFIGMAP (Supergraph)
########################################

resource "kubernetes_config_map" "apollo_supergraph" {
  metadata {
    name      = "apollo-supergraph"
    namespace = var.namespace
  }

  data = {
    "supergraph.graphql" = data.local_file.supergraph.content
  }
}

########################################
# KUBERNETES SERVICE ACCOUNT (IRSA)
########################################

resource "kubernetes_service_account" "apollo_router" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.apollo_router_irsa.arn
    }
  }
}

########################################
# IAM ROLE AND POLICY FOR APOLLO ROUTER
########################################

resource "aws_iam_role" "apollo_router_irsa" {
  provider            = aws.root
  name                = "${var.name_prefix}-apollo-router-irsa"
  assume_role_policy  = data.aws_iam_policy_document.irsa_assume_role.json
  tags                = merge(var.tags, { Component = "apollo-router", ManagedBy = "terraform" })
}

data "aws_iam_policy_document" "apollo_router_policy" {
  provider = aws.root

  statement {
    sid     = "SecretsAndKMSAccess"
    effect  = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "kms:DescribeKey",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "apollo_router_policy" {
  provider = aws.root
  name     = "${var.name_prefix}-apollo-router-policy"
  policy   = data.aws_iam_policy_document.apollo_router_policy.json
}

resource "aws_iam_role_policy_attachment" "apollo_router_policy_attach" {
  provider   = aws.root
  role       = aws_iam_role.apollo_router_irsa.name
  policy_arn = aws_iam_policy.apollo_router_policy.arn
}

########################################
# HELM RELEASE — Apollo Router
########################################

resource "helm_release" "apollo_router" {
  name             = "${var.name_prefix}-apollo-router"
  repository       = "oci://ghcr.io/apollographql/helm-charts"
  chart            = "router"
  version          = "2.8.0"
  namespace        = var.namespace
  create_namespace = true

  timeout = 900
  wait    = true
  atomic  = true

  values = [
    templatefile("${path.module}/values.yaml", {
      subgraphs            = var.subgraphs
      oidc_jwt_issuer      = var.oidc_jwt_issuer
      oidc_audience        = var.oidc_audience
      irsa_role_arn        = aws_iam_role.apollo_router_irsa.arn
      namespace            = var.namespace
      domain               = var.domain
      service_account_name = var.service_account_name
      region               = var.aws_region
    })
  ]

  depends_on = [
    kubernetes_config_map.apollo_supergraph,
    kubernetes_service_account.apollo_router,
    aws_iam_role_policy_attachment.apollo_router_policy_attach
  ]
}

########################################
# OUTPUTS
########################################

output "apollo_router_irsa_role_arn" {
  value       = aws_iam_role.apollo_router_irsa.arn
  description = "IAM Role ARN used by Apollo Router via IRSA"
}

output "router_url" {
  value       = "https://router.${var.domain}"
  description = "Base URL for Apollo Router"
}
