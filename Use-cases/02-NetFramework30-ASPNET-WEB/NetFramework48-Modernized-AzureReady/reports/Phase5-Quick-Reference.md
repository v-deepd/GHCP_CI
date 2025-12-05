# Phase 5 Deployment - Quick Reference

##  You Are Here
**Phase 5: Deploy to Azure (85% Complete)**

##  Prerequisites Status
-  Terraform v1.14.0 installed
-  Azure CLI authenticated (v-deepd@microsoft.com)
-  terraform.tfvars configured
-  All project files fixed

##  Quick Start Commands

### 1. Navigate to Project
\```powershell
cd 'c:\Code repo\MSDemo\GHCP-PromptMigration-main\GHCP_CI\Use-cases\02-NetFramework30-ASPNET-WEB\NetFramework48-Modernized-AzureReady'
\```

### 2. Deploy Infrastructure
\```powershell
cd infra
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output > ../deployment-outputs.txt
cd ..
\```

### 3. Build & Deploy Application
\```powershell
# Build
msbuild NetFramework30ASPNETWEB.csproj /p:Configuration=Release /p:DeployOnBuild=true /p:PublishProfile=FolderProfile

# Create package
$publishFolder = "bin\Release\Publish"
$zipFile = "deployment-package.zip"
Compress-Archive -Path "$publishFolder\*" -DestinationPath $zipFile -Force

# Deploy
$appName = terraform output -raw app_service_name -state=infra\terraform.tfstate
$rgName = terraform output -raw resource_group_name -state=infra\terraform.tfstate
az webapp deployment source config-zip --name $appName --resource-group $rgName --src deployment-package.zip
\```

### 4. Configure App Settings
\```powershell
$aiKey = terraform output -raw application_insights_instrumentation_key -state=infra\terraform.tfstate
az webapp config appsettings set --name $appName --resource-group $rgName --settings APPINSIGHTS_INSTRUMENTATIONKEY=$aiKey APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$aiKey"
\```

##  Manual Step: Azure AD Authentication

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your App Service
3. Click **Authentication**  **Add identity provider**
4. Select **Microsoft**
5. Create new app registration: spnet-migration-dev-auth
6. Configure roles in Azure AD:
   - SecureAppUsers
   - AppAdministrators
7. Assign users to roles

##  Verify Deployment
\```powershell
$appUrl = terraform output -raw app_service_url -state=infra\terraform.tfstate
Start-Process $appUrl
\```

##  Full Documentation
- **Deployment Guide**: reports/Phase5-Deployment-Guide.md
- **Status Report**: reports/Report-Status.md

##  Cost Estimate
~$68-86/month (development tier)

##  Time Estimate
2-3 hours total

##  Troubleshooting
If terraform init fails:
\```powershell
Remove-Item -Recurse -Force .terraform
Remove-Item -Force .terraform.lock.hcl
terraform init
\```

##  Next Phase
After deployment complete: /phase6-setupcicd

---
*Quick Reference v1.0 | December 3, 2025*
