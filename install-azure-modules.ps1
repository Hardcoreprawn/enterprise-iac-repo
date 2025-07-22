#!/usr/bin/env pwsh

# Azure PowerShell Module Installer
# Installs Azure PowerShell modules on-demand when needed

param(
    [Parameter(Mandatory=$false)]
    [string[]]$Modules = @("Az.Accounts", "Az.Resources", "Az.Storage", "Az.KeyVault", "Az.Monitor"),
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllModules = $false
)

Write-Host "🔧 Azure PowerShell Module Installer" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Function to check if module is installed
function Test-ModuleInstalled {
    param([string]$ModuleName)
    return $null -ne (Get-Module -ListAvailable $ModuleName)
}

# Install all Az modules if requested
if ($AllModules) {
    Write-Host "📦 Installing complete Az module suite..."
    try {
        Install-Module -Name Az -Scope CurrentUser -Force:$Force -AllowClobber
        Write-Host "✅ All Azure PowerShell modules installed successfully" -ForegroundColor Green
        return
    }
    catch {
        Write-Host "❌ Failed to install Az modules: $_" -ForegroundColor Red
        exit 1
    }
}

# Install specific modules
Write-Host "📦 Installing Azure PowerShell modules on-demand..."
Write-Host "Modules to install: $($Modules -join ', ')"
Write-Host ""

$installed = @()
$failed = @()

foreach ($module in $Modules) {
    if (-not $Force -and (Test-ModuleInstalled $module)) {
        Write-Host "✅ $module - Already installed" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "📥 Installing $module..." -ForegroundColor Cyan
    try {
        Install-Module -Name $module -Scope CurrentUser -Force:$Force -AllowClobber
        $installed += $module
        Write-Host "✅ $module - Installed successfully" -ForegroundColor Green
    }
    catch {
        $failed += $module
        Write-Host "❌ $module - Installation failed: $_" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "📊 Installation Summary:" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

if ($installed.Count -gt 0) {
    Write-Host "✅ Successfully installed: $($installed -join ', ')" -ForegroundColor Green
}

if ($failed.Count -gt 0) {
    Write-Host "❌ Failed to install: $($failed -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "  - Check internet connectivity"
    Write-Host "  - Run with -Force parameter to overwrite existing modules"
    Write-Host "  - Ensure PowerShell Gallery is accessible"
}

Write-Host ""
Write-Host "🎯 Usage examples:" -ForegroundColor Cyan
Write-Host "  Connect-AzAccount          # Sign in to Azure"
Write-Host "  Get-AzSubscription         # List subscriptions"
Write-Host "  Get-AzResourceGroup        # List resource groups"

if ($failed.Count -gt 0) {
    exit 1
}
