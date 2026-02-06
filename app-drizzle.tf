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
