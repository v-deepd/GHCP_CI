# Phase 5: Azure Deployment Guide
## ASP.NET Framework 3.0 to Azure App Service Migration

**Date**: December 3, 2025
**Status**: Ready for Deployment
**Estimated Time**: 2-3 hours

---

##  Pre-Deployment Checklist

###  Prerequisites Verified

- [x] **Terraform v1.14.0** - Installed and verified
- [x] **Azure CLI v2.67.0** - Installed and authenticated
- [x] **Azure Developer CLI v1.21.3** - Installed and verified
- [x] **Azure Account** - Logged in as v-deepd@microsoft.com
- [x] **Subscription** - ODSP EFun Dev Resources (a471d615-ff98-4e80-b375-a19543d4691e)
- [x] **Tenant ID** - 72f988bf-86f1-41af-91ab-2d7cd011db47
- [x] **terraform.tfvars** - Created with user configuration
- [x] **Infrastructure Files** - Validated and production-ready
- [x] **Project Files** - Fixed and build-ready

---

##  Deployment Steps

### Step 1: Open Fresh PowerShell Terminal

Open a **NEW** PowerShell terminal as Administrator to avoid session issues.

\```powershell
# Navigate to the project directory
cd 'c:\Code repo\MSDemo\GHCP-PromptMigration-main\GHCP_CI\Use-cases\02-NetFramework30-ASPNET-WEB\NetFramework48-Modernized-AzureReady'
\```

### Step 2: Verify Azure Authentication

\```powershell
# Verify Azure CLI login
az account show --output table

# Expected output: Should show your account (v-deepd@microsoft.com)
# If not logged in, run: az login
\```

### Step 3: Initialize Terraform

\```powershell
# Navigate to infrastructure folder
cd infra

# Initialize Terraform (downloads providers)
terraform init

# Expected output: 
# - Initializing the backend...
# - Initializing provider plugins...
# - Terraform has been successfully initialized!
\```

**Note**: This step may take 2-3 minutes to download Azure providers.

### Step 4: Validate Terraform Configuration

\```powershell
# Validate the configuration syntax
terraform validate

# Expected output: Success! The configuration is valid.
\```

### Step 5: Review Deployment Plan

\```powershell
# Generate and review the deployment plan
terraform plan -out=tfplan

# This will show:
# - 8+ resources to be created
# - Resource Group, App Service Plan, Web App, SQL Server, SQL Database
# - Key Vault, Application Insights, Log Analytics Workspace
\```

**Review the plan carefully** to ensure:
- Resource names are correct
- Region is East US
- SKUs match your requirements (B1 for App Service, Basic for SQL)
- No unexpected changes or deletions

### Step 6: Deploy Infrastructure

\```powershell
# Apply the Terraform plan
terraform apply tfplan

# This will take approximately 5-10 minutes
# Azure resources being created:
# 1. Resource Group
# 2. App Service Plan
# 3. Windows Web App
# 4. SQL Server
# 5. SQL Database
# 6. Key Vault
# 7. Application Insights
# 8. Log Analytics Workspace
\```

**Expected Duration**: 5-10 minutes

**What happens during this step**:
- Azure resources are provisioned
- Managed Identity is created for the App Service
- Key Vault access policies are configured
- SQL Server with Azure AD authentication is set up

### Step 7: Capture Terraform Outputs

\```powershell
# Save outputs to a file for reference
terraform output > ../deployment-outputs.txt

# View key outputs
terraform output app_service_url
terraform output sql_server_fqdn
terraform output key_vault_uri
\```

**Save these values** - you'll need them for configuration and testing.

### Step 8: Build Application for Deployment

\```powershell
# Navigate back to project root
cd ..

# Build the application
msbuild NetFramework30ASPNETWEB.csproj /p:Configuration=Release /p:DeployOnBuild=true /p:PublishProfile=FolderProfile

# Or use the build script
.\build.ps1
\```

### Step 9: Create Deployment Package

\```powershell
# Create a zip package for deployment
 = "bin\Release\Publish"
 = "deployment-package.zip"

if (Test-Path $publishFolder) {
    Compress-Archive -Path "$publishFolder\*" -DestinationPath $zipFile -Force
    Write-Host "Deployment package created: $zipFile" -ForegroundColor Green
} else {
    Write-Host "ERROR: Publish folder not found. Run build first." -ForegroundColor Red
}
\```

### Step 10: Deploy Application to App Service

\```powershell
# Get the App Service name from Terraform output
$appName = terraform output -raw app_service_name -state=infra\terraform.tfstate
$rgName = terraform output -raw resource_group_name -state=infra\terraform.tfstate

# Deploy using Azure CLI
az webapp deployment source config-zip 
    --name $appName 
    --resource-group $rgName 
    --src deployment-package.zip

# Expected output: Deployment completed successfully
\```

**Expected Duration**: 2-5 minutes

### Step 11: Configure Application Settings

\```powershell
# Get Application Insights key
$aiKey = terraform output -raw application_insights_instrumentation_key -state=infra\terraform.tfstate

# Configure App Settings
az webapp config appsettings set 
    --name $appName 
    --resource-group $rgName 
    --settings 
        APPINSIGHTS_INSTRUMENTATIONKEY=$aiKey 
        APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$aiKey" 
        ApplicationInsights:InstrumentationKey=$aiKey

Write-Host "Application settings configured successfully" -ForegroundColor Green
\```

---

##  Step 12: Configure Azure AD Authentication (Easy Auth)

This is a **manual step** that must be completed in the Azure Portal.

### 12.1 Navigate to App Service

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **Resource Groups**  Find your resource group (aspnet-migration-dev-XXXX)
3. Click on the **App Service** (aspnet-migration-dev-app-XXXX)

### 12.2 Enable Authentication

1. In the left menu, click **Authentication**
2. Click **Add identity provider**
3. Select **Microsoft** as the identity provider

### 12.3 Configure App Registration

**Option A: Create New Registration (Recommended)**
- App registration type: **Create new app registration**
- Name: spnet-migration-dev-auth
- Supported account types: **Current tenant - Single tenant**

**Option B: Use Existing Registration**
- Select existing app registration if you have one

### 12.4 Authentication Settings

- **Restrict access**:  Require authentication
- **Unauthenticated requests**: Redirect to identity provider (HTTP 302)
- **Token store**:  Enabled

Click **Add** to complete the configuration.

### 12.5 Configure App Roles

1. Go to **Microsoft Entra ID** (Azure Active Directory)
2. Click **App registrations**  Find your app
3. Click **App roles**  **Create app role**

**Create Role 1: SecureAppUsers**
- Display name: SecureAppUsers
- Allowed member types: Users/Groups
- Value: SecureAppUsers
- Description: Users who can access the secure pages

**Create Role 2: AppAdministrators**
- Display name: AppAdministrators
- Allowed member types: Users/Groups
- Value: AppAdministrators
- Description: Application administrators

### 12.6 Assign Users to Roles

1. Go back to **Enterprise applications**
2. Find your app  Click **Users and groups**
3. Click **Add user/group**
4. Select users and assign to appropriate roles

---

##  Step 13: Verify Deployment

### 13.1 Check Application URL

\```powershell
# Get the application URL
$appUrl = terraform output -raw app_service_url -state=infra\terraform.tfstate
Write-Host "Application URL: $appUrl" -ForegroundColor Cyan
Start-Process $appUrl
\```

### 13.2 Test Pages

Test each page in your browser:
-  **Default.aspx** - Home page (should redirect to login)
-  **About.aspx** - About page (should be accessible after login)
-  **Secure.aspx** - Secure page (requires SecureAppUsers role)
-  **AccessDenied.aspx** - Access denied page (if role not assigned)

### 13.3 Verify Authentication Flow

1. Access the application URL
2. Should redirect to Microsoft login page
3. Sign in with your Microsoft account
4. Should redirect back to application
5. Verify your identity is recognized

### 13.4 Check Application Insights

\```powershell
# Open Application Insights in Azure Portal
$aiName = terraform output -raw application_insights_name -state=infra\terraform.tfstate
Write-Host "Application Insights: $aiName" -ForegroundColor Cyan

# View live metrics
Write-Host "Check Live Metrics Stream in Azure Portal" -ForegroundColor Yellow
\```

### 13.5 Check Application Logs

\```powershell
# Stream application logs
az webapp log tail 
    --name $appName 
    --resource-group $rgName

# Or download logs
az webapp log download 
    --name $appName 
    --resource-group $rgName 
    --log-file app-logs.zip
\```

---

##  Troubleshooting

### Issue: Terraform Init Fails

**Solution**:
\```powershell
# Clear Terraform cache
Remove-Item -Recurse -Force .terraform
Remove-Item -Force .terraform.lock.hcl

# Re-initialize
terraform init
\```

### Issue: Authentication Not Working

**Checklist**:
- [ ] Easy Auth is enabled in Azure Portal
- [ ] App registration is created
- [ ] Redirect URIs are configured correctly
- [ ] Users are assigned to app roles
- [ ] Token store is enabled

### Issue: Application Shows 500 Error

**Steps**:
1. Enable detailed errors in Web.config temporarily
2. Check Application Insights for exceptions
3. Stream application logs: z webapp log tail
4. Verify Application Insights connection string

### Issue: SQL Database Connection Fails

**Steps**:
1. Verify firewall rules allow Azure services
2. Check connection string in Key Vault
3. Verify Managed Identity has SQL permissions
4. Test connection from App Service Kudu console

### Issue: Deployment Package Upload Fails

**Solution**:
\```powershell
# Try deploying from a local folder
az webapp deployment source config-local-git 
    --name $appName 
    --resource-group $rgName

# Then use git deployment or FTP
\```

---

##  Post-Deployment Validation Checklist

- [ ] Application loads successfully
- [ ] Authentication redirects to Microsoft login
- [ ] Users can sign in with Microsoft accounts
- [ ] Role-based authorization works (Secure.aspx)
- [ ] Application Insights receives telemetry
- [ ] Custom events are tracked
- [ ] SQL Database connection works (if configured)
- [ ] Key Vault integration works
- [ ] HTTPS enforced (http redirects to https)
- [ ] Application logs are accessible
- [ ] Performance is acceptable (< 2 second load time)

---

##  Cost Monitoring

### Expected Monthly Costs (Development Environment)

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| App Service Plan | B1 (Basic) | ~$13-15/month |
| SQL Database | Basic | ~$5/month |
| Key Vault | Standard | ~$0.03/10k operations |
| Application Insights | Pay-as-you-go | ~$2-3/GB |
| Log Analytics | Pay-as-you-go | ~$2-3/GB |
| **Total** | | **~$68-86/month** |

### Cost Optimization Tips

1. **Stop App Service when not in use** (dev environments)
2. **Use auto-pause for SQL Database** (serverless tier)
3. **Monitor Application Insights ingestion** (set daily cap)
4. **Review and clean up unused resources** monthly
5. **Use Azure Cost Management** for tracking and alerts

---

##  Security Best Practices

### Completed Security Configurations

-  **HTTPS Only** - HTTP traffic redirected
-  **TLS 1.2 Minimum** - Older protocols disabled
-  **Managed Identity** - No credentials in code
-  **Key Vault** - Secrets stored securely
-  **Azure AD Auth** - Integrated authentication
-  **SQL Azure AD Admin** - Azure AD database access
-  **FTP Disabled** - Only FTPS allowed
-  **Soft Delete** - Key Vault data recovery enabled

### Recommended Additional Steps

1. **Enable WAF** (Web Application Firewall) for production
2. **Configure custom domains** with SSL certificates
3. **Set up backup policies** for App Service
4. **Enable diagnostic logs** for audit trails
5. **Configure monitoring alerts** for errors and performance
6. **Implement IP restrictions** if needed
7. **Review and rotate secrets** regularly
8. **Enable Azure Defender** for additional security

---

##  Monitoring and Alerts

### Application Insights Metrics to Monitor

1. **Availability** - Set up availability tests
2. **Response Time** - Alert if > 2 seconds
3. **Failed Requests** - Alert on 5xx errors
4. **Exceptions** - Alert on unhandled exceptions
5. **Dependency Failures** - Database or external API issues

### Recommended Alerts

\```powershell
# Create alert for failed requests
az monitor metrics alert create 
    --name "High-Failed-Requests" 
    --resource-group $rgName 
    --scopes $appServiceId 
    --condition "avg Http5xx > 5" 
    --window-size 5m 
    --evaluation-frequency 1m 
    --action-group-ids $actionGroupId
\```

---

##  Next Steps

### Immediate (Today)
1.  Complete deployment verification
2.  Test all application pages
3.  Verify authentication and authorization
4.  Check Application Insights telemetry

### Short-term (This Week)
1.  Set up monitoring alerts
2.  Configure custom domain (if needed)
3.  Create deployment documentation
4.  Train team on Azure Portal navigation

### Medium-term (Next 2 Weeks)
1.  **Set up CI/CD Pipeline** - Run /phase6-setupcicd
2.  Implement automated testing
3.  Create staging environment
4.  Document operational procedures

### Long-term (1-3 Months)
1.  Optimize performance based on metrics
2.  Review and optimize costs
3.  Implement disaster recovery plan
4.  Consider modernization to .NET 8 (optional)

---

##  Support and Resources

### Azure Documentation
- [App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure SQL Database](https://docs.microsoft.com/azure/sql-database/)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AD Authentication](https://docs.microsoft.com/azure/app-service/configure-authentication-provider-aad)

### Terraform Resources
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

### Project Files
- Infrastructure: infra/ folder
- Reports: eports/ folder
- Status: eports/Report-Status.md
- Assessment: eports/Application-Assessment-Report.md

---

##  Success Criteria

Phase 5 is complete when:
-  Infrastructure deployed successfully to Azure
-  Application accessible via HTTPS URL
-  Authentication working with Azure AD
-  Role-based authorization functioning
-  Application Insights collecting telemetry
-  No critical errors in logs
-  Performance meets requirements (< 2s load time)
-  Security configurations verified
-  Documentation updated

---

**Deployment Guide Version**: 1.0
**Last Updated**: December 3, 2025
**Next Phase**: Phase 6 - CI/CD Pipeline Setup (/phase6-setupcicd)

---

*Generated by GitHub Copilot Migration Assistant*
