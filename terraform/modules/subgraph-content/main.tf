resource "kubernetes_deployment" "content_subgraph" {
  metadata {
    name      = "${var.name_prefix}-content-subgraph"
    namespace = var.namespace
    labels = { app = "content-subgraph" }
  }

  spec {
    replicas = 2
    selector { match_labels = { app = "content-subgraph" } }
    template {
      metadata { labels = { app = "content-subgraph" } }
      spec {
        service_account_name = var.service_account
        container {
          name  = "content-subgraph"
          image = var.image
          port { container_port = 4000 }

          env {
            name  = "BOX_APP_SECRET_ARN"
            value = var.box_secret_arn
          }
          env {
            name  = "DYNAMODB_TABLE"
            value = var.dynamodb_table_name
          }
          env {
            name  = "S3_BUCKET"
            value = var.s3_bucket
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "content_subgraph" {
  metadata {
    name      = "${var.name_prefix}-content-subgraph"
    namespace = var.namespace
  }
  spec {
    selector = { app = "content-subgraph" }
    port { 
        port = 80
        target_port = 4000
    }
    type = "ClusterIP"
  }
}

output "url" {
  value = "http://${kubernetes_service.content_subgraph.metadata[0].name}.${var.namespace}.svc.cluster.local"
}
