resource "digitalocean_firewall" "k8s_kubelet" {
  name        = "k8s-kubelet-access"
  droplet_ids = digitalocean_kubernetes_cluster.corevia.node_pool[0].nodes[*].droplet_id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "10250"
    source_addresses = ["10.244.0.0/16"]
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  timeout    = 600

  values = [
    <<-YAML
      args:
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP
    YAML
  ]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  set = [
    {
      name  = "grafana.adminPassword"
      value = var.GRAFANA_ADMIN_PASSWORD
    },
    {
      name  = "grafana.ingress.enabled"
      value = "false"
    },
    {
      name  = "prometheus.ingress.enabled"
      value = "false"
    },
    {
      name  = "alertmanager.enabled"
      value = "false"
    },
    {
      name  = "thanosRuler.enabled"
      value = "false"
    },
    {
      name  = "prometheusOperator.prometheusAgentSelector.any"
      value = "false"
    }
  ]

  depends_on = [helm_release.metrics_server]
}

