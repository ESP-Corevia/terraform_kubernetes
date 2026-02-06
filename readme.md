# Terraform Configuration Structure

This Terraform configuration has been organized into modular files for better maintainability.

## File Structure

```
.
├── cluster.tf          # Kubernetes cluster configuration
├── database.tf         # PostgreSQL database and secrets
├── networking.tf       # Ingress, DNS, and network configuration
├── app-web.tf          # Web frontend deployment and service
├── app-server.tf       # Backend API deployment and service
├── app-drizzle.tf      # Drizzle gateway deployment and service
├── jobs.tf             # Database migration and seed jobs
├── terraform.tfvars    # Store the secret
└── variables.tf        # Store the environment variables
```

## File Descriptions

### cluster.tf

- DigitalOcean Kubernetes cluster definition
- Node pool configuration with autoscaling

### database.tf

- PostgreSQL database cluster
- Kubernetes secret for database connection

### networking.tf

- IONOS DNS credentials secret
- Ingress NGINX Helm release
- External DNS Helm release
- Ingress rules for all subdomains:
  - back-office.corevia.world
  - drizzle.corevia.world
  - api.corevia.world
  - www.corevia.world

### app-web.tf

- Web frontend deployment
- ClusterIP service for web application

### app-server.tf

- Backend API deployment
- Environment variables and secrets
- ClusterIP service for API

### app-drizzle.tf

- Drizzle Gateway deployment
- ClusterIP service for Drizzle

### jobs.tf

- Database migration job
- Database seed job
- Uses timestamp-based naming for unique job names

## Benefits of This Structure

1. **Separation of Concerns**: Each file focuses on a specific aspect of the infrastructure
2. **Easier Navigation**: Find resources quickly by their logical grouping
3. **Better Git Workflow**: Smaller diffs when making changes to specific components
4. **Parallel Development**: Multiple team members can work on different files
5. **Reusability**: Individual files can be adapted for other projects

## Usage

All files will be automatically loaded by Terraform from the same directory. Run:

```bash
terraform init
terraform plan
terraform apply
```

To destroy this project, run in order:

```
terraform destroy -target=kubernetes_ingress_v1.corevia
# wait ~1 minute
terraform destroy
```

## Notes

- All files must be in the same directory for Terraform to process them
- You need terraform.tfvars with the digital ocean token like `digitalocean_token="token"`
- Variables referenced (like `var.IONOS_DNS_SECRET`, `var.BETTER_AUTH_SECRET`, etc.) should be defined in a `variables.tf` file
