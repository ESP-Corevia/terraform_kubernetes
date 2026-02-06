resource "kubernetes_job_v1" "corevia_migrate_job" {
  metadata {
    name = "corevia-migrate-${formatdate("YYYYMMDDHHMM", timestamp())}"
    labels = {
      app = "corevia-server"
    }
  }

  spec {
    backoff_limit = 0

    template {
      metadata {
        labels = {
          app = "corevia-server"
        }
      }

      spec {
        restart_policy = "Never"

        container {
          name  = "migrate"
          image = "registry.digitalocean.com/corevia/corevia:server-latest"

          command = ["yarn", "db:migrate"]

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.postgres.metadata[0].name
            }
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

resource "kubernetes_job_v1" "corevia_seed_job" {
  metadata {
    name = "corevia-seed-${formatdate("YYYYMMDDHHMM", timestamp())}"
    labels = {
      app = "corevia-server"
    }
  }

  spec {
    backoff_limit = 0

    template {
      metadata {
        labels = {
          app = "corevia-server"
        }
      }

      spec {
        restart_policy = "Never"

        container {
          name  = "seed"
          image = "registry.digitalocean.com/corevia/corevia:server-latest"

          command = ["yarn", "db:seed"]

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
            name  = "BETTER_AUTH_SECRET"
            value = var.BETTER_AUTH_SECRET
          }

          env {
            name  = "SESSION_SECRET"
            value = var.SESSION_SECRET
          }
        }
      }
    }
  }
}
