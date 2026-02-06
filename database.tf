resource "digitalocean_database_cluster" "postgres" {
  name       = "corevia-db"
  engine     = "pg"
  version    = "17"
  size       = "db-s-1vcpu-1gb"
  region     = "fra1"
  node_count = 1
}

resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name = "postgres-secret"
  }

  data = {
    DATABASE_URL = digitalocean_database_cluster.postgres.private_uri
  }
}
