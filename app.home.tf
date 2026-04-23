# Deployment for the Corevia public-facing home / marketing page (port 8080).
# The replica count is set to null when HPA is enabled so Kubernetes owns
# the desired replica count instead of Terraform overwriting it on every apply.
resource "kubernetes_deployment_v1" "corevia_home" {
  metadata {
    name = "corevia-home"
    labels = {
      app = "corevia-home"
    }
  }

  spec {
    replicas = var.home_hpa_enabled ? null : var.home_replicas

    selector {
      match_labels = {
        app = "corevia-home"
      }
    }

    template {
      metadata {
        labels = {
          app = "corevia-home"
        }
      }

      spec {
        container {
          image = "registry.digitalocean.com/corevia/corevia:home-latest"
          name  = "corevia-home"
          image_pull_policy = "Always"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = var.home_cpu_request
              memory = var.home_memory_request
            }
            limits = {
              cpu    = var.home_cpu_limit
              memory = var.home_memory_limit
            }
          }
        }
      }
    }
  }
}

# HorizontalPodAutoscaler for the home deployment. Created only when
# home_hpa_enabled = true; scales between home_min_replicas and
# home_max_replicas based on average CPU utilisation.
resource "kubernetes_horizontal_pod_autoscaler_v2" "corevia_home" {
  count = var.home_hpa_enabled ? 1 : 0

  metadata {
    name = "corevia-home"
  }

  spec {
    min_replicas = var.home_min_replicas
    max_replicas = var.home_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.corevia_home.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.home_cpu_utilization_target
        }
      }
    }
  }
}

# ClusterIP service that exposes the home pods on port 80 (mapped from
# container port 8080). The Ingress routes www.corevia.world to this service.
resource "kubernetes_service_v1" "corevia_home_lb" {
  metadata {
    name = "corevia-home-lb"
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.corevia_home.metadata[0].labels.app
    }

    type = "ClusterIP"

    port {
      port        = 80
      target_port = 8080
    }
  }
}
