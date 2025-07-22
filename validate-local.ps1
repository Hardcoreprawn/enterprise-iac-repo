# Local Infrastructure Validation Runner

# Runs all infrastructure validation tests locally before committing changes
# Designed to be portable across organizations and roles

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "local-validation-config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConnectivity = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSecurity = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipMonitoring = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "Local Infrastructure Validation Runner" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Load local configuration
if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    Write-Host "Using configuration: $ConfigFile" -ForegroundColor Cyan
} else {
    Write-Host "Configuration file not found: $ConfigFile" -ForegroundColor Yellow
    Write-Host "Using default validation settings" -ForegroundColor Yellow
    $config = @{
        resourceGroup = "rg-test-local"
        subscription = $null
        runConnectivityTests = $true
        runSecurityTests = $true
        runMonitoringTests = $true
    }
}

$results = @()
$startTime = Get-Date

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$prereqCheck = @{
    TestName = "Prerequisites"
    Status = "CHECKING"
    Details = @()
}

# Check if running in correct directory
if (-not (Test-Path "terraform" -PathType Container)) {
    $prereqCheck.Details += "Warning: Not in infrastructure repo root (no terraform/ directory found)"
}

# Check Azure CLI or PowerShell availability
try {
    Get-Command "az" -ErrorAction Stop | Out-Null
    $prereqCheck.Details += "Azure CLI available"
} catch {
    try {
        Get-Module -ListAvailable Az.* | Out-Null
        $prereqCheck.Details += "Azure PowerShell modules available"
    } catch {
        $prereqCheck.Status = "FAIL"
        $prereqCheck.Details += "ERROR: Neither Azure CLI nor Azure PowerShell available"
        $results += $prereqCheck
        Write-Host "Prerequisites failed - missing Azure tools" -ForegroundColor Red
        exit 1
    }
}

$prereqCheck.Status = "PASS"
$results += $prereqCheck
Write-Host "Prerequisites check: PASS" -ForegroundColor Green

# Terraform validation (if terraform directory exists)
if (Test-Path "terraform" -PathType Container) {
    Write-Host "`nValidating Terraform configuration..." -ForegroundColor Yellow
    
    $terraformResult = @{
        TestName = "Terraform Validation"
        Status = "CHECKING"
        Details = @()
    }
    
    try {
        Push-Location "terraform"
        
        # Check terraform files exist
        $tfFiles = Get-ChildItem -Filter "*.tf" -Recurse
        if ($tfFiles.Count -eq 0) {
            $terraformResult.Status = "SKIP"
            $terraformResult.Details += "No .tf files found"
        } else {
            if ($DryRun) {
                $terraformResult.Status = "SKIP"
                $terraformResult.Details += "Skipped - dry run mode"
            } else {
                # Run terraform validate
                $validateOutput = terraform validate 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $terraformResult.Status = "PASS"
                    $terraformResult.Details += "Terraform configuration valid"
                } else {
                    $terraformResult.Status = "FAIL"
                    $terraformResult.Details += "Terraform validation failed: $validateOutput"
                }
            }
        }
    } catch {
        $terraformResult.Status = "FAIL"
        $terraformResult.Details += "Error running terraform validate: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
    
    $results += $terraformResult
    
    $color = switch ($terraformResult.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
    }
    Write-Host "Terraform validation: $($terraformResult.Status)" -ForegroundColor $color
}

# Connectivity Tests
if (-not $SkipConnectivity -and $config.runConnectivityTests) {
    Write-Host "`nRunning connectivity tests..." -ForegroundColor Yellow
    
    $connectivityResult = @{
        TestName = "Connectivity Tests"
        Status = "CHECKING"
        Details = @()
    }
    
    if (Test-Path "tests/connectivity/test-network-connectivity.ps1") {
        try {
            if ($DryRun) {
                $connectivityResult.Status = "SKIP"
                $connectivityResult.Details += "Skipped - dry run mode"
            } else {
                $connectivityArgs = @()
                if (Test-Path "tests/connectivity/connectivity-tests.json") {
                    $connectivityArgs += "-TestConfigFile", "tests/connectivity/connectivity-tests.json"
                }
                
                & "tests/connectivity/test-network-connectivity.ps1" @connectivityArgs
                
                if ($LASTEXITCODE -eq 0) {
                    $connectivityResult.Status = "PASS"
                    $connectivityResult.Details += "All connectivity tests passed"
                } else {
                    $connectivityResult.Status = "FAIL"
                    $connectivityResult.Details += "Connectivity test failures detected"
                }
            }
        } catch {
            $connectivityResult.Status = "FAIL"
            $connectivityResult.Details += "Error running connectivity tests: $($_.Exception.Message)"
        }
    } else {
        $connectivityResult.Status = "SKIP"
        $connectivityResult.Details += "Connectivity test script not found"
    }
    
    $results += $connectivityResult
    
    $color = switch ($connectivityResult.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
    }
    Write-Host "Connectivity tests: $($connectivityResult.Status)" -ForegroundColor $color
}

