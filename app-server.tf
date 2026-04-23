# Deployment for the Corevia Node.js backend API (port 3000).
# The replica count is set to null when HPA is enabled so Kubernetes owns
# the desired replica count instead of Terraform overwriting it on every apply.
# Database credentials are injected via envFrom; all other env vars are set
# inline so they are visible in the Terraform plan.
resource "kubernetes_deployment_v1" "corevia_server" {
  metadata {
    name = "corevia-server"
    labels = {
      app = "corevia-server"
    }
  }

  spec {
    replicas = var.server_hpa_enabled ? null : var.server_replicas

    selector {
      match_labels = {
        app = "corevia-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "corevia-server"
        }
      }

      spec {
        container {
          image = "registry.digitalocean.com/corevia/corevia:server-latest"
          name  = "corevia-server"
          image_pull_policy = "Always"

          port {
            container_port = 3000
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.postgres.metadata[0].name
            }
          }

          env {
            name  = "CORS_ORIGIN"
            value = "https://${var.BACKOFFICE_URL}"
          }

          env {
            name  = "BETTER_AUTH_SECRET"
            value = var.BETTER_AUTH_SECRET
          }

          env {
            name  = "BETTER_AUTH_URL"
            value = "https://${var.API_URL}"
          }

          env {
            name  = "SESSION_SECRET"
            value = var.SESSION_SECRET
          }

          env {
            name = "NVIDIA_API_KEY"
            value = var.NVIDIA_API_KEY
          }

          env {
            name  = "S3_BUCKET_NAME"
            value = var.S3_BUCKET_NAME
          }

          env {
            name  = "S3_ENDPOINT"
            value = var.S3_ENDPOINT
          }

          env {
            name  = "S3_ACCESS_KEY"
            value = var.S3_ACCESS_KEY
          }

          env {
            name  = "S3_SECRET_KEY"
            value = var.S3_SECRET_KEY
          }

          env {
            name  = "S3_REGION"
            value = var.S3_REGION
          }

          env {
            name  = "S3_FORCE_PATH_STYLE"
            value = tostring(var.S3_FORCE_PATH_STYLE)
          }

          env {
            name  = "NODE_ENV"
            value = "development"
          }

          env {
            name  = "NODE_TLS_REJECT_UNAUTHORIZED"
            value = "0"
          }

          resources {
            requests = {
              cpu    = var.server_cpu_request
              memory = var.server_memory_request
            }
            limits = {
              cpu    = var.server_cpu_limit
              memory = var.server_memory_limit
            }
          }
        }
      }
    }
  }
}

# HorizontalPodAutoscaler for the server deployment. Created only when
# server_hpa_enabled = true; scales between server_min_replicas and
# server_max_replicas based on average CPU utilisation.
resource "kubernetes_horizontal_pod_autoscaler_v2" "corevia_server" {
  count = var.server_hpa_enabled ? 1 : 0

  metadata {
    name = "corevia-server"
  }

  spec {
    min_replicas = var.server_min_replicas
    max_replicas = var.server_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.corevia_server.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.server_cpu_utilization_target
        }
      }
    }
  }
}

# ClusterIP service that exposes the server pods on port 3000 within the
# cluster. The Ingress routes api.corevia.world to this service.
resource "kubernetes_service_v1" "corevia_server_lb" {
  metadata {
    name = "corevia-server-lb"
  }

  spec {
    selector = {
      app = "corevia-server"
    }

    type = "ClusterIP"

    port {
      port        = 3000
      target_port = 3000
    }
  }
}
