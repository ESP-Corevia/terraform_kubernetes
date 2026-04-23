data "digitalocean_vpc" "cluster_vpc" {
  id = digitalocean_kubernetes_cluster.corevia.vpc_uuid
}

# Allows the pod CIDR and the cluster VPC (used by DO's konnectivity proxy)
# to reach the kubelet on every worker. Without this, metrics-server can't
# scrape CPU/memory and `kubectl logs`/`exec` fail with proxy 500 errors.
resource "digitalocean_firewall" "k8s_kubelet" {
  name        = "k8s-kubelet-access"
  droplet_ids = digitalocean_kubernetes_cluster.corevia.node_pool[0].nodes[*].droplet_id

  inbound_rule {
    protocol   = "tcp"
    port_range = "10250"
    source_addresses = [
      data.digitalocean_vpc.cluster_vpc.ip_range,
      "10.244.0.0/16",
    ]
  }
}

# Kubernetes Metrics Server. --kubelet-insecure-tls is required because
# DigitalOcean nodes use self-signed kubelet certificates.
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
      resources:
        requests:
          cpu: 50m
          memory: 100Mi
        limits:
          memory: 200Mi
    YAML
  ]

  depends_on = [digitalocean_firewall.k8s_kubelet]
}

# kube-prometheus-stack (Prometheus + Grafana). AlertManager is off to save
# resources. Every sub-chart has explicit requests/limits so the scheduler
# can pack pods safely and nothing OOM-evicts the app workloads. Prometheus
# and Grafana use DigitalOcean block storage so dashboards and metrics
# survive pod restarts.
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 900

  values = [
    <<-YAML
      alertmanager:
        enabled: false

      grafana:
        ingress:
          enabled: false
        resources:
          requests:
            cpu: 50m
            memory: 128Mi
          limits:
            memory: 256Mi
        persistence:
          enabled: true
          type: pvc
          storageClassName: do-block-storage
          size: 2Gi

      prometheus:
        ingress:
          enabled: false
        prometheusSpec:
          retention: 7d
          resources:
            requests:
              cpu: 200m
              memory: 512Mi
            limits:
              memory: 1Gi
          storageSpec:
            volumeClaimTemplate:
              spec:
                storageClassName: do-block-storage
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 10Gi

      prometheusOperator:
        resources:
          requests:
            cpu: 50m
            memory: 128Mi
          limits:
            memory: 256Mi

      kube-state-metrics:
        resources:
          requests:
            cpu: 20m
            memory: 64Mi
          limits:
            memory: 128Mi

      prometheus-node-exporter:
        resources:
          requests:
            cpu: 20m
            memory: 32Mi
          limits:
            memory: 64Mi
    YAML
  ]

  set_sensitive = [
    {
      name  = "grafana.adminPassword"
      value = var.GRAFANA_ADMIN_PASSWORD
    }
  ]

  depends_on = [helm_release.metrics_server]
}

