resource "digitalocean_kubernetes_cluster" "corevia" {
  name   = "corevia"
  region = "fra1"
  version = "1.34.1-do.1"

  registry_integration = true

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}

resource "kubernetes_deployment_v1" "corevia_web" {
  metadata {
    name = "corevia-web"
    labels = {
      app = "corevia-web"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "corevia-web"
      }
    }

    template {
      metadata {
        labels = {
          app = "corevia-web"
        }
      }

      spec {
        container {
          image = "registry.digitalocean.com/corevia/corevia:web-latest"
          name  = "corevia-web"

          port {
            container_port = 80
          }

          env {
            name  = "NODE_ENV"
            value = var.NODE_ENV
          }

          env {
            name  = "VITE_API_URL"
            value = "http://${kubernetes_service_v1.corevia_server_lb.status[0].load_balancer[0].ingress[0].ip}"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "corevia_web_lb" {
  metadata {
    name = "corevia-web-lb"
  }

  spec {
    selector = {
      app = "corevia-web" # from kubernetes_deployment_v1.corevia_web.metadata[0].labels.app
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }
}

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
            value = "http://${kubernetes_service_v1.corevia_web_lb.status[0].load_balancer[0].ingress[0].ip}"
          }

          env {
            name  = "BETTER_AUTH_SECRET"
            value = var.BETTER_AUTH_SECRET
          }

          env {
            name  = "BETTER_AUTH_URL"
            value = "http://${kubernetes_service_v1.corevia_server_lb.status[0].load_balancer[0].ingress[0].ip}"
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
      app = "corevia-server" # from kubernetes_deployment_v1.corevia_server.metadata[0].labels.app
    }

    type = "LoadBalancer"

    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "digitalocean_database_cluster" "postgres" {
  name       = "corevia-db"
  engine     = "pg"
  version    = "17"
  size       = "db-s-1vcpu-1gb"
  region     = "fra1"
  node_count = 1
}

resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name = "postgres-secret"
  }

  data = {
    DATABASE_URL = digitalocean_database_cluster.postgres.private_uri
  }
}

resource "kubernetes_job_v1" "corevia_migrate_job" {
  metadata {
    name = "corevia-migrate-lb"
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
          image = "registry.digitalocean.com/corevia/corevia:server-latest" # replace with your container

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
    name = "corevia-seed-lb"
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
          image = "registry.digitalocean.com/corevia/corevia:server-latest" # replace with your container

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
        }
      }
    }
  }
}
