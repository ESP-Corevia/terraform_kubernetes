# Provisions the Corevia Kubernetes cluster on DigitalOcean in the Frankfurt
# region (fra1). Registry integration is enabled so pods can pull images from
# the DigitalOcean container registry without extra image-pull secrets.
# The worker pool auto-scales between 2 and 4 nodes (s-2vcpu-4gb droplets);
# the 4 GB size is required to comfortably fit the monitoring stack plus apps,
# and min 2 nodes keeps the cluster usable while a node drains or reboots.
resource "digitalocean_kubernetes_cluster" "corevia" {
  name    = "corevia"
  region  = "fra1"
  version = "1.35.1-do.2"

  registry_integration = true

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 4
  }
}
