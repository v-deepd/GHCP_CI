# Azure AD Role Assignment Helper Script
# Use this script to assign users to SecureAppUsers or AppAdministrators roles

param(
    [Parameter(Mandatory=$true)]
    [string]$UserEmail,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('SecureAppUsers', 'AppAdministrators')]
    [string]$RoleName
)

# Configuration
$servicePrincipalId = '4c210e62-bc68-4ef7-9300-6b13ffd5f1bb'
$secureUsersRoleId = '5eb2fe1a-b872-4e88-894a-66ce20ecc90e'
$adminRoleId = 'c872a4a3-0bfb-4e36-aa1f-a141079c02ad'

Write-Host '=== Azure AD Role Assignment Script ===' -ForegroundColor Cyan
Write-Host 'App: webapp-apps-winmig-emea-v-deepd-demo-web' -ForegroundColor Gray
Write-Host ''

# Get user Object ID
Write-Host 'Looking up user...' -ForegroundColor Yellow
try {
    $userObjectId = az ad user show --id $UserEmail --query 'id' -o tsv
    if (-not $userObjectId) {
        Write-Host 'ERROR: User not found' -ForegroundColor Red
        exit 1
    }
    $userName = az ad user show --id $UserEmail --query 'displayName' -o tsv
    Write-Host "Found: $userName ($UserEmail)" -ForegroundColor Green
} catch {
    Write-Host 'ERROR: Failed to find user' -ForegroundColor Red
    exit 1
}

# Select role
$appRoleId = if ($RoleName -eq 'SecureAppUsers') { $secureUsersRoleId } else { $adminRoleId }
Write-Host "Role: $RoleName" -ForegroundColor Cyan

# Create assignment JSON
$assignmentJson = @{
    principalId = $userObjectId
    resourceId = $servicePrincipalId
    appRoleId = $appRoleId
} | ConvertTo-Json

$tempFile = Join-Path $env:TEMP 'role-assignment-temp.json'
$assignmentJson | Out-File -FilePath $tempFile -Encoding UTF8

# Assign role
Write-Host 'Assigning role...' -ForegroundColor Yellow
try {
    $result = az rest --method POST `
        --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$servicePrincipalId/appRoleAssignments" `
        --headers 'Content-Type=application/json' `
        --body "@$tempFile" | ConvertFrom-Json
    
    Write-Host ''
    Write-Host ' Role assignment successful!' -ForegroundColor Green
    Write-Host "User: $($result.principalDisplayName)" -ForegroundColor White
    Write-Host "Role: $RoleName" -ForegroundColor White
    Write-Host "Assigned: $($result.createdDateTime)" -ForegroundColor White
    Write-Host ''
    Write-Host 'User may need to sign out and sign in again for the role to take effect.' -ForegroundColor Yellow
} catch {
    Write-Host 'ERROR: Failed to assign role' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}
