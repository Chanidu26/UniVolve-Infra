# Section 18 — API Management (public front door; VNet-injected, external mode)
resource "azurerm_api_management" "main" {
  name                 = "apim-${var.prefix}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  publisher_name       = var.apim_publisher_name
  publisher_email      = var.apim_publisher_email
  sku_name             = "Developer_1"
  virtual_network_type = "External"
  tags                 = var.tags

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.apim]
}

resource "azurerm_api_management_api" "backend" {
  name                = "univolve-api"
  resource_group_name = azurerm_resource_group.main.name
  api_management_name = azurerm_api_management.main.name
  revision            = "1"
  display_name        = "univolve-api"
  path                = "api"
  protocols           = ["https"]
  service_url         = "https://${azurerm_container_app.backend.ingress[0].fqdn}/api"
}

# Wildcard operation so all routes/methods pass through to the backend
resource "azurerm_api_management_api_operation" "all" {
  operation_id        = "all-operations"
  api_name            = azurerm_api_management_api.backend.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "All operations"
  method              = "*"
  url_template        = "/*"
}

# Backend does its own session-JWT verification now (Google Sign-In → our own JWT), so this
# policy only needs CORS + rate-limiting — no validate-jwt against a third-party IdP anymore.
resource "azurerm_api_management_api_policy" "backend" {
  api_name            = azurerm_api_management_api.backend.name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = azurerm_resource_group.main.name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <cors allow-credentials="false">
      <allowed-origins><origin>*</origin></allowed-origins>
      <allowed-methods><method>*</method></allowed-methods>
      <allowed-headers><header>*</header></allowed-headers>
    </cors>
    <rate-limit calls="100" renewal-period="60" />
  </inbound>
  <backend><base /></backend>
  <outbound><base /></outbound>
  <on-error><base /></on-error>
</policies>
XML
}
