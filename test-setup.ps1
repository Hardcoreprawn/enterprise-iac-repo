#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Test that enterprise IaC toolkit setup is working correctly

.DESCRIPTION
    Convenience wrapper for the comprehensive test suite in scripts/ directory.
    Validates that all tools and configurations are working properly.

.PARAMETER ShowDetails
    Show detailed information about each test

.EXAMPLE
    ./test-setup.ps1
    Run basic setup validation

.EXAMPLE
    ./test-setup.ps1 -ShowDetails
    Run validation with detailed output
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails = $false
)

Write-Host "🧪 Enterprise IaC Toolkit Test Suite" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "scripts" -PathType Container)) {
    Write-Host "❌ Error: Must run from repository root directory" -ForegroundColor Red
    exit 1
}

# Build arguments for the main script
$scriptArgs = @()
if ($ShowDetails) { $scriptArgs += "-ShowDetails" }

# Run the main test script
Write-Host "Running comprehensive test suite..." -ForegroundColor Yellow
& "./scripts/test-setup.ps1" @scriptArgs

exit $LASTEXITCODE
