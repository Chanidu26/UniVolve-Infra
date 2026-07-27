variable "project" { default = "vms" }
variable "location" { default = "southeastasia" }
variable "environment" { default = "prod" }

variable "db_admin_user" { default = "vmsadmin" }
variable "db_admin_password" {
  description = "PostgreSQL admin password (stored in Key Vault)"
  type        = string
  sensitive   = true
}

variable "tenant_name" { description = "Entra External ID tenant short name" }
variable "tenant_id" { description = "Entra External ID tenant GUID" }

# The backend's own API app registration (exposes an "access" scope) - NOT either
# SPA's client ID. Both admin-frontend and volunteer-frontend are separate SPA app
# registrations that request this API's scope; the resulting token's audience is
# this API's identifier regardless of which SPA acquired it.
variable "api_client_id" { description = "API app registration's Application (client) ID" }

variable "backend_image" {
  description = "Container image, e.g. <acr>.azurecr.io/vms-backend:latest"
  default     = ""
}
