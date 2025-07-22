# Setup Script for Infrastructure Toolkit

# Initializes the toolkit for local development across different environments
# Designed to be portable across organizations and operating systems

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

$setupResults = @()

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$prereqChecks = @(
    @{
        Name = "PowerShell"
        Check = { $PSVersionTable.PSVersion.Major -ge 5 }
        Required = $true
        InstallMsg = "Install PowerShell 7+ from https://github.com/PowerShell/PowerShell"
    },
    @{
        Name = "Git"
        Check = { Get-Command "git" -ErrorAction SilentlyContinue }
        Required = $true
        InstallMsg = "Install Git from https://git-scm.com/"
    },
    @{
        Name = "Azure CLI"
        Check = { Get-Command "az" -ErrorAction SilentlyContinue }
        Required = $false
        InstallMsg = "Install Azure CLI from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    },
    @{
        Name = "Azure PowerShell"
        Check = { Get-Module -ListAvailable Az.* }
        Required = $false
        InstallMsg = "Install Azure PowerShell: Install-Module -Name Az -Scope CurrentUser"
    },
    @{
        Name = "Terraform"
        Check = { Get-Command "terraform" -ErrorAction SilentlyContinue }
        Required = $false
        InstallMsg = "Install Terraform from https://terraform.io/downloads"
    },
    @{
        Name = "Make"
        Check = { Get-Command "make" -ErrorAction SilentlyContinue }
        Required = $false
        InstallMsg = "Install Make (Windows: chocolatey install make, Linux/Mac: usually pre-installed)"
    }
)

$missingRequired = @()
$missingOptional = @()

foreach ($check in $prereqChecks) {
    $result = & $check.Check
    if ($result) {
        Write-Host "  ✓ $($check.Name)" -ForegroundColor Green
        $setupResults += @{ Component = $check.Name; Status = "Available" }
    } else {
        $color = if ($check.Required) { "Red" } else { "Yellow" }
        $symbol = if ($check.Required) { "✗" } else { "⚠" }
        Write-Host "  $symbol $($check.Name)" -ForegroundColor $color
        
        if ($check.Required) {
            $missingRequired += $check
        } else {
            $missingOptional += $check
        }
        
        $setupResults += @{ Component = $check.Name; Status = "Missing"; InstallMsg = $check.InstallMsg }
    }
}

if ($missingRequired.Count -gt 0) {
    Write-Host "`nMissing required prerequisites:" -ForegroundColor Red
    foreach ($missing in $missingRequired) {
        Write-Host "  - $($missing.Name): $($missing.InstallMsg)" -ForegroundColor White
    }
    
    if (-not $Force) {
        Write-Host "`nSetup cannot continue without required prerequisites." -ForegroundColor Red
        Write-Host "Install missing prerequisites or use -Force to continue anyway." -ForegroundColor Yellow
        exit 1
    }
}

if ($missingOptional.Count -gt 0 -and -not $Minimal) {
    Write-Host "`nOptional prerequisites not found:" -ForegroundColor Yellow
    foreach ($missing in $missingOptional) {
        Write-Host "  - $($missing.Name): $($missing.InstallMsg)" -ForegroundColor White
    }
    Write-Host "These will limit available functionality but setup can continue." -ForegroundColor White
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
