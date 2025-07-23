#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Install Azure PowerShell modules on-demand

.DESCRIPTION
    Convenience wrapper for the Azure module installer in scripts/ directory.
    Installs essential Azure PowerShell modules for infrastructure automation.

.PARAMETER AllModules
    Install the complete Az module suite instead of just essential modules

.PARAMETER Force
    Force reinstallation even if modules are already installed

.EXAMPLE
    ./install-azure-modules.ps1
    Install essential Azure modules

.EXAMPLE
    ./install-azure-modules.ps1 -AllModules
    Install complete Az module suite
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$AllModules = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "📦 Azure PowerShell Module Installer" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "scripts" -PathType Container)) {
    Write-Host "❌ Error: Must run from repository root directory" -ForegroundColor Red
    exit 1
}

# Build arguments for the main script
$scriptArgs = @()
if ($AllModules) { $scriptArgs += "-AllModules" }
if ($Force) { $scriptArgs += "-Force" }

# Run the main installer script
Write-Host "Running Azure module installer..." -ForegroundColor Yellow
& "./scripts/install-azure-modules.ps1" @scriptArgs

exit $LASTEXITCODE