# Security Tests
if (-not $SkipSecurity -and $config.runSecurityTests -and $config.resourceGroup) {
    Write-Host "`nRunning security compliance tests..." -ForegroundColor Yellow
    
    $securityResult = @{
        TestName = "Security Compliance"
        Status = "CHECKING"
        Details = @()
    }
    
    if (Test-Path "tests/compliance/validate-security-compliance.ps1") {
        try {
            if ($DryRun) {
                $securityResult.Status = "SKIP"
                $securityResult.Details += "Skipped - dry run mode"
            } else {
                $securityArgs = @("-ResourceGroupName", $config.resourceGroup)
                if ($config.subscription) {
                    $securityArgs += "-SubscriptionId", $config.subscription
                }
                
                & "tests/compliance/validate-security-compliance.ps1" @securityArgs
                
                if ($LASTEXITCODE -eq 0) {
                    $securityResult.Status = "PASS"
                    $securityResult.Details += "All security compliance checks passed"
                } elseif ($LASTEXITCODE -eq 1) {
                    $securityResult.Status = "WARN"
                    $securityResult.Details += "Non-critical security issues detected"
                } else {
                    $securityResult.Status = "FAIL"
                    $securityResult.Details += "Critical security compliance failures"
                }
            }
        } catch {
            $securityResult.Status = "FAIL"
            $securityResult.Details += "Error running security tests: $($_.Exception.Message)"
        }
    } else {
        $securityResult.Status = "SKIP"
        $securityResult.Details += "Security compliance script not found"
    }
    
    $results += $securityResult
    
    $color = switch ($securityResult.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
    }
    Write-Host "Security compliance: $($securityResult.Status)" -ForegroundColor $color
}

# Monitoring Tests
if (-not $SkipMonitoring -and $config.runMonitoringTests -and $config.resourceGroup) {
    Write-Host "`nRunning monitoring configuration tests..." -ForegroundColor Yellow
    
    $monitoringResult = @{
        TestName = "Monitoring Configuration"
        Status = "CHECKING"
        Details = @()
    }
    
    if (Test-Path "tests/compliance/validate-monitoring-config.ps1") {
        try {
            if ($DryRun) {
                $monitoringResult.Status = "SKIP"
                $monitoringResult.Details += "Skipped - dry run mode"
            } else {
                $monitoringArgs = @("-ResourceGroupName", $config.resourceGroup)
                if ($config.subscription) {
                    $monitoringArgs += "-SubscriptionId", $config.subscription
                }
                
                & "tests/compliance/validate-monitoring-config.ps1" @monitoringArgs
                
                if ($LASTEXITCODE -eq 0) {
                    $monitoringResult.Status = "PASS"
                    $monitoringResult.Details += "All monitoring configuration checks passed"
                } elseif ($LASTEXITCODE -eq 1) {
                    $monitoringResult.Status = "WARN"
                    $monitoringResult.Details += "Non-critical monitoring issues detected"
                } else {
                    $monitoringResult.Status = "FAIL"
                    $monitoringResult.Details += "Critical monitoring configuration failures"
                }
            }
        } catch {
            $monitoringResult.Status = "FAIL"
            $monitoringResult.Details += "Error running monitoring tests: $($_.Exception.Message)"
        }
    } else {
        $monitoringResult.Status = "SKIP"
        $monitoringResult.Details += "Monitoring configuration script not found"
    }
    
    $results += $monitoringResult
    
    $color = switch ($monitoringResult.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
    }
    Write-Host "Monitoring configuration: $($monitoringResult.Status)" -ForegroundColor $color
}

# Generate summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n" -NoNewline
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

$passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = ($results | Where-Object { $_.Status -eq "WARN" }).Count
$skipCount = ($results | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host "Duration: $($duration.TotalSeconds) seconds" -ForegroundColor White
Write-Host "Tests Run: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Warnings: $warnCount" -ForegroundColor Yellow
Write-Host "Skipped: $skipCount" -ForegroundColor Yellow

# Show detailed results for failures and warnings
$issueResults = $results | Where-Object { $_.Status -in @("FAIL", "WARN") }
if ($issueResults.Count -gt 0) {
    Write-Host "`nIssues Found:" -ForegroundColor Yellow
    foreach ($result in $issueResults) {
        $color = if ($result.Status -eq "FAIL") { "Red" } else { "Yellow" }
        Write-Host "[$($result.Status)] $($result.TestName)" -ForegroundColor $color
        foreach ($detail in $result.Details) {
            Write-Host "  - $detail" -ForegroundColor White
        }
    }
}

# Save results for pipeline integration
$report = @{
    Timestamp = $endTime.ToString("yyyy-MM-dd HH:mm:ss")
    Duration = $duration.TotalSeconds
    Summary = @{
        Total = $results.Count
        Passed = $passCount
        Failed = $failCount
        Warnings = $warnCount
        Skipped = $skipCount
    }
    Results = $results
}

$reportFile = "validation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 4 | Out-File $reportFile
Write-Host "`nDetailed report saved: $reportFile" -ForegroundColor Cyan

# Recommendations for next steps
if ($failCount -eq 0 -and $warnCount -eq 0) {
    Write-Host "`nAll validations passed - ready to commit!" -ForegroundColor Green
    exit 0
} elseif ($failCount -eq 0) {
    Write-Host "`nValidation completed with warnings - review before committing" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`nValidation failed - fix issues before committing" -ForegroundColor Red
    exit 1
}
