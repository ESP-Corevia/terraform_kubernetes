resource "digitalocean_kubernetes_cluster" "corevia" {
  name   = "corevia"
  region = "fra1"
  version = "1.34.1-do.2"

  registry_integration = true

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}

resource "kubernetes_secret_v1" "ionos_credentials" {
  metadata {
    name      = "ionos-credentials"
    namespace = "kube-system"
  }

  data = {
    api-key = var.IONOS_DNS_SECRET
  }

  type = "Opaque"
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true
}

resource "helm_release" "externaldns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  values = [file("external-dns-ionos-values.yaml")]
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

    type = "ClusterIP"

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
      app = "corevia-server" # from kubernetes_deployment_v1.corevia_server.metadata[0].labels.app
    }

    type = "ClusterIP"

    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_ingress_v1" "corevia" {
  metadata {
    name = "corevia-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "external-dns.alpha.kubernetes.io/hostname" = "test.corevia.world"
    }
  }

  spec {
    rule {
      host = "test.corevia.world"

      http {
        path {
          path      = "/api"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.corevia_server_lb.metadata[0].name
              port {
                number = 3000
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.corevia_web_lb.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
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
