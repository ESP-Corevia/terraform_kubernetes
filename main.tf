terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Authenticates with the DigitalOcean API using a personal access token.
provider "digitalocean" {
  token = var.digitalocean_token
}

# Connects to the Corevia cluster using the endpoint and credentials exported
# directly from the digitalocean_kubernetes_cluster resource, so no local
# kubeconfig file is required.
provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.corevia.endpoint
  token                  = digitalocean_kubernetes_cluster.corevia.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.corevia.kube_config[0].cluster_ca_certificate)
}

# kubectl provider mirrors the kubernetes provider configuration and is used
# for raw YAML manifests (e.g. ClusterIssuer) that the kubernetes provider
# does not support natively.
provider "kubectl" {
  host                   = digitalocean_kubernetes_cluster.corevia.endpoint
  token                  = digitalocean_kubernetes_cluster.corevia.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.corevia.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

# Helm provider uses the same in-cluster credentials so chart installations
# do not depend on a local kubeconfig or helm context.
provider "helm" {
  kubernetes = {
    host  = digitalocean_kubernetes_cluster.corevia.endpoint

    token = digitalocean_kubernetes_cluster.corevia.kube_config[0].token

    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.corevia.kube_config[0].cluster_ca_certificate
    )
  }
}
