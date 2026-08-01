terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" }
  }
}

provider "azurerm" {
  features {
    key_vault { purge_soft_delete_on_destroy = true }
  }
}

data "azurerm_client_config" "current" {}

locals {
  name          = "${var.project}-${var.environment}"
  unique_suffix = substr(replace(data.azurerm_client_config.current.subscription_id, "-", ""), 0, 6)
  tags          = { project = var.project, environment = var.environment, managed_by = "terraform" }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_provider_registration" "communication" {
  name = "Microsoft.Communication"
}

resource "azurerm_resource_provider_registration" "app" {
  name = "Microsoft.App"
}
