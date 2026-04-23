# Exposes the PostgreSQL private URI so other Terraform modules or CI pipelines
# can reference the connection string without hard-coding it.
output "postgres_host" {
  value     = digitalocean_database_cluster.postgres.private_uri
  sensitive = true
}

# Bearer token for the dashboard-admin service account, used to authenticate
# to the Headlamp UI at dashboard.corevia.world.
# Retrieve with: terraform output -raw dashboard_admin_token
output "dashboard_admin_token" {
  value     = kubernetes_secret_v1.dashboard_admin_token.data["token"]
  sensitive = true
}
