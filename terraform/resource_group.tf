# Section 1 — Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}"
  location = var.location
  tags     = var.tags
}

# Section 2 — Register resource providers (fresh subscriptions sometimes aren't registered for these)
resource "azurerm_resource_provider_registration" "app" {
  name = "Microsoft.App"
}

resource "azurerm_resource_provider_registration" "communication" {
  name = "Microsoft.Communication"
}
