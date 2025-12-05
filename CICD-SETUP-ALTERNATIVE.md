# Alternative CI/CD Setup (Without AD Permissions)

## Issue
You don't have permissions to create Service Principals via Azure CLI. This is common in enterprise environments where only administrators can manage Azure AD.

##  Solution 1: Request IT/Admin Assistance

### What to Request
Ask your Azure Administrator or IT team to create a Service Principal with these specifications:

**Service Principal Details:**
- Name: `github-actions-winmig` (or any name they prefer)
- Type: App Registration with Service Principal
- Role: `Contributor`
- Scope: `/subscriptions/95642268-5116-484d-9b88-7dfce8c20ce4/resourceGroups/rg-infra-winmig-eme-v-deepd-demo`
- Purpose: GitHub Actions CI/CD deployment

**Required Output:**
Ask them to provide you with a JSON in this format:
```json
{
  "clientId": "<app-id>",
  "clientSecret": "<password>",
  "subscriptionId": "95642268-5116-484d-9b88-7dfce8c20ce4",
  "tenantId": "<tenant-id>"
}
```

**Additional Permissions Needed:**
- Key Vault access policy: GET and LIST secrets on `kv-winmig-2695`

### Email Template to Send to Admin:

```
Subject: Request: Service Principal for GitHub Actions CI/CD

Hi [Admin Name],

I need a Service Principal created for automated deployments from GitHub Actions to Azure.

Details:
- Application Name: github-actions-winmig
- Role Assignment: Contributor
- Scope: Resource Group "rg-infra-winmig-eme-v-deepd-demo"
- Subscription ID: 95642268-5116-484d-9b88-7dfce8c20ce4

Additionally, please grant the Service Principal access to Key Vault:
- Key Vault Name: kv-winmig-2695
- Permissions: GET and LIST on secrets

Please provide me with the following JSON output:
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "95642268-5116-484d-9b88-7dfce8c20ce4",
  "tenantId": "..."
}

This will be used as a GitHub repository secret for automated deployments.

Thank you!
```

---

##  Solution 2: Use Deployment Credentials (App Service Specific)

If you only need to deploy to the specific App Service, you can use **Publish Profile** instead:

### Step 1: Download Publish Profile

Run this command (this should work without AD permissions):
```powershell
az webapp deployment list-publishing-profiles \
  --name "webapp-apps-winmig-emea-v-deepd-demo-web" \
  --resource-group "rg-infra-winmig-eme-v-deepd-demo" \
  --xml > publish-profile.xml
```

### Step 2: Add to GitHub Secrets

1. Go to: https://github.com/v-deepd/GHCP_CI/settings/secrets/actions
2. Click "New repository secret"
3. Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
4. Value: Paste the entire contents of `publish-profile.xml`
5. Click "Add secret"

### Step 3: Update Workflow File

The workflow needs to be modified to use publish profile instead of Service Principal.

I can help you update the workflow to use this method if you prefer.

---

##  Solution 3: Use Managed Identity (If Running from Azure)

If you''re deploying from Azure DevOps or another Azure service, you can use Managed Identity instead of Service Principal.

---

##  Recommended Approach

**For your situation, I recommend Solution 2 (Publish Profile)** because:
-  No Azure AD permissions required
-  Scoped only to the specific App Service
-  Quick to set up
-  Secure (credentials are managed by Azure)

**Drawback:**
- Only works for this specific App Service
- Cannot manage other Azure resources (Key Vault, etc.)

---

##  Next Steps

**Choose your approach:**

1. **If you want full control**: Use Solution 1 (contact admin)
2. **If you want quick deployment**: Use Solution 2 (publish profile) - I can help set this up now
3. **If deploying from Azure DevOps**: Use Solution 3 (managed identity)

Which approach would you like to proceed with?
