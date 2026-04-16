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

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.16.3"

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]

  depends_on = [helm_release.ingress_nginx]
}

resource "kubectl_manifest" "letsencrypt_cluster_issuer" {
  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: romain@ades.io
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
          - http01:
              ingress:
                class: nginx
  YAML

  depends_on = [helm_release.cert_manager]
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
      "external-dns.alpha.kubernetes.io/hostname"     = "back-office.corevia.world,drizzle.corevia.world,api.corevia.world,www.corevia.world,dashboard.corevia.world"
      "external-dns.alpha.kubernetes.io/ttl"          = "60"
      "cert-manager.io/cluster-issuer"                = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
    }
  }

  spec {
    tls {
      hosts       = [var.BACKOFFICE_URL, var.DRIZZLE_URL, var.API_URL, var.WWW_URL, var.DASHBOARD_URL]
      secret_name = "corevia-tls"
    }

    rule {
      host = var.BACKOFFICE_URL
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
      host = var.DRIZZLE_URL
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
      host = var.API_URL
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
      host = var.WWW_URL
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.corevia_home_lb.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = var.DASHBOARD_URL
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.headlamp_external.metadata[0].name
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
