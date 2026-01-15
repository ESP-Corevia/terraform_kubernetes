variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "BETTER_AUTH_SECRET" {
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