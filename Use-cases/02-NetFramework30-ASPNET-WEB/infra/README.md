# Azure Infrastructure - Terraform Configuration

This directory contains Terraform configuration for deploying the ASP.NET Framework application to Azure App Service.

## 📋 Prerequisites

1. **Azure Subscription** with Contributor access
2. **Terraform** installed (>= 1.0)
   ```powershell
   winget install Hashicorp.Terraform
   ```
3. **Azure CLI** installed and authenticated
   ```powershell
   winget install Microsoft.AzureCLI
   az login
   ```

## 🏗️ Infrastructure Components

This configuration deploys:

| Resource | Purpose | SKU/Tier |
|----------|---------|----------|
| **Resource Group** | Container for all resources | N/A |
| **App Service Plan** | Hosting plan for web app | B1 (Basic) |
| **App Service** | Windows web app for .NET Framework 4.8 | Windows |
| **Azure SQL Database** | Relational database | Basic (5 DTUs) |
| **Key Vault** | Secrets management | Standard |
| **Application Insights** | Monitoring and diagnostics | Pay-as-you-go |
| **Log Analytics** | Centralized logging | PerGB2018 |

## 🚀 Deployment Steps

### Step 1: Configure Variables

```powershell
# Copy the example file
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
notepad terraform.tfvars
```

**Required variables**:
- `sql_admin_password` - Strong password for SQL Server
- `azure_ad_tenant_id` - Your Azure AD tenant ID
- `sql_aad_admin_login` - Azure AD admin email
- `sql_aad_admin_object_id` - Azure AD admin object ID

### Step 2: Initialize Terraform

```powershell
cd infra
terraform init
```

This downloads the required providers (Azure RM).

### Step 3: Validate Configuration

```powershell
terraform validate
```

Checks for syntax errors and configuration issues.

### Step 4: Preview Changes

```powershell
terraform plan
```

Review the resources that will be created.

### Step 5: Deploy Infrastructure

```powershell
terraform apply
```

Type `yes` when prompted. Deployment takes ~5-10 minutes.

### Step 6: View Outputs

```powershell
terraform output
```

Save important values:
- `app_service_url` - Your application URL
- `app_service_name` - App Service name for deployment
- `key_vault_name` - Key Vault for secrets

## 🔒 Security Configuration

### 1. Configure Azure AD Authentication (Easy Auth)

After deployment, configure authentication in Azure Portal:

1. Go to **Azure Portal** → **App Services** → **[Your App]** → **Authentication**
2. Click **Add identity provider**
3. Select **Microsoft**
4. Choose **Create new app registration** or use existing
5. Set **Restrict access** to **Require authentication**
6. Configure **Token store**: Enabled
7. Click **Add**

### 2. Configure App Roles

In Azure AD app registration:

1. Go to **Azure Portal** → **Azure Active Directory** → **App registrations**
2. Find your app registration
3. Click **App roles** → **Create app role**
4. Create roles:
   - **SecureAppUsers** (User/Groups) - Access to secure pages
   - **AppAdministrators** (User/Groups) - Admin access
5. **Assign users/groups** to roles

### 3. Update Key Vault Access (if needed)

```powershell
# Grant your user account access to Key Vault
$keyVaultName = terraform output -raw key_vault_name
az keyvault set-policy --name $keyVaultName --upn your-email@domain.com --secret-permissions get list
```

## 📦 Application Deployment

### Option 1: Visual Studio Publish

1. Open project in Visual Studio
2. Right-click project → **Publish**
3. Choose **Azure** → **Azure App Service (Windows)**
4. Select your subscription and App Service
5. Click **Publish**

### Option 2: Azure CLI

```powershell
# Build the application
dotnet publish -c Release -o ./publish

# Create deployment package
Compress-Archive -Path ./publish/* -DestinationPath app.zip

# Deploy to App Service
$appName = terraform output -raw app_service_name
$rgName = terraform output -raw resource_group_name
az webapp deployment source config-zip --name $appName --resource-group $rgName --src app.zip
```

### Option 3: GitHub Actions (Recommended for CI/CD)

See `.github/workflows/` directory for deployment workflow.

## 🧪 Testing

After deployment, test your application:

1. **Home Page**: `https://[app-name].azurewebsites.net/Default.aspx`
2. **About Page**: `https://[app-name].azurewebsites.net/About.aspx`
3. **Secure Page**: `https://[app-name].azurewebsites.net/Secure.aspx` (requires authentication)

## 📊 Monitoring

### Application Insights

View real-time metrics:

```powershell
# Get Application Insights connection
$aiKey = terraform output -raw application_insights_instrumentation_key
Write-Host "Application Insights Key: $aiKey"
```

Go to **Azure Portal** → **Application Insights** → **[Your App Insights]**

### Log Stream

View live logs:

```powershell
$appName = terraform output -raw app_service_name
$rgName = terraform output -raw resource_group_name
az webapp log tail --name $appName --resource-group $rgName
```

## 💰 Cost Estimation

Monthly costs (approximate):

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| App Service Plan (B1) | Basic | ~$55/month |
| Azure SQL Database (Basic) | 5 DTU | ~$5/month |
| Key Vault | Standard | ~$0.50/month |
| Application Insights | Pay-as-you-go | ~$5-20/month |
| **Total** | | **~$65-80/month** |

## 🗑️ Cleanup

To delete all resources:

```powershell
terraform destroy
```

Type `yes` when prompted. This removes all Azure resources.

## 📝 Terraform Best Practices Applied

✅ **State Management**: Use remote state in production (Azure Storage)  
✅ **Variables**: Parameterized for different environments  
✅ **Secrets**: Stored in Key Vault, not in code  
✅ **Managed Identity**: App Service uses MI for Key Vault access  
✅ **Security**: Purge protection enabled, HTTPS enforced  
✅ **Monitoring**: Application Insights integrated  
✅ **Tags**: All resources tagged for cost tracking  

## 🔧 Troubleshooting

### Issue: Terraform authentication fails

```powershell
az login
az account show
```

### Issue: Key Vault access denied

```powershell
$keyVaultName = terraform output -raw key_vault_name
az keyvault set-policy --name $keyVaultName --upn $(az account show --query user.name -o tsv) --secret-permissions get list set
```

### Issue: SQL connection fails

Check firewall rules in Azure Portal → SQL Server → Firewalls and virtual networks

## 📚 Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Application Insights Documentation](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)

## 📞 Support

For issues or questions:
- Review the main [Application-Assessment-Report.md](../reports/Application-Assessment-Report.md)
- Check [Report-Status.md](../reports/Report-Status.md) for migration progress