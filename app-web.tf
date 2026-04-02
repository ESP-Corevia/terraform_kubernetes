resource "kubernetes_deployment_v1" "corevia_web" {
  metadata {
    name = "corevia-web"
    labels = {
      app = "corevia-web"
    }
  }

  spec {
    replicas = var.web_hpa_enabled ? null : var.web_replicas

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
          image_pull_policy = "Always"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = var.web_cpu_request
              memory = var.web_memory_request
            }
            limits = {
              cpu    = var.web_cpu_limit
              memory = var.web_memory_limit
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "corevia_web" {
  count = var.web_hpa_enabled ? 1 : 0

  metadata {
    name = "corevia-web"
  }

  spec {
    min_replicas = var.web_min_replicas
    max_replicas = var.web_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.corevia_web.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.web_cpu_utilization_target
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
      app = kubernetes_deployment_v1.corevia_web.metadata[0].labels.app
    }

    type = "ClusterIP"

    port {
      port        = 80
      target_port = 80
    }
  }
}
