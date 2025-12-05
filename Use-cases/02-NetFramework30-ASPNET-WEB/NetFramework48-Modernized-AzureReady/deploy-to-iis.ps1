# IIS Deployment Script for Modernized ASP.NET Application

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ASP.NET Application Deployment to IIS" -ForegroundColor Green
Write-Host "================================================`n" -ForegroundColor Cyan

# Variables
$siteName = "NetFramework30ASPNETWEB"
$appPoolName = "NetFramework30AppPool"
$physicalPath = "$PWD"
$port = 8080

# Check if IIS is installed
$iisService = Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue
if (-not $iisService) {
    Write-Host " IIS is not installed. Please complete IIS installation first." -ForegroundColor Red
    exit 1
}

# Start IIS if not running
if ($iisService.Status -ne 'Running') {
    Write-Host "Starting IIS..." -ForegroundColor Yellow
    Start-Service W3SVC
}

Write-Host " IIS is running" -ForegroundColor Green

# Import WebAdministration module
Import-Module WebAdministration -ErrorAction Stop

# Create Application Pool
Write-Host "`nCreating Application Pool: $appPoolName" -ForegroundColor Cyan
if (Test-Path "IIS:\AppPools\$appPoolName") {
    Write-Host "  Application Pool already exists, removing..." -ForegroundColor Yellow
    Remove-WebAppPool -Name $appPoolName
}

New-WebAppPool -Name $appPoolName
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value "v4.0"
Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "enable32BitAppOnWin64" -Value $false
Write-Host " Application Pool created" -ForegroundColor Green

# Create Website
Write-Host "`nCreating Website: $siteName" -ForegroundColor Cyan
if (Test-Path "IIS:\Sites\$siteName") {
    Write-Host "  Website already exists, removing..." -ForegroundColor Yellow
    Remove-WebSite -Name $siteName
}

New-WebSite -Name $siteName `
    -PhysicalPath $physicalPath `
    -ApplicationPool $appPoolName `
    -Port $port
    
Write-Host " Website created" -ForegroundColor Green

# Start the website
Start-WebSite -Name $siteName
Write-Host " Website started" -ForegroundColor Green

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "`nApplication URL: http://localhost:$port" -ForegroundColor Yellow
Write-Host "IIS Manager: Run 'inetmgr' to manage the site`n" -ForegroundColor Cyan
