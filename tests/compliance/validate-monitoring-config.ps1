# Monitoring Configuration Validation

# Validates that monitoring and alerting configurations meet enterprise standards
# Checks Log Analytics workspaces, Application Insights, alert rules, and diagnostic settings

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$MonitoringConfigFile = "monitoring-requirements.json"
)

Write-Host "Starting monitoring configuration validation for Resource Group: $ResourceGroupName" -ForegroundColor Green

# Load monitoring requirements
if (-not (Test-Path $MonitoringConfigFile)) {
    Write-Error "Monitoring configuration file not found: $MonitoringConfigFile"
    exit 1
}

$monitoringConfig = Get-Content $MonitoringConfigFile | ConvertFrom-Json
$validationResults = @()

# Validate Log Analytics Workspaces
Write-Host "`nValidating Log Analytics Workspaces..." -ForegroundColor Yellow

$logWorkspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName

foreach ($workspace in $logWorkspaces) {
    Write-Host "  Checking workspace: $($workspace.Name)" -ForegroundColor Cyan
    
    # Check retention period
    $retentionResult = @{
        ResourceType = "LogAnalyticsWorkspace"
        ResourceName = $workspace.Name
        Rule = "Data Retention Period"
        Status = if ($workspace.retentionInDays -ge $monitoringConfig.logAnalytics.minimumRetentionDays) { "PASS" } else { "FAIL" }
        Details = "Retention: $($workspace.retentionInDays) days (minimum: $($monitoringConfig.logAnalytics.minimumRetentionDays))"
        Severity = "High"
    }
    $validationResults += $retentionResult
    
    # Check if workspace is collecting required data types
    $dataTypes = Get-AzOperationalInsightsDataSource -WorkspaceName $workspace.Name -ResourceGroupName $ResourceGroupName
    
    foreach ($requiredType in $monitoringConfig.logAnalytics.requiredDataSources) {
        $hasDataType = $dataTypes | Where-Object { $_.Kind -eq $requiredType }
        
        $result = @{
            ResourceType = "LogAnalyticsWorkspace"
            ResourceName = $workspace.Name
            Rule = "Required Data Source: $requiredType"
            Status = if ($hasDataType) { "PASS" } else { "FAIL" }
            Details = if ($hasDataType) { "Data source configured" } else { "Data source missing" }
            Severity = "Medium"
        }
        $validationResults += $result
    }
}

# Validate Application Insights
Write-Host "`nValidating Application Insights..." -ForegroundColor Yellow

$appInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName

foreach ($ai in $appInsights) {
    Write-Host "  Checking Application Insights: $($ai.Name)" -ForegroundColor Cyan
    
    # Check sampling configuration
    $samplingResult = @{
        ResourceType = "ApplicationInsights"
        ResourceName = $ai.Name
        Rule = "Sampling Configuration"
        Status = if ($ai.SamplingPercentage -ge $monitoringConfig.applicationInsights.minimumSamplingPercentage) { "PASS" } else { "FAIL" }
        Details = "Sampling: $($ai.SamplingPercentage)% (minimum: $($monitoringConfig.applicationInsights.minimumSamplingPercentage)%)"
        Severity = "Medium"
    }
    $validationResults += $samplingResult
    
    # Check data retention
    $retentionResult = @{
        ResourceType = "ApplicationInsights"
        ResourceName = $ai.Name
        Rule = "Data Retention"
        Status = if ($ai.RetentionInDays -ge $monitoringConfig.applicationInsights.minimumRetentionDays) { "PASS" } else { "FAIL" }
        Details = "Retention: $($ai.RetentionInDays) days (minimum: $($monitoringConfig.applicationInsights.minimumRetentionDays))"
        Severity = "High"
    }
    $validationResults += $retentionResult
}

# Validate Alert Rules
Write-Host "`nValidating Alert Rules..." -ForegroundColor Yellow

$alertRules = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroupName

$requiredAlerts = $monitoringConfig.alertRules.requiredAlerts

