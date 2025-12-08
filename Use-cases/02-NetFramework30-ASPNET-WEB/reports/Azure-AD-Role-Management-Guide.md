# Azure AD Role Management Guide

## Overview
This application uses Azure AD Easy Auth for authentication and custom app roles for authorization.

## App Roles Created

### SecureAppUsers
- **Role ID**: 5eb2fe1a-b872-4e88-894a-66ce20ecc90e
- **Purpose**: Standard access to secure content
- **Permissions**: Can view the Secure.aspx page

### AppAdministrators
- **Role ID**: c872a4a3-0bfb-4e36-aa1f-a141079c02ad
- **Purpose**: Administrative access
- **Permissions**: Full access to all secure content

## Current Assignments

| User | Role | Date Assigned |
|------|------|---------------|
| Deepak D | AppAdministrators | 2025-12-08 12:25:26 UTC |

## How to Assign Users

### Using PowerShell Script (Recommended)
.\scripts\Assign-AzureADRole.ps1 -UserEmail "user@contoso.com" -RoleName "SecureAppUsers"

### Using Azure Portal
1. Azure Portal  Azure Active Directory  Enterprise Applications
2. Search: webapp-apps-winmig-emea-v-deepd-demo-web
3. Users and groups  Add user/group
4. Select user and role  Assign

## Testing Access
Access: https://webapp-apps-winmig-emea-v-deepd-demo-web-aye7gxb4b4htb8fh.canadacentral-01.azurewebsites.net/Secure.aspx

**Expected for assigned users:**
- Azure AD authentication required
- User information displayed
- Role appears in claims
- Authorization Status: Authorized
- Secret content visible

## Configuration Reference
- App Registration: d27a4c73-d0da-4636-b677-f08138df4733
- Service Principal: 4c210e62-bc68-4ef7-9300-6b13ffd5f1bb
- Tenant: 0e478cd4-3e52-496d-ac3a-419ca58ba7ac

## Troubleshooting
1. **User cant access**: Verify role assignment exists, wait 5-10 minutes for propagation
2. **Role not in claims**: Sign out and sign in again
3. **Assignment fails**: Use file-based JSON approach in PowerShell

Last Updated: 2025-12-08
