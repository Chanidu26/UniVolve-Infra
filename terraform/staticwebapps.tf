# Section 17 — Static Web Apps (two portals)
resource "azurerm_static_web_app" "admin" {
  name                = "swa-admin-${var.prefix}"
  location            = var.swa_location
  resource_group_name = azurerm_resource_group.main.name
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = var.tags
}

resource "azurerm_static_web_app" "volunteer" {
  name                = "swa-volunteer-${var.prefix}"
  location            = var.swa_location
  resource_group_name = azurerm_resource_group.main.name
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = var.tags
}
