# ─── Credentials ─────────────────────────────────────────────────────────────

variable "digitalocean_token" {
  description = "DigitalOcean API token used to manage cloud resources"
  type        = string
  sensitive   = true
}

variable "BETTER_AUTH_SECRET" {
  description = "Secret key used by Better Auth to sign sessions and tokens"
  type        = string
  default     = "supersecret"
}

variable "NVIDIA_API_KEY" {
  description = "NVIDIA API key for AI/GPU-related service calls in the server"
  type        = string
  default     = "supersecret"
}

variable "SESSION_SECRET" {
  description = "Secret used to sign and verify user session cookies"
  type        = string
  default     = "supersecret"
}

variable "NODE_ENV" {
  description = "Node.js runtime environment (production | development)"
  type        = string
  default     = "production"
}

variable "IONOS_DNS_SECRET" {
  description = "IONOS DNS TSIG secret used by ExternalDNS to manage DNS records"
  type        = string
  sensitive   = true
}

# ─── S3 object storage ───────────────────────────────────────────────────────

variable "S3_BUCKET_NAME" {
  description = "S3 bucket name used by the server for object storage"
  type        = string
  default     = "corevia"
}

variable "S3_ENDPOINT" {
  description = "S3-compatible endpoint URL"
  type        = string
  default     = "https://ax0lxa5hfujr.compat.objectstorage.eu-paris-1.oci.customer-oci.com/"
}

variable "S3_ACCESS_KEY" {
  description = "S3 access key ID"
  type        = string
  sensitive   = true
}

variable "S3_SECRET_KEY" {
  description = "S3 secret access key"
  type        = string
  sensitive   = true
}

variable "S3_REGION" {
  description = "S3 bucket region"
  type        = string
  default     = "eu-paris-1"
}

variable "S3_FORCE_PATH_STYLE" {
  description = "Force path-style addressing for S3 requests"
  type        = bool
  default     = true
}

# ─── Domain URLs ─────────────────────────────────────────────────────────────

variable "BACKOFFICE_URL" {
  description = "Public hostname for the back-office web application"
  type        = string
  default     = "back-office.corevia.world"
}

variable "API_URL" {
  description = "Public hostname for the backend API server"
  type        = string
  default     = "api.corevia.world"
}

variable "DRIZZLE_URL" {
  description = "Public hostname for the Drizzle ORM gateway (DB studio)"
  type        = string
  default     = "drizzle.corevia.world"
}

variable "WWW_URL" {
  description = "Public hostname for the main marketing / home page"
  type        = string
  default     = "www.corevia.world"
}

variable "DASHBOARD_URL" {
  description = "Public hostname for the Headlamp Kubernetes dashboard"
  type    = string
  default = "dashboard.corevia.world"
}

# ─── Server app scaling & resources ──────────────────────────────────────────

variable "server_replicas" {
  description = "Static replica count when HPA is disabled"
  type    = number
  default = 1
}

variable "server_hpa_enabled" {
  description = "Enable the HorizontalPodAutoscaler for the server deployment"
  type    = bool
  default = false
}

variable "server_min_replicas" {
  description = "Minimum replicas when HPA is active"
  type    = number
  default = 1
}

variable "server_max_replicas" {
  description = "Maximum replicas when HPA is active"
  type    = number
  default = 5
}

variable "server_cpu_utilization_target" {
  description = "CPU utilization percentage that triggers HPA scale-out"
  type    = number
  default = 80
}

variable "server_cpu_request" {
  description = "CPU resource request for each server pod"
  type    = string
  default = "100m"
}

variable "server_memory_request" {
  description = "Memory resource request for each server pod"
  type    = string
  default = "128Mi"
}

variable "server_cpu_limit" {
  description = "CPU resource limit for each server pod"
  type    = string
  default = "500m"
}

variable "server_memory_limit" {
  description = "Memory resource limit for each server pod"
  type    = string
  default = "512Mi"
}

# ─── Web app scaling & resources ─────────────────────────────────────────────

variable "web_replicas" {
  description = "Static replica count when HPA is disabled"
  type    = number
  default = 1
}

variable "web_hpa_enabled" {
  description = "Enable the HorizontalPodAutoscaler for the web deployment"
  type    = bool
  default = false
}

variable "web_min_replicas" {
  description = "Minimum replicas when HPA is active"
  type    = number
  default = 1
}

variable "web_max_replicas" {
  description = "Maximum replicas when HPA is active"
  type    = number
  default = 3
}

variable "web_cpu_utilization_target" {
  description = "CPU utilization percentage that triggers HPA scale-out"
  type    = number
  default = 80
}

variable "web_cpu_request" {
  description = "CPU resource request for each web pod"
  type    = string
  default = "50m"
}

variable "web_memory_request" {
  description = "Memory resource request for each web pod"
  type    = string
  default = "32Mi"
}

variable "web_cpu_limit" {
  description = "CPU resource limit for each web pod"
  type    = string
  default = "100m"
}

variable "web_memory_limit" {
  description = "Memory resource limit for each web pod"
  type    = string
  default = "128Mi"
}

# ─── Home app scaling & resources ────────────────────────────────────────────

variable "home_replicas" {
  description = "Static replica count when HPA is disabled"
  type    = number
  default = 1
}

variable "home_hpa_enabled" {
  description = "Enable the HorizontalPodAutoscaler for the home deployment"
  type    = bool
  default = false
}

variable "home_min_replicas" {
  description = "Minimum replicas when HPA is active"
  type    = number
  default = 1
}

variable "home_max_replicas" {
  description = "Maximum replicas when HPA is active"
  type    = number
  default = 3
}

variable "home_cpu_utilization_target" {
  description = "CPU utilization percentage that triggers HPA scale-out"
  type    = number
  default = 80
}

variable "home_cpu_request" {
  description = "CPU resource request for each home pod"
  type    = string
  default = "50m"
}

variable "home_memory_request" {
  description = "Memory resource request for each home pod"
  type    = string
  default = "32Mi"
}

variable "home_cpu_limit" {
  description = "CPU resource limit for each home pod"
  type    = string
  default = "100m"
}

variable "home_memory_limit" {
  description = "Memory resource limit for each home pod"
  type    = string
  default = "128Mi"
}

# ─── Monitoring ──────────────────────────────────────────────────────────────

variable "GRAFANA_ADMIN_PASSWORD" {
  description = "Initial admin password for the Grafana web UI"
  type      = string
  sensitive = true
}

variable "GRAFANA_URL" {
  description = "Public hostname for the Grafana dashboard"
  type    = string
  default = "grafana.corevia.world"
}

variable "PROMETHEUS_URL" {
  description = "Public hostname for the Prometheus web UI"
  type    = string
  default = "prometheus.corevia.world"
}
