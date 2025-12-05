# CI/CD Setup Guide - Federated Identity (OIDC) Method

## Overview
This guide explains how to set up GitHub Actions CI/CD using **Federated Identity (OIDC)** which is:
-  More secure (no secrets stored)
-  No Service Principal creation required
-  No Publish Profile download required
-  Uses Azure AD federated credentials

## Prerequisites
- Access to Azure Portal
- Permissions to create App Registrations in Azure AD
- Owner or User Access Administrator role on the resource group

---

## Setup Steps (To Request from Admin)

### Step 1: Create App Registration

Your Azure administrator needs to:

1. Go to Azure Portal  **Azure Active Directory**  **App registrations**
2. Click **"New registration"**
3. Configure:
   - Name: `github-actions-winmig-oidc`
   - Supported account types: **"Accounts in this organizational directory only"**
   - Redirect URI: Leave blank
4. Click **"Register"**
5. **Copy the following values** (you''ll need them):
   - Application (client) ID
   - Directory (tenant) ID

### Step 2: Configure Federated Identity Credential

Still in the App Registration:

1. Go to **"Certificates & secrets"**  **"Federated credentials"** tab
2. Click **"Add credential"**
3. Select **"GitHub Actions deploying Azure resources"**
4. Configure:
   - **Organization**: `v-deepd`
   - **Repository**: `GHCP_CI`
   - **Entity type**: `Branch`
   - **GitHub branch name**: `main`
   - **Credential name**: `github-actions-deploy`
5. Click **"Add"**

### Step 3: Assign Azure Role

The App Registration needs Contributor role on the resource group:

```powershell
# Replace <CLIENT_ID> with the Application (client) ID from Step 1
az role assignment create \
  --assignee <CLIENT_ID> \
  --role "Contributor" \
  --scope "/subscriptions/95642268-5116-484d-9b88-7dfce8c20ce4/resourceGroups/rg-infra-winmig-eme-v-deepd-demo"
```

**Or via Azure Portal:**
1. Go to Resource Group: **rg-infra-winmig-eme-v-deepd-demo**
2. Click **"Access control (IAM)"**  **"Add"**  **"Add role assignment"**
3. Role: **Contributor**
4. Assign access to: **User, group, or service principal**
5. Select: `github-actions-winmig-oidc`
6. Click **"Save"**

### Step 4: Grant Key Vault Access (Optional but Recommended)

If your deployment needs to access Key Vault secrets:

```powershell
# Replace <CLIENT_ID> with the Application (client) ID from Step 1
az keyvault set-policy \
  --name "kv-winmig-2695" \
  --spn <CLIENT_ID> \
  --secret-permissions get list
```

---

## Your Action (After Admin Completes Setup)

Once your admin provides the **Application (client) ID**, you need to update the workflow file:

1. Open: `.github/workflows/deploy-dotnet-framework.yml`
2. Find this line:
   ```yaml
   AZURE_CLIENT_ID: ''YOUR_APP_REGISTRATION_CLIENT_ID''
   ```
3. Replace `YOUR_APP_REGISTRATION_CLIENT_ID` with the actual client ID
4. Commit and push the change

**Example:**
```yaml
env:
  AZURE_WEBAPP_NAME: webapp-apps-winmig-emea-v-deepd-demo-web
  AZURE_WEBAPP_PACKAGE_PATH: ''Use-cases/02-NetFramework30-ASPNET-WEB''
  AZURE_CLIENT_ID: ''12345678-1234-1234-1234-123456789abc''  #  Replace this
  AZURE_TENANT_ID: ''0e478cd4-3e52-496d-ac3a-419ca58ba7ac''
  AZURE_SUBSCRIPTION_ID: ''95642268-5116-484d-9b88-7dfce8c20ce4''
```

---

## Email Template to Send to Admin

```
Subject: Request: Federated Identity Setup for GitHub Actions CI/CD

Hi [Admin Name],

I need help setting up federated identity (OIDC) for GitHub Actions CI/CD deployment. This is more secure than Service Principals as it doesn''t require managing secrets.

Could you please:

1. Create an App Registration:
   - Name: github-actions-winmig-oidc
   - Supported account types: This organization only

2. Add Federated Credential:
   - Credential type: GitHub Actions deploying Azure resources
   - Organization: v-deepd
   - Repository: GHCP_CI
   - Entity type: Branch
   - Branch name: main
   - Credential name: github-actions-deploy

3. Assign Role:
   - Role: Contributor
   - Scope: /subscriptions/95642268-5116-484d-9b88-7dfce8c20ce4/resourceGroups/rg-infra-winmig-eme-v-deepd-demo

4. Grant Key Vault Access:
   - Key Vault: kv-winmig-2695
   - Permissions: GET and LIST on secrets

Please provide me with the Application (client) ID from the App Registration.

Detailed guide: See CICD-SETUP-OIDC.md in the repository

Thank you!
```

---

## Advantages of OIDC Method

 **No Secrets**: No client secrets or passwords to manage
 **More Secure**: Short-lived tokens issued by GitHub
 **Easy Rotation**: No credential rotation needed
 **Audit Trail**: Better tracking in Azure AD logs
 **Recommended by Microsoft**: Best practice for GitHub Actions

---

## Testing the Pipeline

After setup is complete:

1. Make a small change to any file in `Use-cases/02-NetFramework30-ASPNET-WEB/`
2. Commit and push to `main` branch
3. Go to: https://github.com/v-deepd/GHCP_CI/actions
4. Watch the workflow run
5. Verify deployment succeeds

---

## Troubleshooting

### Error: "No subscription found"
- Verify the App Registration has Contributor role on the resource group
- Check the subscription ID is correct in the workflow

### Error: "Login failed"
- Verify the Federated Credential is configured correctly
- Check Organization and Repository names match exactly (case-sensitive)
- Ensure Entity type is "Branch" and branch name is "main"

### Error: "Client ID not found"
- Verify you updated the AZURE_CLIENT_ID in the workflow file
- Ensure you''re using the Application (client) ID, not Object ID

---

## Resources

- [Microsoft Docs: Workload Identity Federation](https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation)
- [GitHub Docs: OIDC with Azure](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
