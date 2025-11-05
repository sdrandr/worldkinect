########################################
# Apollo Router Module (IRSA + Ingress)
# Terraform 1.13.x | AWS Provider 5.x | K8s Provider 2.x | Helm Provider 2.x
########################################

terraform {
  required_version = ">= 1.13.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0, < 6.0.0"
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
# EKS Cluster Data
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
# IRSA Trust Policy (EKS OIDC)
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
# Download Supergraph File
########################################

resource "null_resource" "download_supergraph" {
  triggers = { always = timestamp() }

  provisioner "local-exec" {
    command = "curl -sSL https://supergraph.demo.starstuff.dev/ -o ${path.module}/supergraph.graphql"
  }
}

data "local_file" "supergraph" {
  filename   = "${path.module}/supergraph.graphql"
  depends_on = [null_resource.download_supergraph]
}

########################################
# Namespace + ConfigMap
########################################

resource "kubernetes_namespace" "apollo_system" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_config_map" "apollo_supergraph" {
  depends_on = [kubernetes_namespace.apollo_system]

  metadata {
    name      = "apollo-supergraph"
    namespace = var.namespace
  }

  data = {
    "supergraph.graphql" = data.local_file.supergraph.content
  }
}

########################################
# IAM Role + Policy for Router
########################################

resource "aws_iam_role" "apollo_router_irsa" {
  provider = aws.root
  name     = "${var.name_prefix}-apollo-router-irsa"

  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json

  dynamic "inline_policy" {
    for_each = var.enable_github_oidc ? [1] : []
    content {
      name = "GitHubOIDCTrust"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Federated = "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringLike = {
                "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
              }
              StringEquals = {
                "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
    }
  }

  tags = merge(var.tags, {
    Component = "apollo-router"
    ManagedBy = "terraform"
  })
}

data "aws_iam_policy_document" "apollo_router_policy" {
  provider = aws.root

  statement {
    sid    = "SecretsAndKMSAccess"
    effect = "Allow"
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
# Helm Release: Apollo Router
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

  set {
    name  = "serviceAccount.create"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  depends_on = [
    kubernetes_config_map.apollo_supergraph,
    aws_iam_role_policy_attachment.apollo_router_policy_attach
  ]
}

########################################
# Ingress (AWS ALB + Route53 + ACM)
########################################

module "ingress" {
  source = "../ingress"

  namespace       = var.namespace
  service_name    = "${var.name_prefix}-apollo-router"
  service_port    = 8080
  domain_name     = "router.dev.${var.domain}"
  route53_zone_id = var.route53_zone_id
  aws_region      = var.aws_region
  name_prefix     = var.name_prefix
  environment     = var.env_name

  depends_on = [helm_release.apollo_router]
}

########################################
# Outputs
########################################

output "apollo_router_irsa_role_arn" {
  description = "IAM Role ARN used by Apollo Router via IRSA"
  value       = aws_iam_role.apollo_router_irsa.arn
}

output "router_url" {
  description = "Base URL for Apollo Router ingress endpoint"
  value       = module.ingress.router_url
}
