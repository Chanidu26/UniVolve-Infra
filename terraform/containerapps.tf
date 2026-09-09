# Section 12 — Log Analytics + Container Apps Environment
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_app_environment" "main" {
  name                           = "cae-${var.prefix}"
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id       = azurerm_subnet.aca.id
  internal_load_balancer_enabled = true # APIM is the only public entry point, not this
  tags                           = var.tags
}

# Section 13 — Managed Identity + role assignments
resource "azurerm_user_assigned_identity" "backend" {
  name                = "id-backend-${var.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_role_assignment" "backend_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

resource "azurerm_role_assignment" "backend_kv_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

# Section 14 — Key Vault secrets (the Container App below references these)
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin_current_user]
}

resource "azurerm_key_vault_secret" "acs_connection_string" {
  name         = "acs-connection-string"
  value        = azurerm_communication_service.main.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin_current_user]
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.main.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin_current_user]
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-secret"
  value        = var.jwt_secret
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin_current_user]
}

resource "azurerm_key_vault_secret" "db_schema" {
  name         = "db-schema"
  value        = file("${path.module}/schema.sql")
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_admin_current_user]
}

# Section 15 — Container App (backend)
resource "azurerm_container_app" "backend" {
  name                         = "ca-backend-${var.prefix}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.backend.id
  }

  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.db_password.versionless_id
    identity            = azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "acs-connection"
    key_vault_secret_id = azurerm_key_vault_secret.acs_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "storage-connection"
    key_vault_secret_id = azurerm_key_vault_secret.storage_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.backend.id
  }
  secret {
    name                = "jwt-secret"
    key_vault_secret_id = azurerm_key_vault_secret.jwt_secret.versionless_id
    identity            = azurerm_user_assigned_identity.backend.id
  }

  template {
    min_replicas = 1
    max_replicas = 5

    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }
      env {
        name  = "DB_USER"
        value = var.db_admin_username
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
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
        value = "DoNotReply@${azurerm_email_communication_service_domain.managed.mail_from_sender_domain}"
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
        value = azurerm_key_vault.main.vault_uri
      }
      env {
        name        = "JWT_SECRET"
        secret_name = "jwt-secret"
      }
      env {
        name  = "GOOGLE_CLIENT_ID"
        value = var.google_client_id
      }
      env {
        name  = "SUPER_ADMIN_EMAILS"
        value = var.super_admin_emails
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/health"
        port      = 4000
      }
    }

    http_scale_rule {
      name                = "http-scale"
      concurrent_requests = 50
    }
  }

  ingress {
    external_enabled = false # APIM is the only public entry point
    target_port      = 4000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
