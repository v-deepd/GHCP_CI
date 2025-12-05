# ==============================================================================
# Azure Infrastructure for ASP.NET Framework 3.0 to 4.8 Migration
# ==============================================================================
# This Terraform configuration deploys:
# - Azure App Service (Windows) for .NET Framework 4.8
# - Azure SQL Database for future data needs
# - Azure Key Vault for secrets management
# - Application Insights for monitoring
# - All resources use Managed Identity for secure access
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false # Security best practice
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Get current client configuration for Key Vault access
data "azurerm_client_config" "current" {}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ==============================================================================
# Resource Group
# ==============================================================================
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_prefix}-rg"
  location = var.location

  tags = var.tags
}

# ==============================================================================
# Application Insights (Deploy first for App Service dependency)
# ==============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_prefix}-law-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.resource_prefix}-ai-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# ==============================================================================
# App Service Plan (Windows for .NET Framework)
# ==============================================================================
resource "azurerm_service_plan" "main" {
  name                = "${var.resource_prefix}-asp-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Windows"
  sku_name            = var.app_service_sku

  tags = var.tags
}

# ==============================================================================
# App Service (Windows Web App for .NET Framework 4.8)
# ==============================================================================
resource "azurerm_windows_web_app" "main" {
  name                = "${var.resource_prefix}-app-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  # Enable System-Assigned Managed Identity for Azure service access
  identity {
    type = "SystemAssigned"
  }

  site_config {
    # .NET Framework 4.8 runtime
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v4.0" # v4.0 supports .NET Framework 4.8
    }

    # Always On for production workloads
    always_on = var.environment == "production" ? true : false

    # HTTP/2 support
    http2_enabled = true

    # Minimum TLS version
    minimum_tls_version = "1.2"

    # Health check path
    health_check_path = "/Default.aspx"

    # FTP disabled for security
    ftps_state = "Disabled"
  }

  # Application Settings
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    
    # Azure AD configuration (configure these in Azure Portal or override)
    "WEBSITE_AUTH_AAD_ALLOWED_TENANTS" = var.azure_ad_tenant_id
    
    # Authorized roles for Secure.aspx
    "AuthorizedRoles" = "SecureAppUsers,AppAdministrators"
    
    # Environment
    "ASPNETCORE_ENVIRONMENT" = var.environment
  }

  # Connection strings (will reference Key Vault)
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection.id})"
  }

  # HTTPS only
  https_only = true

  # Client certificate mode
  client_certificate_mode = "Optional"

  tags = var.tags

  # Ensure App Insights is created first
  depends_on = [
    azurerm_application_insights.main
  ]
}

# ==============================================================================
# Azure SQL Server and Database
# ==============================================================================
resource "azurerm_mssql_server" "main" {
  name                         = "${var.resource_prefix}-sql-${random_string.suffix.result}"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password # Use Key Vault in production
  minimum_tls_version          = "1.2"

  # Azure AD authentication (recommended)
  azuread_administrator {
    login_username = var.sql_aad_admin_login
    object_id      = var.sql_aad_admin_object_id
  }

  tags = var.tags
}

# Allow Azure services to access SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "${var.resource_prefix}-sqldb"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = var.sql_sku
  max_size_gb    = 2
  zone_redundant = false

  # Backup retention
  short_term_retention_policy {
    retention_days = 7
  }

  tags = var.tags
}

# ==============================================================================
# Key Vault for Secrets Management
# ==============================================================================
resource "azurerm_key_vault" "main" {
  name                       = "${var.resource_prefix}-kv-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true # Security best practice

  # Network ACLs
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # Change to "Deny" in production with specific IP rules
  }

  tags = var.tags
}

# Access policy for current user/service principal (for initial setup)
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# Access policy for App Service Managed Identity
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = azurerm_windows_web_app.main.identity[0].tenant_id
  object_id    = azurerm_windows_web_app.main.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]

  depends_on = [
    azurerm_key_vault_access_policy.terraform
  ]
}

# Store SQL connection string in Key Vault
resource "azurerm_key_vault_secret" "sql_connection" {
  name         = "SqlConnectionString"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform
  ]
}

# Store Application Insights Instrumentation Key
resource "azurerm_key_vault_secret" "app_insights_key" {
  name         = "AppInsightsInstrumentationKey"
  value        = azurerm_application_insights.main.instrumentation_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform
  ]
}

# ==============================================================================
# Outputs
# ==============================================================================
# See outputs.tf for all output values