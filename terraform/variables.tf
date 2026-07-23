variable "project"     { default = "vms" }
variable "location"    { default = "southeastasia" }
variable "environment" { default = "prod" }

variable "db_admin_user"     { default = "vmsadmin" }
variable "db_admin_password" {
  description = "PostgreSQL admin password (stored in Key Vault)"
  type        = string
  sensitive   = true
}

variable "tenant_name" { description = "Entra External ID tenant short name" }
variable "tenant_id"   { description = "Entra External ID tenant GUID" }
variable "client_id"   { description = "SPA app registration client ID" }

variable "backend_image" {
  description = "Container image, e.g. <acr>.azurecr.io/vms-backend:latest"
  default     = ""
}
