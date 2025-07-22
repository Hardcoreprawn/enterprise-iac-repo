# PowerShell pre-commit hook for Windows environments
# Run this manually or set up as a PowerShell scheduled task

param(
    [switch]$Install,
    [switch]$Uninstall
)

$hookPath = ".git/hooks/pre-commit"

if ($Install) {
    Write-Host "Installing pre-commit hook..." -ForegroundColor Green
    
    # Ensure .git/hooks directory exists
    if (-not (Test-Path ".git/hooks" -PathType Container)) {
        New-Item -Path ".git/hooks" -ItemType Directory -Force | Out-Null
    }
    
    # Copy hook script
    if (Test-Path "hooks/pre-commit") {
        Copy-Item "hooks/pre-commit" $hookPath -Force
        Write-Host "Pre-commit hook installed successfully" -ForegroundColor Green
        Write-Host "Hook location: $hookPath" -ForegroundColor Cyan
    } else {
        Write-Host "Error: hooks/pre-commit not found" -ForegroundColor Red
        exit 1
    }
    
    return
}

if ($Uninstall) {
    Write-Host "Removing pre-commit hook..." -ForegroundColor Yellow
    
    if (Test-Path $hookPath) {
        Remove-Item $hookPath -Force
        Write-Host "Pre-commit hook removed" -ForegroundColor Green
    } else {
        Write-Host "No pre-commit hook found to remove" -ForegroundColor Yellow
    }
    
    return
}

# Manual pre-commit validation
Write-Host "Infrastructure Pre-Commit Validation" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Check for staged infrastructure files
$stagedFiles = git diff --cached --name-only 2>$null

if (-not $stagedFiles) {
    Write-Host "No staged files found" -ForegroundColor Yellow
    exit 0
}

$infraFiles = $stagedFiles | Where-Object { 
    $_ -like "*.tf" -or 
    $_ -like "*.tfvars" -or 
    $_ -like "*.json" -or 
    $_ -like "tests/*" -or
    $_ -like "terraform/*"
}

if (-not $infraFiles) {
    Write-Host "No infrastructure files staged for commit" -ForegroundColor Yellow
    exit 0
}

Write-Host "Infrastructure files detected in commit:" -ForegroundColor Cyan
$infraFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

# Run validation
Write-Host "`nRunning infrastructure validation..." -ForegroundColor Yellow

if (Test-Path "validate-local.ps1") {
    # Quick validation for pre-commit
    & "./validate-local.ps1" -DryRun
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✓ Pre-commit validation passed" -ForegroundColor Green
        Write-Host "Recommendation: Run full validation before pushing" -ForegroundColor Cyan
        Write-Host "Command: ./validate-local.ps1" -ForegroundColor White
    } else {
        Write-Host "`n✗ Pre-commit validation failed" -ForegroundColor Red
        Write-Host "Run './validate-local.ps1' for detailed results" -ForegroundColor Yellow
        Write-Host "Use 'git commit --no-verify' to bypass this check" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "Warning: validate-local.ps1 not found - skipping validation" -ForegroundColor Yellow
}

exit 0
