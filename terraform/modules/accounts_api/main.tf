# ============================================================
# Terraform Module: accounts-api
# Deploys Accounts API subgraph to EKS
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0"
      configuration_aliases = [aws.root]
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

# ============================================================
# Variables
# ============================================================

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "apollo-system"
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "accounts-api"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from EKS"
  type        = string
}

variable "oidc_provider_issuer" {
  description = "OIDC provider issuer URL from EKS"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "worldkinect/accounts-api"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# ============================================================
# ECR Repository
# ============================================================

resource "aws_ecr_repository" "accounts_api" {
  provider = aws.root
  name     = var.ecr_repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_tag_mutability = "MUTABLE"

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-accounts-api-ecr"
    Component = "accounts-api"
  })
}

resource "aws_ecr_lifecycle_policy" "accounts_api" {
  provider   = aws.root
  repository = aws_ecr_repository.accounts_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================================
# IAM Role for Service Account (IRSA)
# ============================================================

data "aws_caller_identity" "current" {
  provider = aws.root
}

# IAM Role
resource "aws_iam_role" "accounts_api" {
  provider = aws.root
  name     = "${var.name_prefix}-accounts-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_issuer, "https://", "")}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${replace(var.oidc_provider_issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-accounts-api-role"
    Component = "accounts-api"
  })
}

# IAM Policy for ECR access
resource "aws_iam_role_policy" "accounts_api_ecr" {
  provider = aws.root
  name     = "ecr-access"
  role     = aws_iam_role.accounts_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = aws_ecr_repository.accounts_api.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for Secrets Manager (if needed)
resource "aws_iam_role_policy" "accounts_api_secrets" {
  provider = aws.root
  name     = "secrets-access"
  role     = aws_iam_role.accounts_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.name_prefix}/*"
      }
    ]
  })
}

# ============================================================
# Kubernetes Resources
# ============================================================

# Namespace
resource "kubernetes_namespace" "apollo_system" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Service Account
resource "kubernetes_service_account" "accounts_api" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.apollo_system.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.accounts_api.arn
    }
  }
}

# Deployment
resource "kubernetes_deployment" "accounts_api" {
  depends_on = [
    kubernetes_service_account.accounts_api
  ]

  metadata {
    name      = "accounts-api"
    namespace = kubernetes_namespace.apollo_system.metadata[0].name
    labels = {
      app       = "accounts-api"
      component = "subgraph"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "accounts-api"
      }
    }

    template {
      metadata {
        labels = {
          app       = "accounts-api"
          component = "subgraph"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.accounts_api.metadata[0].name

        container {
          name              = "accounts-api"
          image             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository_name}:${var.image_tag}"
          image_pull_policy = "Always"

          port {
            name           = "http"
            container_port = 4000
            protocol       = "TCP"
          }

          env {
            name  = "PORT"
            value = "4000"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            tcp_socket {
              port = 4000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 4000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

# Service
resource "kubernetes_service" "accounts_api" {
  metadata {
    name      = "accounts-api"
    namespace = kubernetes_namespace.apollo_system.metadata[0].name
    labels = {
      app = "accounts-api"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 4000
      target_port = 4000
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = "accounts-api"
    }
  }
}

# ============================================================
# Outputs
# ============================================================

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.accounts_api.repository_url
}

output "service_account_role_arn" {
  description = "IAM role ARN for the service account"
  value       = aws_iam_role.accounts_api.arn
}

output "service_endpoint" {
  description = "Internal service endpoint"
  value       = "http://${kubernetes_service.accounts_api.metadata[0].name}.${kubernetes_namespace.apollo_system.metadata[0].name}.svc.cluster.local:4000"
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.apollo_system.metadata[0].name
}
