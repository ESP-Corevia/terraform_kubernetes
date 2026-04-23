# Deploys the Headlamp Kubernetes dashboard via Helm into the
# kubernetes-dashboard namespace. Headlamp's built-in ingress is left disabled
# so that all TLS termination is handled by the centralised corevia Ingress.
resource "helm_release" "kubernetes_dashboard" {
  name             = "headlamp"
  repository       = "https://kubernetes-sigs.github.io/headlamp/"
  chart            = "headlamp"
  namespace        = "kubernetes-dashboard"
  create_namespace = true

  # set? = {
  #   name  = "app.ingress.enabled"
  #   value = "false"
  # }
}

# ExternalName service that makes the Headlamp ClusterIP reachable from the
# default namespace, following the same cross-namespace proxy pattern used for
# Grafana and Prometheus in networking.tf.
resource "kubernetes_service_v1" "headlamp_external" {
  metadata {
    name = "headlamp-external"
  }

  spec {
    type          = "ExternalName"
    external_name = "headlamp.kubernetes-dashboard.svc.cluster.local"
  }

  depends_on = [helm_release.kubernetes_dashboard]
}

# Dedicated service account used to generate a long-lived token for
# authenticating to the Headlamp UI. Scoped to the kubernetes-dashboard
# namespace and granted cluster-admin below.
resource "kubernetes_service_account_v1" "dashboard_admin" {
  metadata {
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"
  }

  depends_on = [helm_release.kubernetes_dashboard]
}

# Grants the dashboard-admin service account full cluster-admin privileges so
# the Headlamp UI can read and manage all cluster resources.
resource "kubernetes_cluster_role_binding_v1" "dashboard_admin" {
  metadata {
    name = "dashboard-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.dashboard_admin.metadata[0].name
    namespace = "kubernetes-dashboard"
  }
}

# Long-lived service account token secret for the dashboard-admin account.
# The kubernetes.io/service-account.name annotation links this secret to the
# service account so the token is automatically populated by Kubernetes.
resource "kubernetes_secret_v1" "dashboard_admin_token" {
  metadata {
    name      = "dashboard-admin-token"
    namespace = "kubernetes-dashboard"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.dashboard_admin.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [kubernetes_service_account_v1.dashboard_admin]
}
