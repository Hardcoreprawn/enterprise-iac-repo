# Setup Script for Infrastructure Toolkit

# Initializes the toolkit for DevContainer development
# Simplified for consistent Linux container environment

param(
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipHooks = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Minimal = $false
)

Write-Host "Infrastructure Toolkit Setup" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host ""

# Check if we're in DevContainer
$isDevContainer = $env:REMOTE_CONTAINERS -eq "true" -or (Test-Path "/.dockerenv")

if (-not $isDevContainer) {
    Write-Host "⚠️  Warning: This setup script is optimized for DevContainer environments." -ForegroundColor Yellow
    Write-Host "   For local development, please use the DevContainer setup instead." -ForegroundColor Yellow
    Write-Host "   See the Quick Start Guide for instructions." -ForegroundColor White
    Write-Host ""
}

$setupResults = @()

# Quick tool verification (DevContainer should have everything)
Write-Host "Verifying DevContainer tools..." -ForegroundColor Yellow

$tools = @(
    @{ Name = "PowerShell"; Command = "pwsh"; Required = $true },
    @{ Name = "Git"; Command = "git"; Required = $true },
    @{ Name = "Azure CLI"; Command = "az"; Required = $false },
    @{ Name = "Terraform"; Command = "terraform"; Required = $false },
    @{ Name = "Make"; Command = "make"; Required = $false }
)

$missingTools = @()

foreach ($tool in $tools) {
    if (Get-Command $tool.Command -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ $($tool.Name)" -ForegroundColor Green
        $setupResults += @{ Component = $tool.Name; Status = "Available" }
    } else {
        $color = if ($tool.Required) { "Red" } else { "Yellow" }
        $symbol = if ($tool.Required) { "✗" } else { "⚠" }
        Write-Host "  $symbol $($tool.Name)" -ForegroundColor $color
        
        if ($tool.Required) {
            $missingTools += $tool.Name
        }
        
        $setupResults += @{ Component = $tool.Name; Status = "Missing" }
    }
}

# Check Azure PowerShell repository configuration
Write-Host "  Checking Azure PowerShell configuration..." -ForegroundColor Cyan
try {
    $psGallery = Get-PSRepository PSGallery -ErrorAction SilentlyContinue
    if ($psGallery -and $psGallery.InstallationPolicy -eq 'Trusted') {
        Write-Host "  ✓ Azure PowerShell (on-demand installation ready)" -ForegroundColor Green
        $setupResults += @{ Component = "Azure PowerShell"; Status = "Ready" }
    } else {
        Write-Host "  ⚠ Azure PowerShell repository not configured" -ForegroundColor Yellow
        $setupResults += @{ Component = "Azure PowerShell"; Status = "Config Needed" }
    }
} catch {
    Write-Host "  ✗ PowerShell Gallery access failed" -ForegroundColor Red
    $setupResults += @{ Component = "Azure PowerShell"; Status = "Failed" }
}

if ($missingTools.Count -gt 0 -and -not $Force) {
    Write-Host "`nMissing required tools: $($missingTools -join ', ')" -ForegroundColor Red
    Write-Host "This suggests the DevContainer setup didn't complete properly." -ForegroundColor Red
    Write-Host "Try rebuilding the container or use -Force to continue anyway." -ForegroundColor Yellow
    exit 1
}

# Initialize configuration
Write-Host "`nInitializing configuration..." -ForegroundColor Yellow

$configFile = "local-validation-config.json"
if (Test-Path $configFile -and -not $Force) {
    Write-Host "  Configuration file already exists: $configFile" -ForegroundColor Cyan
    $setupResults += @{ Component = "Configuration"; Status = "Exists" }
} else {
    Write-Host "  Creating configuration file: $configFile" -ForegroundColor Cyan
    
    # Prompt for basic configuration
    $resourceGroup = Read-Host "  Enter test resource group name (optional, press Enter to skip)"
    $subscription = Read-Host "  Enter Azure subscription ID (optional, press Enter to skip)"
    
    $config = @{
        description = "Local validation configuration - customize for your environment"
        resourceGroup = if ($resourceGroup) { $resourceGroup } else { $null }
        subscription = if ($subscription) { $subscription } else { $null }
        runConnectivityTests = $true
        runSecurityTests = if ($resourceGroup) { $true } else { $false }
        runMonitoringTests = if ($resourceGroup) { $true } else { $false }
        localMode = @{
            skipAzureAuth = $false
            dryRunByDefault = $false
            validateTerraformOnly = $false
        }
    }
    
    $config | ConvertTo-Json -Depth 3 | Out-File $configFile
    $setupResults += @{ Component = "Configuration"; Status = "Created" }
}

