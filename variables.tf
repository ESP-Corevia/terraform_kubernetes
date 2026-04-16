variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "BETTER_AUTH_SECRET" {
  type    = string
  default = "supersecret"
}

variable "NVIDIA_API_KEY" {
  type    = string
  default = "supersecret"
}

variable "SESSION_SECRET" {
  type    = string
  default = "supersecret"
}

variable "NODE_ENV" {
  type    = string
  default = "production"
}

variable "IONOS_DNS_SECRET" {
  description = "IONOS DNS TSIG Secret for ExternalDNS"
  type        = string
  sensitive   = true
}

variable "BACKOFFICE_URL" {
  type        = string
  default     = "back-office.corevia.world"
}

variable "API_URL" {
  type        = string
  default     = "api.corevia.world"
}

variable "DRIZZLE_URL" {
  type        = string
  default     = "drizzle.corevia.world"
}

variable "WWW_URL" {
  type        = string
  default     = "www.corevia.world"
}

variable "DASHBOARD_URL" {
  type    = string
  default = "dashboard.corevia.world"
}

variable "server_replicas" {
  type    = number
  default = 1
}

variable "server_hpa_enabled" {
  type    = bool
  default = false
}

variable "server_min_replicas" {
  type    = number
  default = 1
}

variable "server_max_replicas" {
  type    = number
  default = 5
}

variable "server_cpu_utilization_target" {
  type    = number
  default = 80
}

variable "server_cpu_request" {
  type    = string
  default = "100m"
}

variable "server_memory_request" {
  type    = string
  default = "128Mi"
}

variable "server_cpu_limit" {
  type    = string
  default = "500m"
}

variable "server_memory_limit" {
  type    = string
  default = "512Mi"
}

variable "web_replicas" {
  type    = number
  default = 1
}

variable "web_hpa_enabled" {
  type    = bool
  default = false
}

variable "web_min_replicas" {
  type    = number
  default = 1
}

variable "web_max_replicas" {
  type    = number
  default = 3
}

variable "web_cpu_utilization_target" {
  type    = number
  default = 80
}

variable "web_cpu_request" {
  type    = string
  default = "50m"
}

variable "web_memory_request" {
  type    = string
  default = "32Mi"
}

variable "web_cpu_limit" {
  type    = string
  default = "100m"
}

variable "web_memory_limit" {
  type    = string
  default = "128Mi"
}

variable "home_replicas" {
  type    = number
  default = 1
}

variable "home_hpa_enabled" {
  type    = bool
  default = false
}

variable "home_min_replicas" {
  type    = number
  default = 1
}

variable "home_max_replicas" {
  type    = number
  default = 3
}

variable "home_cpu_utilization_target" {
  type    = number
  default = 80
}

variable "home_cpu_request" {
  type    = string
  default = "50m"
}

variable "home_memory_request" {
  type    = string
  default = "32Mi"
}

variable "home_cpu_limit" {
  type    = string
  default = "100m"
}

variable "home_memory_limit" {
  type    = string
  default = "128Mi"
}
