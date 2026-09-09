# Section 11 — Azure Communication Services + Email (application status/invite notifications)
resource "azurerm_communication_service" "main" {
  name                = "acs-${var.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  data_location       = var.acs_data_location
  tags                = var.tags
}

resource "azurerm_email_communication_service" "main" {
  name                = "email-${var.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  data_location       = var.acs_data_location
  tags                = var.tags
}

resource "azurerm_email_communication_service_domain" "managed" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.main.id
  domain_management = "AzureManaged"
}

resource "azurerm_communication_service_email_domain_association" "main" {
  communication_service_id = azurerm_communication_service.main.id
  email_service_domain_id  = azurerm_email_communication_service_domain.managed.id
}
