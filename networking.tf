# Stores the IONOS API key in kube-system so ExternalDNS can read it when
# reconciling DNS records for all public hostnames.
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

# Deploys the NGINX Ingress Controller, which acts as the single entry point
# for all inbound HTTP/HTTPS traffic and routes requests to cluster services.
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
}

# Installs cert-manager with CRDs enabled so it can automatically provision
# and renew TLS certificates via Let's Encrypt.
# Pinned to v1.16.3 to avoid unexpected CRD drift on re-apply.
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

# Creates a cluster-wide cert-manager ClusterIssuer that uses the ACME HTTP-01
# challenge (via the NGINX ingress class) to obtain Let's Encrypt production
# certificates for all public hostnames.
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

# Deploys ExternalDNS configured for the IONOS DNS provider so that Ingress
# hostname annotations are automatically reconciled to DNS A records.
# Configuration details are in external-dns-ionos-values.yaml.
resource "helm_release" "externaldns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  values = [file("external-dns-ionos-values.yaml")]
}

# ExternalName service that proxies the default namespace into the Grafana
# ClusterIP inside the monitoring namespace, allowing the main Ingress to
# route grafana.corevia.world without cross-namespace backend references.
resource "kubernetes_service_v1" "grafana_external" {
  metadata {
    name = "grafana-external"
  }

  spec {
    type          = "ExternalName"
    external_name = "kube-prometheus-stack-grafana.monitoring.svc.cluster.local"
  }
}

# ExternalName service for Prometheus, following the same cross-namespace
# proxy pattern as grafana_external above.
resource "kubernetes_service_v1" "prometheus_external" {
  metadata {
    name = "prometheus-external"
  }

  spec {
    type          = "ExternalName"
    external_name = "kube-prometheus-stack-prometheus.monitoring.svc.cluster.local"
  }
}

# Single Ingress that routes all public hostnames to their respective services.
# cert-manager issues a shared TLS certificate (corevia-tls) covering all
# hosts. ExternalDNS annotations drive automatic DNS record creation with a
# 60-second TTL.
resource "kubernetes_ingress_v1" "corevia" {
  metadata {
    name = "corevia-ingress"
    annotations = {
      "kubernetes.io/ingress.class"                   = "nginx"
      "external-dns.alpha.kubernetes.io/hostname"     = "back-office.corevia.world,drizzle.corevia.world,api.corevia.world,www.corevia.world,dashboard.corevia.world,${var.GRAFANA_URL},${var.PROMETHEUS_URL}"
      "external-dns.alpha.kubernetes.io/ttl"          = "60"
      "cert-manager.io/cluster-issuer"                = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
    }
  }

  spec {
    tls {
      hosts       = [var.BACKOFFICE_URL, var.DRIZZLE_URL, var.API_URL, var.WWW_URL, var.DASHBOARD_URL, var.GRAFANA_URL, var.PROMETHEUS_URL]
      secret_name = "corevia-tls"
    }

    # back-office.corevia.world → corevia-web (port 80)
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

    # drizzle.corevia.world → corevia-drizzle (port 3001)
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

    # api.corevia.world → corevia-server (port 3000)
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

    # www.corevia.world → corevia-home (port 80)
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

    # dashboard.corevia.world → Headlamp (port 80)
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

    # grafana.corevia.world → Grafana via ExternalName proxy (port 80)
    rule {
      host = var.GRAFANA_URL
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.grafana_external.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # prometheus.corevia.world → Prometheus via ExternalName proxy (port 9090)
    rule {
      host = var.PROMETHEUS_URL
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.prometheus_external.metadata[0].name
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }
}
