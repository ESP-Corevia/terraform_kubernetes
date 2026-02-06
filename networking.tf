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
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
}

resource "helm_release" "externaldns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  values = [file("external-dns-ionos-values.yaml")]
}

resource "kubernetes_ingress_v1" "corevia" {
  metadata {
    name = "corevia-ingress"
    annotations = {
      "kubernetes.io/ingress.class"                   = "nginx"
      "external-dns.alpha.kubernetes.io/hostname"     = "back-office.corevia.world,drizzle.corevia.world,api.corevia.world,www.corevia.world"
      "external-dns.alpha.kubernetes.io/ttl"          = "60"
    }
  }

  spec {
    rule {
      host = "back-office.corevia.world"
      http {
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

    rule {
      host = "drizzle.corevia.world"
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.corevia_drizzle_lb.metadata[0].name
              port {
                number = 3001
              }
            }
          }
        }
      }
    }

    rule {
      host = "api.corevia.world"
      http {
        path {
          path      = "/"
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
      }
    }

    rule {
      host = "www.corevia.world"
      http {
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
