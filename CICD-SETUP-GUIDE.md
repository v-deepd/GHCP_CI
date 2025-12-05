# CI/CD Prerequisites Setup Guide

##  Completed Prerequisites

### 1. Azure Key Vault
- **Name**: kv-winmig-2695
- **Location**: Canada Central  
- **Resource Group**: rg-infra-winmig-eme-v-deepd-demo
- **Vault URI**: https://kv-winmig-2695.vault.azure.net/

### 2. GitHub Repository
- **Repository**: https://github.com/v-deepd/GHCP_CI.git
- **Branch**: main
- **Status**:  Connected

### 3. Infrastructure Code
- **Type**: Terraform
- **Location**: Use-cases/02-NetFramework30-ASPNET-WEB/infra/
- **Files**: main.tf, variables.tf, outputs.tf

### 4. GitHub Actions Workflow
- **File**: .github/workflows/deploy-dotnet-framework.yml
- **Status**:  Created
- **Triggers**: Push to main branch, Manual dispatch

---

##  Required Manual Steps

### Step 1: Create Service Principal

Run this command in PowerShell:

```powershell
az ad sp create-for-rbac --name "github-actions-winmig" `
  --role Contributor `
  --scopes "/subscriptions/95642268-5116-484d-9b88-7dfce8c20ce4/resourceGroups/rg-infra-winmig-eme-v-deepd-demo" `
  --json-auth
```

**Copy the entire JSON output!** You'll need it in the next step.

### Step 2: Add GitHub Repository Secret

1. Go to your GitHub repository: https://github.com/v-deepd/GHCP_CI
2. Navigate to: **Settings**  **Secrets and variables**  **Actions**
3. Click **"New repository secret"**
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the entire JSON output from Step 1
6. Click **"Add secret"**

### Step 3: Grant Key Vault Access to Service Principal

Get the Client ID from the JSON output in Step 1, then run:

```powershell
# Replace <CLIENT_ID> with the actual clientId from Step 1
$clientId = "<CLIENT_ID>"

az keyvault set-policy --name "kv-winmig-2695" `
  --spn $clientId `
  --secret-permissions get list
```

### Step 4: Store Secrets in Key Vault (Optional)

If you have database connection strings or other secrets:

```powershell
# Example: Store a connection string
az keyvault secret set --vault-name "kv-winmig-2695" `
  --name "DatabaseConnectionString" `
  --value "your-connection-string-here"
```

### Step 5: Test the CI/CD Pipeline

1. Make a small change to a file in `Use-cases/02-NetFramework30-ASPNET-WEB/`
2. Commit and push to the `main` branch:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. Go to GitHub  **Actions** tab to see the workflow running

---

##  CI/CD Workflow Overview

### Build Job (runs-on: windows-latest)
1.  Checkout code
2.  Setup MSBuild
3.  Setup NuGet  
4.  Restore NuGet packages
5.  Build .NET Framework solution (Release configuration)
6.  Upload build artifacts

### Deploy Job (runs-on: windows-latest, needs: build)
1.  Download build artifacts
2.  Login to Azure using AZURE_CREDENTIALS
3.  Deploy to Azure App Service: webapp-apps-winmig-emea-v-deepd-demo-web
4.  Logout from Azure

---

##  Security Best Practices

-  Service Principal has Contributor role scoped to resource group only
-  Secrets stored in Azure Key Vault
-  GitHub secrets used for Azure credentials
-  No credentials stored in code
-  Review and rotate Service Principal credentials periodically

---

##  Quick Reference

| Resource | Value |
|----------|-------|
| **Subscription ID** | 95642268-5116-484d-9b88-7dfce8c20ce4 |
| **Resource Group** | rg-infra-winmig-eme-v-deepd-demo |
| **App Service** | webapp-apps-winmig-emea-v-deepd-demo-web |
| **Key Vault** | kv-winmig-2695 |
| **GitHub Repo** | v-deepd/GHCP_CI |
| **Workflow File** | .github/workflows/deploy-dotnet-framework.yml |
| **App URL** | https://webapp-apps-winmig-emea-v-deepd-demo-web-aye7gxb4b4htb8fh.canadacentral-01.azurewebsites.net |

---

##  Next Steps

1. **Complete Step 1-3** above to configure GitHub Actions
2. **Test the pipeline** by making a commit
3. **Monitor the deployment** in GitHub Actions tab
4. **Verify** the application is running after deployment

---

##  Troubleshooting

### Build Fails
- Check NuGet package restore logs
- Verify .NET Framework 4.8 is available on runner
- Check MSBuild version compatibility

### Deployment Fails
- Verify AZURE_CREDENTIALS secret is set correctly
- Check Service Principal has correct permissions
- Verify App Service name is correct

### Authentication Errors
- Regenerate Service Principal credentials
- Update AZURE_CREDENTIALS in GitHub secrets
- Check Azure subscription is active

