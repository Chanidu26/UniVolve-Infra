# azure/terraform/storage.tf
resource "azurerm_storage_account" "assets" {
  name                     = replace("st${local.name}assets", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true   # needed for public blob read
  tags                     = local.tags
}

resource "azurerm_storage_container" "avatars" {
  name                  = "avatars"
  storage_account_id    = azurerm_storage_account.assets.id
  container_access_type = "blob"           # public read, private write
}