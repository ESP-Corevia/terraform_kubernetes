output "loadbalancer_ip_server" {
  value = kubernetes_service_v1.corevia_server_lb.status[0].load_balancer[0].ingress[0].ip
}

output "loadbalancer_ip_web" {
  value = kubernetes_service_v1.corevia_web_lb.status[0].load_balancer[0].ingress[0].ip
}

output "postgres_host" {
  value = digitalocean_database_cluster.postgres.private_host
}
