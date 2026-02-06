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
      app = kubernetes_deployment_v1.corevia_web.metadata[0].labels.app
    }

    type = "ClusterIP"

    port {
      port        = 80
      target_port = 80
    }
  }
}
