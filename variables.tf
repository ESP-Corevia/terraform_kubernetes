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