# Install git hooks
if (-not $SkipHooks) {
    Write-Host "`nSetting up git hooks..." -ForegroundColor Yellow
    
    if (Test-Path ".git" -PathType Container) {
        if (Test-Path "hooks/pre-commit.ps1") {
            try {
                & "hooks/pre-commit.ps1" -Install
                Write-Host "  ✓ Git hooks installed" -ForegroundColor Green
                $setupResults += @{ Component = "Git Hooks"; Status = "Installed" }
            } catch {
                Write-Host "  ⚠ Git hooks installation failed: $($_.Exception.Message)" -ForegroundColor Yellow
                $setupResults += @{ Component = "Git Hooks"; Status = "Failed" }
            }
        } else {
            Write-Host "  ⚠ Git hook scripts not found" -ForegroundColor Yellow
            $setupResults += @{ Component = "Git Hooks"; Status = "Not Available" }
        }
    } else {
        Write-Host "  ⚠ Not in a git repository - skipping hook installation" -ForegroundColor Yellow
        $setupResults += @{ Component = "Git Hooks"; Status = "Skipped" }
    }
}

# Validate setup
Write-Host "`nValidating setup..." -ForegroundColor Yellow

if (Test-Path "validate-local.ps1") {
    try {
        Write-Host "  Running validation test..." -ForegroundColor Cyan
        & "./validate-local.ps1" -DryRun
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Validation test passed" -ForegroundColor Green
            $setupResults += @{ Component = "Validation Test"; Status = "Passed" }
        } else {
            Write-Host "  ⚠ Validation test completed with warnings" -ForegroundColor Yellow
            $setupResults += @{ Component = "Validation Test"; Status = "Warnings" }
        }
    } catch {
        Write-Host "  ✗ Validation test failed: $($_.Exception.Message)" -ForegroundColor Red
        $setupResults += @{ Component = "Validation Test"; Status = "Failed" }
    }
} else {
    Write-Host "  ✗ Validation script not found" -ForegroundColor Red
    $setupResults += @{ Component = "Validation Test"; Status = "Not Found" }
}

# Generate setup summary
Write-Host "`n" -NoNewline
Write-Host "Setup Summary" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan

foreach ($result in $setupResults) {
    $color = switch ($result.Status) {
        "Available" { "Green" }
        "Created" { "Green" }
        "Installed" { "Green" }
        "Passed" { "Green" }
        "Exists" { "Cyan" }
        "Warnings" { "Yellow" }
        "Missing" { "Red" }
        "Failed" { "Red" }
        "Not Found" { "Red" }
        default { "White" }
    }
    
    Write-Host "$($result.Component): $($result.Status)" -ForegroundColor $color
}

# Next steps
Write-Host "`nNext Steps:" -ForegroundColor Green
Write-Host "1. Review and customize: $configFile" -ForegroundColor White
Write-Host "2. Test the toolkit: ./validate-local.ps1" -ForegroundColor White
Write-Host "3. Start building infrastructure in terraform/" -ForegroundColor White

if ($missingOptional.Count -gt 0) {
    Write-Host "4. Install optional prerequisites for full functionality" -ForegroundColor Yellow
}

Write-Host "`nToolkit Commands:" -ForegroundColor Cyan
if (Get-Command "make" -ErrorAction SilentlyContinue) {
    Write-Host "  make validate      - Full validation" -ForegroundColor White
    Write-Host "  make validate-dry  - Quick validation" -ForegroundColor White
    Write-Host "  make help          - Show all commands" -ForegroundColor White
} else {
    Write-Host "  ./validate-local.ps1         - Full validation" -ForegroundColor White
    Write-Host "  ./validate-local.ps1 -DryRun - Quick validation" -ForegroundColor White
}

Write-Host "`nSetup complete! 🚀" -ForegroundColor Green
