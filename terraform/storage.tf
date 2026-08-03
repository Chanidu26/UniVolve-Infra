resource "azurerm_storage_account" "assets" {
  name                            = replace("st${local.name}assets", "-", "")
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
  tags                            = local.tags
}

resource "azurerm_storage_container" "avatars" {
  name                  = "avatars"
  storage_account_name  = azurerm_storage_account.assets.name
  container_access_type = "blob"
}

output "storage_connection_string" {
  value     = azurerm_storage_account.assets.primary_connection_string
  sensitive = true
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.pe.id
  # All private endpoints on snet-private-endpoints must be created sequentially -
  # Azure serializes subnet-modifying operations and rejects concurrent attempts
  # with "ReferencedResourceNotProvisioned ... subnet is in Updating state".
  depends_on = [azurerm_private_endpoint.acr]

  private_service_connection {
    name                           = "blob-connection"
    private_connection_resource_id = azurerm_storage_account.assets.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
