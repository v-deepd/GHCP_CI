# Build and Run Script for ASP.NET Framework 4.8 WebForms Application
# Windows PowerShell Script
# Author: GitHub Copilot Migration Assistant
# Date: December 2, 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ASP.NET Framework 4.8 WebForms Build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if MSBuild is available
$msbuildPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1

if (-not $msbuildPath) {
    Write-Host " ERROR: MSBuild not found. Please install Visual Studio 2019 or later." -ForegroundColor Red
    Write-Host "   Download from: https://visualstudio.microsoft.com/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host " MSBuild found at: $msbuildPath" -ForegroundColor Green
Write-Host ""

# Restore NuGet packages
Write-Host " Restoring NuGet packages..." -ForegroundColor Yellow
nuget restore NetFramework30ASPNETWEB.sln
if ($LASTEXITCODE -ne 0) {
    Write-Host " NuGet restore failed" -ForegroundColor Red
    exit 1
}
Write-Host " NuGet packages restored" -ForegroundColor Green
Write-Host ""

# Build the solution
Write-Host " Building solution..." -ForegroundColor Yellow
& $msbuildPath NetFramework30ASPNETWEB.sln /p:Configuration=Release /p:Platform="Any CPU" /t:Rebuild /v:minimal

if ($LASTEXITCODE -ne 0) {
    Write-Host " Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " BUILD SUCCESSFUL" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host " Build output location: bin\Release\" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review build output for any warnings" -ForegroundColor White
Write-Host "  2. Test application locally with IIS Express" -ForegroundColor White
Write-Host "  3. Deploy to Azure App Service using:" -ForegroundColor White
Write-Host "     - Visual Studio Publish" -ForegroundColor Gray
Write-Host "     - Azure CLI (az webapp deployment)" -ForegroundColor Gray
Write-Host "     - GitHub Actions / Azure DevOps" -ForegroundColor Gray
Write-Host ""
