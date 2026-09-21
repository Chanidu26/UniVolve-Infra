# Section 10 — PostgreSQL Flexible Server (VNet-integrated, private access only)
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "pg-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  version             = "16"

  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 32768

  administrator_login           = var.db_admin_username
  administrator_password        = var.db_admin_password
  public_network_access_enabled = false

  delegated_subnet_id = azurerm_subnet.db.id
  private_dns_zone_id = azurerm_private_dns_zone.zones["postgres"].id

  # Zone-redundant HA is commonly unavailable for this region/subscription combination —
  # leave disabled, per the manual guide's note.
  backup_retention_days = 7
  tags                  = var.tags

  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.zones]
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
