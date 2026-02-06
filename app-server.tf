resource "kubernetes_deployment_v1" "corevia_server" {
  metadata {
    name = "corevia-server"
    labels = {
      app = "corevia-server"
    }
  }

  spec {
    replicas = 1

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
            value = "http://corevia.world"
          }

          env {
            name  = "BETTER_AUTH_SECRET"
            value = var.BETTER_AUTH_SECRET
          }

          env {
            name  = "BETTER_AUTH_URL"
            value = "http://corevia.world"
          }

          env {
            name  = "SESSION_SECRET"
            value = var.SESSION_SECRET
          }

          env {
            name  = "NODE_ENV"
            value = "development"
          }

          env {
            name  = "NODE_TLS_REJECT_UNAUTHORIZED"
            value = "0"
          }
        }
      }
    }
  }
}

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
