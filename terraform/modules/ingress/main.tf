########################################
# ALB Ingress Module — Apollo Router
# Terraform 1.13.x | AWS Provider 5.x | Kubernetes 2.30+
# Purpose: Expose Apollo Router via ALB + Route53 + ACM TLS
########################################

terraform {
  required_version = ">= 1.13.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0, < 6.0.0"
    }
  }
}


########################################
# 1️⃣ ACM CERTIFICATE — router.<env>.<domain>
########################################

resource "aws_acm_certificate" "router_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-router-cert"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

########################################
# 2️⃣ ROUTE53 DNS VALIDATION RECORD
########################################

resource "aws_route53_record" "router_cert_validation" {
  zone_id = var.route53_zone_id
  name    = tolist(aws_acm_certificate.router_cert.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.router_cert.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.router_cert.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "router_cert_validation" {
  certificate_arn         = aws_acm_certificate.router_cert.arn
  validation_record_fqdns = [aws_route53_record.router_cert_validation.fqdn]
}


########################################
# 3️⃣ KUBERNETES INGRESS — ALB Integration
########################################

resource "kubernetes_ingress_v1" "apollo_router_ingress" {
  metadata {
    name      = "${var.name_prefix}-apollo-router-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn"      = aws_acm_certificate.router_cert.arn
      "alb.ingress.kubernetes.io/ssl-redirect"         = "443"
      "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\":\"redirect\",\"RedirectConfig\":{\"Protocol\":\"HTTPS\",\"Port\":\"443\",\"StatusCode\":\"HTTP_301\"}}"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.domain_name

      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = var.service_name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    aws_acm_certificate_validation.router_cert_validation
  ]
}


########################################
# Route53 Record → ALB (CNAME)
########################################

# Discover ALBs available in this region
data "aws_lb" "all" {
  for_each = {
    router = "${var.name_prefix}-apollo-router"
  }

  # A placeholder to force dependency — we’ll look up the ALB by tag below
  depends_on = [kubernetes_ingress_v1.apollo_router_ingress]
}

# Retrieve all existing ALBs and find the one associated with the ingress
data "aws_lbs" "active" {
  depends_on = [kubernetes_ingress_v1.apollo_router_ingress]
}

locals {
  # Pull the first ALB whose name includes "apollo-router"
  ingress_lb_dns = one([
    for lb in data.aws_lbs.active.arns : replace(lb, "/^arn:aws:elasticloadbalancing:[^:]+:[0-9]+:loadbalancer\\//", "")
    if can(regex("${var.name_prefix}-apollo-router", lb))
  ])
}

# Route53 DNS record pointing to ALB
resource "aws_route53_record" "router_dns" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 60
  records = [local.ingress_lb_dns]

  depends_on = [data.aws_lbs.active]
}