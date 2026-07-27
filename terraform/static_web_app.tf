# ---------- Azure Static Web Apps (two portals, CI/CD via GitHub Actions) ----------

resource "azurerm_static_web_app" "admin_frontend" {
  name                = "swa-admin-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastasia"
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = local.tags
}

resource "azurerm_static_web_app" "volunteer_frontend" {
  name                = "swa-volunteer-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastasia"
  sku_tier            = "Standard"
  sku_size            = "Standard"
  tags                = local.tags
}
