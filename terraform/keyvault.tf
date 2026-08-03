resource "azurerm_key_vault" "kv" {
  name                          = "kv-${local.name}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = var.key_vault_public_network_access_enabled
  tags                          = local.tags
}

resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.pe.id
  # Completes the acr -> blob -> kv sequential chain (see storage.tf) - Azure
  # serializes subnet-modifying operations on snet-private-endpoints and rejects
  # concurrent attempts with "ReferencedResourceNotProvisioned ... Updating state".
  depends_on = [azurerm_private_endpoint.blob]

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }
}

resource "azurerm_role_assignment" "tf_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.tf_kv_admin]
}

resource "azurerm_key_vault_secret" "acs_connection" {
  name         = "acs-connection-string"
  value        = azurerm_communication_service.acs.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.tf_kv_admin]
}

resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.assets.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.tf_kv_admin]
}

resource "azurerm_key_vault_secret" "db_schema" {
  name         = "db-schema"
  value        = file("${path.module}/schema.sql")
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.tf_kv_admin]
}