output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "container_app_name" {
  value = azurerm_container_app.backend.name
}

output "admin_swa_default_hostname" {
  value = azurerm_static_web_app.admin.default_host_name
}

output "volunteer_swa_default_hostname" {
  value = azurerm_static_web_app.volunteer.default_host_name
}

output "admin_swa_api_key" {
  value     = azurerm_static_web_app.admin.api_key
  sensitive = true
}

output "volunteer_swa_api_key" {
  value     = azurerm_static_web_app.volunteer.api_key
  sensitive = true
}

output "apim_gateway_url" {
  value = azurerm_api_management.main.gateway_url
}

output "vite_api_url" {
  description = "Value to set as VITE_API_URL in both frontend deploy workflows"
  value       = "${azurerm_api_management.main.gateway_url}/api"
}
