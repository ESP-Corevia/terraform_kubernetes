output "postgres_host" {
  value = digitalocean_database_cluster.postgres.private_uri
  sensitive = true
}
