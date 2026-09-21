variable "prefix" {
  description = "Naming prefix reused across all resources"
  type        = string
  default     = "univolve-prod"
}

variable "location" {
  description = "Primary Azure region (used for everything except Static Web Apps)"
  type        = string
  default     = "Southeast Asia"
}

variable "swa_location" {
  description = "Region for the two Static Web Apps (Southeast Asia is commonly unavailable for this resource type)"
  type        = string
  default     = "East Asia"
}

variable "acs_data_location" {
  description = "Data residency region for Communication/Email Communication Services"
  type        = string
  default     = "Asia Pacific"
}

variable "db_admin_username" {
  description = "PostgreSQL Flexible Server administrator login"
  type        = string
  default     = "univolveadmin"
}

variable "db_admin_password" {
  description = "PostgreSQL Flexible Server administrator password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "univolvedb"
}

variable "backend_image" {
  description = "Full backend container image reference in the UniVolve Azure Container Registry."
  type        = string
  default     = "acrunivolveprod.azurecr.io/univolve-backend:latest"
}

variable "google_client_id" {
  description = "Google OAuth 2.0 Client ID (created manually in Google Cloud Console — shared by both frontends and the backend)"
  type        = string
}

variable "jwt_secret" {
  description = "Secret used to sign the backend's own session JWTs, issued after verifying a Google ID token"
  type        = string
  sensitive   = true
}

variable "super_admin_emails" {
  description = "Comma-separated Google account emails to treat as SUPER_ADMIN"
  type        = string
  default     = ""
}

variable "apim_publisher_name" {
  description = "API Management publisher/organization name"
  type        = string
  default     = "UniVolve"
}

variable "apim_publisher_email" {
  description = "API Management publisher contact email"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    project = "univolve"
  }
}
