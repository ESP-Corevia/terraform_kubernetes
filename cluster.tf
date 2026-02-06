resource "digitalocean_kubernetes_cluster" "corevia" {
  name    = "corevia"
  region  = "fra1"
  version = "1.34.1-do.3"

  registry_integration = true

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}
