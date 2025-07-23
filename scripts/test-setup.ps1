#!/usr/bin/env pwsh
# Setup Validation Test
# Tests that the toolkit is properly configured and all tools work

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails = $false
)

Write-Host "Enterprise IaC Toolkit - Setup Validation" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

$results = @()
$failed = 0

function Test-Command {
    param(
        [string]$Name,
        [string]$Command,
        [string]$ExpectedOutput = $null,
        [switch]$ShouldSucceed
    )
    
    Write-Host "Testing $Name..." -NoNewline
    
    try {
        $output = Invoke-Expression $Command 2>&1
        $exitCode = $LASTEXITCODE
        
        if ((-not $ShouldSucceed.IsPresent -or $ShouldSucceed) -and $exitCode -eq 0) {
            Write-Host " ✓ PASS" -ForegroundColor Green
            $script:results += [PSCustomObject]@{
                Test = $Name
                Status = "PASS"
                Output = if ($ShowDetails) { $output } else { $null }
            }
        } elseif ($ShouldSucceed.IsPresent -and -not $ShouldSucceed -and $exitCode -ne 0) {
            Write-Host " ✓ PASS" -ForegroundColor Green
            $script:results += [PSCustomObject]@{
                Test = $Name
                Status = "PASS"
                Output = if ($ShowDetails) { $output } else { $null }
            }
        } else {
            Write-Host " ✗ FAIL" -ForegroundColor Red
            if ($ShowDetails) {
                Write-Host "   Output: $output" -ForegroundColor Yellow
            }
            $script:failed++
            $script:results += [PSCustomObject]@{
                Test = $Name
                Status = "FAIL"
                Output = $output
            }
        }
    } catch {
        Write-Host " ✗ FAIL" -ForegroundColor Red
        if ($ShowDetails) {
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $script:failed++
        $script:results += [PSCustomObject]@{
            Test = $Name
            Status = "FAIL"
            Output = $_.Exception.Message
        }
    }
}

function Test-FileExists {
    param(
        [string]$Name,
        [string]$Path
    )
    
    Write-Host "Testing $Name..." -NoNewline
    
    if (Test-Path $Path) {
        Write-Host " ✓ PASS" -ForegroundColor Green
        $script:results += [PSCustomObject]@{
            Test = $Name
            Status = "PASS"
            Output = "File exists: $Path"
        }
    } else {
        Write-Host " ✗ FAIL" -ForegroundColor Red
        $script:failed++
        $script:results += [PSCustomObject]@{
            Test = $Name
            Status = "FAIL"
            Output = "File missing: $Path"
        }
    }
}

# Core Tool Tests
Write-Host "Core Tools" -ForegroundColor Cyan
Write-Host "----------" -ForegroundColor Cyan
Test-Command "PowerShell Version" "pwsh --version"
Test-Command "Terraform" "terraform version"
Test-Command "Azure CLI" "az version --output json"
Test-Command "Git" "git --version"
Test-Command "Make" "make --version"

Write-Host ""

# Repository Structure Tests
Write-Host "Repository Structure" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan
Test-FileExists "Terraform Foundation" "terraform/foundation/main.tf"
Test-FileExists "Validation Script" "scripts/validate-local.ps1"
Test-FileExists "Local Config Template" "local-validation-config.json"
Test-FileExists "Bootstrap Config" "bootstrap-config.json"
Test-FileExists "Makefile" "Makefile"
Test-FileExists "Azure Module Installer" "scripts/install-azure-modules.ps1"
Test-FileExists "Bootstrap Script" "scripts/bootstrap-azure.ps1"

Write-Host ""

# Module Structure Tests
Write-Host "Module Structure" -ForegroundColor Cyan
Write-Host "---------------" -ForegroundColor Cyan
Test-FileExists "Modules Directory" "terraform/modules"
Test-FileExists "Tests Directory" "tests"
Test-FileExists "Pipelines Directory" "pipelines"
Test-FileExists "Documentation" "docs/standards"

Write-Host ""

# Validation Framework Tests
Write-Host "Validation Framework" -ForegroundColor Cyan
Write-Host "-------------------" -ForegroundColor Cyan
Test-Command "Make Help" "make help"
Test-Command "Validation Dry Run" "make validate-dry"

Write-Host ""

# DevContainer Integration Tests
Write-Host "DevContainer Integration" -ForegroundColor Cyan
Write-Host "-----------------------" -ForegroundColor Cyan
Test-FileExists "DevContainer Config" ".devcontainer/devcontainer.json"
Test-FileExists "Post-Create Script" ".devcontainer/post-create.sh"

Write-Host ""

# Azure Integration Tests (Optional)
Write-Host "Azure Integration (Optional)" -ForegroundColor Cyan
Write-Host "---------------------------" -ForegroundColor Cyan

if ($env:AZURE_SUBSCRIPTION_ID) {
    Test-Command "Azure Login Check" "az account show --query 'id' -o tsv"
} else {
    Write-Host "Azure authentication not configured (optional)" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
$total = $results.Count
$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "🎉 All tests passed! Your enterprise IaC toolkit is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Configure Azure authentication: az login" -ForegroundColor White
    Write-Host "2. Edit local-validation-config.json for your environment" -ForegroundColor White
    Write-Host "3. Run 'make validate' to test full validation pipeline" -ForegroundColor White
    Write-Host "4. Start building infrastructure modules in terraform/modules/" -ForegroundColor White
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Some tests failed. Please review the results above." -ForegroundColor Red
    
    if ($ShowDetails) {
        Write-Host ""
        Write-Host "Failed Tests Details:" -ForegroundColor Yellow
        $results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
            Write-Host "- $($_.Test): $($_.Output)" -ForegroundColor Red
        }
    }
    
    exit 1
}
