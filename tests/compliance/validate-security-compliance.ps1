# Security Configuration Validation

# Validates security configurations against enterprise standards
# Checks firewall rules, access controls, encryption, and compliance settings

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ComplianceConfigFile = "compliance-rules.json"
)

Write-Host "Starting security compliance validation for Resource Group: $ResourceGroupName" -ForegroundColor Green

# Load compliance configuration
if (-not (Test-Path $ComplianceConfigFile)) {
    Write-Error "Compliance configuration file not found: $ComplianceConfigFile"
    exit 1
}

$complianceConfig = Get-Content $ComplianceConfigFile | ConvertFrom-Json
$validationResults = @()

# Validate Network Security Groups
Write-Host "`nValidating Network Security Groups..." -ForegroundColor Yellow

$nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName

foreach ($nsg in $nsgs) {
    Write-Host "  Checking NSG: $($nsg.Name)" -ForegroundColor Cyan
    
    # Check for default deny rules
    $hasDefaultDeny = $nsg.SecurityRules | Where-Object { 
        $_.Access -eq "Deny" -and 
        $_.Priority -eq 4096 -and 
        $_.SourceAddressPrefix -eq "*" -and 
        $_.DestinationAddressPrefix -eq "*"
    }
    
    $result = @{
        ResourceType = "NetworkSecurityGroup"
        ResourceName = $nsg.Name
        Rule = "Default Deny Rule"
        Status = if ($hasDefaultDeny) { "PASS" } else { "FAIL" }
        Details = if ($hasDefaultDeny) { "Default deny rule found" } else { "Missing default deny rule" }
        Severity = "High"
    }
    $validationResults += $result
    
    # Check for overly permissive rules
    $permissiveRules = $nsg.SecurityRules | Where-Object {
        $_.Access -eq "Allow" -and 
        $_.SourceAddressPrefix -eq "*" -and
        $_.DestinationPortRange -eq "*"
    }
    
    foreach ($rule in $permissiveRules) {
        $result = @{
            ResourceType = "NetworkSecurityGroup"
            ResourceName = $nsg.Name
            Rule = "Overly Permissive Rule: $($rule.Name)"
            Status = "FAIL"
            Details = "Rule allows * to * on all ports"
            Severity = "Critical"
        }
        $validationResults += $result
    }
    
    # Check required ports are properly configured
    foreach ($portRule in $complianceConfig.requiredPortRules) {
        $matchingRule = $nsg.SecurityRules | Where-Object {
            $_.DestinationPortRange -eq $portRule.port -and
            $_.Access -eq $portRule.expectedAccess
        }
        
        $result = @{
            ResourceType = "NetworkSecurityGroup"
            ResourceName = $nsg.Name
            Rule = "Required Port Rule: $($portRule.port)"
            Status = if ($matchingRule) { "PASS" } else { "FAIL" }
            Details = if ($matchingRule) { "Port $($portRule.port) properly configured" } else { "Port $($portRule.port) not properly configured" }
            Severity = $portRule.severity
        }
        $validationResults += $result
    }
}

# Validate Storage Account Encryption
Write-Host "`nValidating Storage Account Security..." -ForegroundColor Yellow

$storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName

foreach ($storage in $storageAccounts) {
    Write-Host "  Checking Storage Account: $($storage.StorageAccountName)" -ForegroundColor Cyan
    
    # Check encryption at rest
    $result = @{
        ResourceType = "StorageAccount"
        ResourceName = $storage.StorageAccountName
        Rule = "Encryption at Rest"
        Status = if ($storage.Encryption.Services.Blob.Enabled) { "PASS" } else { "FAIL" }
        Details = if ($storage.Encryption.Services.Blob.Enabled) { "Blob encryption enabled" } else { "Blob encryption disabled" }
        Severity = "High"
    }
    $validationResults += $result
    
    # Check HTTPS only
    $result = @{
        ResourceType = "StorageAccount"
        ResourceName = $storage.StorageAccountName
        Rule = "HTTPS Only"
        Status = if ($storage.EnableHttpsTrafficOnly) { "PASS" } else { "FAIL" }
        Details = if ($storage.EnableHttpsTrafficOnly) { "HTTPS-only traffic enforced" } else { "HTTP traffic allowed" }
        Severity = "High"
    }
    $validationResults += $result
    
    # Check public access
    $result = @{
        ResourceType = "StorageAccount"
        ResourceName = $storage.StorageAccountName
        Rule = "Public Access Restrictions"
        Status = if ($storage.AllowBlobPublicAccess -eq $false) { "PASS" } else { "FAIL" }
        Details = if ($storage.AllowBlobPublicAccess -eq $false) { "Public blob access disabled" } else { "Public blob access enabled" }
        Severity = "Medium"
    }
    $validationResults += $result
}

