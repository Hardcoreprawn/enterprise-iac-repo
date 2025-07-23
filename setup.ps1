#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Quick setup script for enterprise IaC toolkit

.DESCRIPTION
    Initializes the development environment and installs required Azure PowerShell modules.
    This is a convenience wrapper around the more comprehensive scripts in the scripts/ directory.

.PARAMETER Force
    Force reinstallation of modules even if they're already installed

.EXAMPLE
    ./setup.ps1
    Basic setup for development environment

.EXAMPLE
    ./setup.ps1 -Force
    Force reinstall all modules
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "🚀 Enterprise IaC Toolkit Setup" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "scripts" -PathType Container)) {
    Write-Host "❌ Error: Must run from repository root directory" -ForegroundColor Red
    exit 1
}

# Run the comprehensive setup script
Write-Host "Running comprehensive setup..." -ForegroundColor Yellow
& "./scripts/test-setup.ps1" -ShowDetails

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Configure local-validation-config.json for your environment" -ForegroundColor White
    Write-Host "2. Run 'az login' to authenticate with Azure" -ForegroundColor White
    Write-Host "3. Run 'make validate-dry' to test the setup" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Setup encountered issues. See output above for details." -ForegroundColor Red
    exit 1
}
