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

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.digitalocean_token
}

provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.corevia.endpoint
  token                  = digitalocean_kubernetes_cluster.corevia.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.corevia.kube_config[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = digitalocean_kubernetes_cluster.corevia.endpoint
  token                  = digitalocean_kubernetes_cluster.corevia.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.corevia.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes = {
    host  = digitalocean_kubernetes_cluster.corevia.endpoint

    token = digitalocean_kubernetes_cluster.corevia.kube_config[0].token

    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.corevia.kube_config[0].cluster_ca_certificate
    )
  }
}