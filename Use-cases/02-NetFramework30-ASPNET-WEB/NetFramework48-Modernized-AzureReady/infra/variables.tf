# ==============================================================================
# Terraform Variables for ASP.NET Framework Migration to Azure
# ==============================================================================

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "aspnet-migration"

  validation {
    condition     = length(var.resource_prefix) <= 20
    error_message = "Resource prefix must be 20 characters or less."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "app_service_sku" {
  description = "SKU for App Service Plan"
  type        = string
  default     = "B1" # Basic tier - suitable for development/small workloads

  validation {
    condition     = can(regex("^(B1|B2|B3|S1|S2|S3|P1v2|P2v2|P3v2)$", var.app_service_sku))
    error_message = "App Service SKU must be a valid Windows plan SKU."
  }
}

variable "sql_sku" {
  description = "SKU for SQL Database"
  type        = string
  default     = "Basic" # Basic tier - 5 DTUs, suitable for development

  validation {
    condition     = can(regex("^(Basic|S0|S1|S2|S3|P1|P2|P4)$", var.sql_sku))
    error_message = "SQL SKU must be a valid Azure SQL Database SKU."
  }
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_username) >= 4
    error_message = "SQL admin username must be at least 4 characters."
  }
}

variable "sql_admin_password" {
  description = "SQL Server administrator password (use Azure Key Vault in production)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.sql_admin_password) >= 8
    error_message = "SQL admin password must be at least 8 characters."
  }
}

variable "sql_aad_admin_login" {
  description = "Azure AD admin login for SQL Server"
  type        = string
  default     = ""
}

variable "sql_aad_admin_object_id" {
  description = "Azure AD admin object ID for SQL Server"
  type        = string
  default     = ""
}

variable "azure_ad_tenant_id" {
  description = "Azure AD tenant ID for authentication"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "ASP.NET Migration"
    Environment = "Development"
    ManagedBy   = "Terraform"
    CostCenter  = "IT"
  }
}