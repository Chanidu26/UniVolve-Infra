# Section 9 — Key Vault
resource "azurerm_key_vault" "main" {
  name                          = "kv-${var.prefix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = true # simpler for adding secrets below; the private endpoint still restricts the backend's actual runtime path
  tags                          = var.tags
}

# Create this private endpoint after the storage one above (step 8), same reasoning
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-kv"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["keyvault"].id]
  }

  depends_on = [azurerm_private_endpoint.storage]
}

# Grant the deploying identity access to add secrets below
resource "azurerm_role_assignment" "kv_admin_current_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
