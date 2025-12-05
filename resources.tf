resource "digitalocean_kubernetes_cluster" "corevia" {
  name   = "corevia"
  region = "fra1"
  # Grab the latest version slug from `doctl kubernetes options versions` (e.g. "1.14.6-do.1"
  # If set to "latest", latest published version will be used.
  version = "latest"

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3

    taint {
      key    = "workloadKind"
      value  = "database"
      effect = "NoSchedule"
    }
  }
}