foreach ($requiredAlert in $requiredAlerts) {
    $matchingAlert = $alertRules | Where-Object { 
        $_.Name -like "*$($requiredAlert.name)*" -or 
        $_.Description -like "*$($requiredAlert.description)*"
    }
    
    $result = @{
        ResourceType = "AlertRule"
        ResourceName = $requiredAlert.name
        Rule = "Required Alert: $($requiredAlert.name)"
        Status = if ($matchingAlert) { "PASS" } else { "FAIL" }
        Details = if ($matchingAlert) { "Alert rule configured" } else { "Alert rule missing" }
        Severity = $requiredAlert.severity
    }
    $validationResults += $result
    
    # If alert exists, check its configuration
    if ($matchingAlert) {
        # Check if alert is enabled
        $enabledResult = @{
            ResourceType = "AlertRule"
            ResourceName = $matchingAlert.Name
            Rule = "Alert Enabled"
            Status = if ($matchingAlert.Enabled) { "PASS" } else { "FAIL" }
            Details = if ($matchingAlert.Enabled) { "Alert is enabled" } else { "Alert is disabled" }
            Severity = "High"
        }
        $validationResults += $enabledResult
        
        # Check evaluation frequency
        $frequencyResult = @{
            ResourceType = "AlertRule"
            ResourceName = $matchingAlert.Name
            Rule = "Evaluation Frequency"
            Status = if ($matchingAlert.EvaluationFrequency -le $requiredAlert.maxEvaluationFrequency) { "PASS" } else { "FAIL" }
            Details = "Frequency: $($matchingAlert.EvaluationFrequency) (max: $($requiredAlert.maxEvaluationFrequency))"
            Severity = "Medium"
        }
        $validationResults += $frequencyResult
    }
}

# Validate Diagnostic Settings
Write-Host "`nValidating Diagnostic Settings..." -ForegroundColor Yellow

$resources = Get-AzResource -ResourceGroupName $ResourceGroupName

foreach ($resource in $resources) {
    # Skip certain resource types that don't support diagnostic settings
    $skipTypes = @("Microsoft.Insights/components", "Microsoft.OperationalInsights/workspaces")
    if ($resource.ResourceType -in $skipTypes) {
        continue
    }
    
    Write-Host "  Checking diagnostic settings for: $($resource.Name)" -ForegroundColor Cyan
    
    try {
        $diagnosticSettings = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
        
        $result = @{
            ResourceType = $resource.ResourceType
            ResourceName = $resource.Name
            Rule = "Diagnostic Settings Configured"
            Status = if ($diagnosticSettings) { "PASS" } else { "FAIL" }
            Details = if ($diagnosticSettings) { "Diagnostic settings found" } else { "No diagnostic settings configured" }
            Severity = "High"
        }
        $validationResults += $result
        
        # If diagnostic settings exist, check configuration
        if ($diagnosticSettings) {
            foreach ($setting in $diagnosticSettings) {
                # Check if logs are being sent to Log Analytics
                $logAnalyticsResult = @{
                    ResourceType = $resource.ResourceType
                    ResourceName = $resource.Name
                    Rule = "Logs to Log Analytics"
                    Status = if ($setting.WorkspaceId) { "PASS" } else { "FAIL" }
                    Details = if ($setting.WorkspaceId) { "Logs sent to Log Analytics" } else { "Logs not sent to Log Analytics" }
                    Severity = "High"
                }
                $validationResults += $logAnalyticsResult
                
                # Check if required log categories are enabled
                foreach ($requiredCategory in $monitoringConfig.diagnosticSettings.requiredLogCategories) {
                    $categoryEnabled = $setting.Logs | Where-Object { 
                        $_.Category -eq $requiredCategory -and $_.Enabled 
                    }
                    
                    $categoryResult = @{
                        ResourceType = $resource.ResourceType
                        ResourceName = $resource.Name
                        Rule = "Log Category: $requiredCategory"
                        Status = if ($categoryEnabled) { "PASS" } else { "FAIL" }
                        Details = if ($categoryEnabled) { "Category enabled" } else { "Category not enabled" }
                        Severity = "Medium"
                    }
                    $validationResults += $categoryResult
                }
            }
        }
    }
    catch {
        # Resource doesn't support diagnostic settings
        continue
    }
}

# Generate monitoring validation summary
Write-Host "`nMonitoring Configuration Summary:" -ForegroundColor Cyan

$passCount = ($validationResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($validationResults | Where-Object { $_.Status -eq "FAIL" }).Count
$criticalFailures = ($validationResults | Where-Object { $_.Status -eq "FAIL" -and $_.Severity -eq "Critical" }).Count
$highFailures = ($validationResults | Where-Object { $_.Status -eq "FAIL" -and $_.Severity -eq "High" }).Count

Write-Host "  Total Checks: $($validationResults.Count)" -ForegroundColor White
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "  Critical Failures: $criticalFailures" -ForegroundColor Magenta
Write-Host "  High Severity Failures: $highFailures" -ForegroundColor Red

# Display failed checks
if ($failCount -gt 0) {
    Write-Host "`nFailed Monitoring Checks:" -ForegroundColor Red
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
$outputFile = "monitoring-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
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
Write-Host "`nDetailed monitoring validation report saved to: $outputFile" -ForegroundColor Yellow

# Exit with appropriate code
if ($criticalFailures -gt 0) {
    Write-Host "`nCritical monitoring configuration failures detected!" -ForegroundColor Magenta
    exit 2
} elseif ($failCount -gt 0) {
    Write-Host "`nMonitoring configuration failures detected!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll monitoring configuration checks passed!" -ForegroundColor Green
    exit 0
}
