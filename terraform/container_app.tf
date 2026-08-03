resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Same class of issue as the APIM/subnet wait below: Azure can report the Container
# App Environment as deleted before its managed infrastructure is fully reconciled,
# which then blocks unregistering the Microsoft.App provider. Force a wait between
# the two on destroy. No effect on create.
resource "time_sleep" "wait_for_container_app_cleanup" {
  depends_on       = [azurerm_resource_provider_registration.app]
  destroy_duration = "10m"
}

resource "azurerm_container_app_environment" "env" {
  name                           = "cae-${local.name}"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = azurerm_resource_group.rg.location
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  infrastructure_subnet_id       = azurerm_subnet.aca.id
  internal_load_balancer_enabled = true
  tags                           = local.tags
  depends_on                     = [time_sleep.wait_for_container_app_cleanup]
}

resource "azurerm_user_assigned_identity" "backend" {
  name                = "id-backend-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

# RBAC role assignments complete at the ARM control-plane level well before the
# actual authorization grant propagates through Azure's data plane. Without this
# wait, the Container App can start provisioning (and try to pull the ACR image /
# resolve Key Vault secret references via the managed identity) before the grants
# are actually effective, failing with "Unable to get value using Managed identity".
resource "time_sleep" "wait_for_backend_rbac_propagation" {
  depends_on      = [azurerm_role_assignment.acr_pull, azurerm_role_assignment.kv_secrets_user]
  create_duration = "90s"
}

resource "azurerm_container_app" "backend" {
  name                         = "ca-backend-${local.name}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.tags
  depends_on                   = [time_sleep.wait_for_backend_rbac_propagation]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.backend.id
  }

  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.db_password.id
    identity            = azurerm_user_assigned_identity.backend.id
  }

  secret {
    name                = "acs-connection"
    key_vault_secret_id = azurerm_key_vault_secret.acs_connection.id
    identity            = azurerm_user_assigned_identity.backend.id
  }

  secret {
    name                = "storage-connection"
    key_vault_secret_id = azurerm_key_vault_secret.storage_connection.id
    identity            = azurerm_user_assigned_identity.backend.id
  }

  ingress {
    external_enabled = false
    target_port      = 4000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 5

    container {
      name   = "backend"
      image  = var.backend_image != "" ? var.backend_image : "${azurerm_container_registry.acr.login_server}/vms-backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.pg.fqdn
      }
      env {
        name  = "DB_USER"
        value = var.db_admin_user
      }
      env {
        name  = "DB_NAME"
        value = "vmsdb"
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
      env {
        name        = "ACS_CONNECTION_STRING"
        secret_name = "acs-connection"
      }
      env {
        name  = "ACS_SENDER"
        value = "DoNotReply@${azurerm_email_communication_service_domain.domain.from_sender_domain}"
      }
      env {
        name        = "STORAGE_CONNECTION_STRING"
        secret_name = "storage-connection"
      }
      env {
        name  = "STORAGE_CONTAINER"
        value = "avatars"
      }
      env {
        name  = "KEY_VAULT_URI"
        value = azurerm_key_vault.kv.vault_uri
      }
      env {
        name  = "TENANT_NAME"
        value = var.tenant_name
      }
      env {
        name  = "TENANT_ID"
        value = var.tenant_id
      }
      env {
        name  = "API_CLIENT_ID"
        value = var.api_client_id
      }
      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 4000
      }
    }

    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = 50
    }
  }
}
