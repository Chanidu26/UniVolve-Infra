# Section 8 — Storage Account (avatar + event photo uploads)
resource "azurerm_storage_account" "main" {
  name                            = "stunivolveprodassets"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
  tags                            = var.tags
}

resource "azurerm_storage_container" "avatars" {
  name                  = "avatars"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "blob"
}

# Create this private endpoint before the Key Vault one (step 9) — Azure serializes network
# operations on a shared subnet, so doing two at once can transiently fail.
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["blob"].id]
  }
}