# Validate Key Vault Configuration
Write-Host "`nValidating Key Vault Security..." -ForegroundColor Yellow

$keyVaults = Get-AzKeyVault -ResourceGroupName $ResourceGroupName

foreach ($kv in $keyVaults) {
    Write-Host "  Checking Key Vault: $($kv.VaultName)" -ForegroundColor Cyan
    
    # Check soft delete
    $result = @{
        ResourceType = "KeyVault"
        ResourceName = $kv.VaultName
        Rule = "Soft Delete Enabled"
        Status = if ($kv.EnableSoftDelete) { "PASS" } else { "FAIL" }
        Details = if ($kv.EnableSoftDelete) { "Soft delete enabled" } else { "Soft delete disabled" }
        Severity = "High"
    }
    $validationResults += $result
    
    # Check purge protection
    $result = @{
        ResourceType = "KeyVault"
        ResourceName = $kv.VaultName
        Rule = "Purge Protection"
        Status = if ($kv.EnablePurgeProtection) { "PASS" } else { "FAIL" }
        Details = if ($kv.EnablePurgeProtection) { "Purge protection enabled" } else { "Purge protection disabled" }
        Severity = "High"
    }
    $validationResults += $result
}

# Generate compliance report
Write-Host "`nGenerating Compliance Report..." -ForegroundColor Yellow

$passCount = ($validationResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($validationResults | Where-Object { $_.Status -eq "FAIL" }).Count
$criticalFailures = ($validationResults | Where-Object { $_.Status -eq "FAIL" -and $_.Severity -eq "Critical" }).Count
$highFailures = ($validationResults | Where-Object { $_.Status -eq "FAIL" -and $_.Severity -eq "High" }).Count

Write-Host "`nSecurity Compliance Summary:" -ForegroundColor Cyan
Write-Host "  Total Checks: $($validationResults.Count)" -ForegroundColor White
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "  Critical Failures: $criticalFailures" -ForegroundColor Magenta
Write-Host "  High Severity Failures: $highFailures" -ForegroundColor Red

# Display failed checks
if ($failCount -gt 0) {
    Write-Host "`nFailed Compliance Checks:" -ForegroundColor Red
    $validationResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        $color = switch ($_.Severity) {
            "Critical" { "Magenta" }
            "High" { "Red" }
            "Medium" { "Yellow" }
            default { "White" }
        }
        Write-Host "  [$($_.Severity)] $($_.ResourceType)/$($_.ResourceName): $($_.Rule) - $($_.Details)" -ForegroundColor $color
    }
}

# Save detailed results
$outputFile = "compliance-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ResourceGroup = $ResourceGroupName
    Summary = @{
        TotalChecks = $validationResults.Count
        Passed = $passCount
        Failed = $failCount
        CriticalFailures = $criticalFailures
        HighFailures = $highFailures
    }
    Details = $validationResults
}

$report | ConvertTo-Json -Depth 4 | Out-File $outputFile
Write-Host "`nDetailed compliance report saved to: $outputFile" -ForegroundColor Yellow

# Exit with appropriate code
if ($criticalFailures -gt 0) {
    Write-Host "`nCritical security compliance failures detected!" -ForegroundColor Magenta
    exit 2
} elseif ($failCount -gt 0) {
    Write-Host "`nSecurity compliance failures detected!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll security compliance checks passed!" -ForegroundColor Green
    exit 0
}
