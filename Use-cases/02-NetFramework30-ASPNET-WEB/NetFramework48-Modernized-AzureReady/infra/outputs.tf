# ==============================================================================
# Terraform Outputs - Important information after deployment
# ==============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_windows_web_app.main.name
}

output "app_service_url" {
  description = "URL of the deployed application"
  value       = "https://${azurerm_windows_web_app.main.default_hostname}"
}

output "app_service_managed_identity_principal_id" {
  description = "Principal ID of the App Service Managed Identity"
  value       = azurerm_windows_web_app.main.identity[0].principal_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "sql_server_fqdn" {
  description = "Fully Qualified Domain Name of SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "deployment_instructions" {
  description = "Next steps for deployment"
  value       = <<-EOT
  
  ========================================
  DEPLOYMENT SUCCESSFUL!
  ========================================
  
  App Service URL: https://${azurerm_windows_web_app.main.default_hostname}
  Resource Group: ${azurerm_resource_group.main.name}
  
  NEXT STEPS:
  
  1. Configure Azure AD Authentication (Easy Auth):
     - Go to Azure Portal → App Service → Authentication
     - Add Microsoft identity provider
     - Configure app roles: SecureAppUsers, AppAdministrators
     - Assign users/groups to roles
  
  2. Deploy your application:
     - Via Visual Studio: Right-click project → Publish → Azure
     - Via Azure CLI: az webapp deployment source config-zip
     - Via GitHub Actions: Use provided workflow file
  
  3. Verify Application Insights:
     - Check: https://portal.azure.com → Application Insights
     - View live metrics and logs
  
  4. Test the application:
     - Home page: https://${azurerm_windows_web_app.main.default_hostname}/Default.aspx
     - Secure page: https://${azurerm_windows_web_app.main.default_hostname}/Secure.aspx
  
  5. View Azure Portal Resources:
     https://portal.azure.com/#resource/subscriptions/YOUR_SUB_ID/resourceGroups/${azurerm_resource_group.main.name}/overview
  
  ========================================
  EOT
}