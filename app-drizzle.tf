# Deployment for the Drizzle ORM gateway (port 3001), which provides a
# browser-based database studio. Runs a single replica with no HPA — this
# is a developer tool and does not need to scale with production traffic.
# Database credentials are injected from the shared postgres secret.
resource "kubernetes_deployment_v1" "corevia_drizzle" {
  metadata {
    name = "corevia-drizzle"
    labels = {
      app = "corevia-drizzle"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "corevia-drizzle"
      }
    }

    template {
      metadata {
        labels = {
          app = "corevia-drizzle"
        }
      }

      spec {
        container {
          image = "ghcr.io/drizzle-team/gateway:latest"
          name  = "corevia-drizzle"

          port {
            container_port = 3001
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.postgres.metadata[0].name
            }
          }

          env {
            name  = "NODE_TLS_REJECT_UNAUTHORIZED"
            value = "0"
          }

          env {
            name  = "PORT"
            value = "3001"
          }
        }
      }
    }
  }
}

# ClusterIP service that exposes the Drizzle gateway on port 3001.
# The Ingress routes drizzle.corevia.world to this service.
resource "kubernetes_service_v1" "corevia_drizzle_lb" {
  metadata {
    name = "corevia-drizzle-lb"
  }

  spec {
    selector = {
      app = "corevia-drizzle"
    }

    type = "ClusterIP"

    port {
      port        = 3001
      target_port = 3001
    }
  }
}
