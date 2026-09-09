# Section 7 — Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acrunivolveprod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Premium" # required for private endpoints
  admin_enabled       = false     # backend authenticates via managed identity
  tags                = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdz-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.zones["acr"].id]
  }
}
