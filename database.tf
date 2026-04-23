# Managed PostgreSQL 17 cluster on DigitalOcean (single node, db-s-1vcpu-1gb)
# in Frankfurt. A single-node setup is sufficient for the current workload;
# upgrade node_count and size to enable high-availability when needed.
resource "digitalocean_database_cluster" "postgres" {
  name       = "corevia-db"
  engine     = "pg"
  version    = "17"
  size       = "db-s-1vcpu-1gb"
  region     = "fra1"
  node_count = 1
}

# Kubernetes secret that injects the private connection URI into any pod that
# mounts it via envFrom. Using the private URI keeps traffic inside the VPC
# and avoids egress charges.
resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name = "postgres-secret"
  }

  data = {
    DATABASE_URL = digitalocean_database_cluster.postgres.private_uri
  }
}
