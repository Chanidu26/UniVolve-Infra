# Section 1 — Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}"
  location = var.location
  tags     = var.tags
}

