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

resource "kubernetes_service_account_v1" "dashboard_admin" {
  metadata {
    name      = "dashboard-admin"
    namespace = "kubernetes-dashboard"
  }

  depends_on = [helm_release.kubernetes_dashboard]
}

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
