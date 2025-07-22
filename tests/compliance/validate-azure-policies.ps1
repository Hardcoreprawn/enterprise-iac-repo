# Azure Policy Validation Script

# Validates Azure Policy compliance for resources in a subscription or resource group
# Checks policy assignments, compliance state, and generates remediation reports

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$PolicySetName,
    
    [Parameter(Mandatory=$false)]
    [switch]$RemediateNonCompliant = $false
)

Write-Host "Starting Azure Policy compliance validation" -ForegroundColor Green

# Set subscription context if provided
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
    Write-Host "Using subscription: $SubscriptionId" -ForegroundColor Cyan
}

$results = @()
$currentTime = Get-Date

# Get policy assignments
Write-Host "`nRetrieving policy assignments..." -ForegroundColor Yellow

if ($ResourceGroupName) {
    $scope = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroupName"
    Write-Host "Checking resource group scope: $ResourceGroupName" -ForegroundColor Cyan
} else {
    $scope = "/subscriptions/$((Get-AzContext).Subscription.Id)"
    Write-Host "Checking subscription scope" -ForegroundColor Cyan
}

$policyAssignments = Get-AzPolicyAssignment -Scope $scope

if ($PolicySetName) {
    $policyAssignments = $policyAssignments | Where-Object { $_.Properties.DisplayName -like "*$PolicySetName*" }
}

Write-Host "Found $($policyAssignments.Count) policy assignments" -ForegroundColor White

# Check compliance for each assignment
foreach ($assignment in $policyAssignments) {
    Write-Host "`nChecking compliance for: $($assignment.Properties.DisplayName)" -ForegroundColor Cyan
    
    # Get compliance summary
    $complianceStates = Get-AzPolicyState -PolicyAssignmentName $assignment.Name -Top 1000
    
    $compliantCount = ($complianceStates | Where-Object { $_.ComplianceState -eq "Compliant" }).Count
    $nonCompliantCount = ($complianceStates | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
    $totalResources = $complianceStates.Count
    
    $compliancePercentage = if ($totalResources -gt 0) { 
        [math]::Round(($compliantCount / $totalResources) * 100, 2) 
    } else { 
        100 
    }
    
    $result = @{
        PolicyAssignment = $assignment.Properties.DisplayName
        PolicyDefinition = $assignment.Properties.PolicyDefinitionId
        Scope = $assignment.Properties.Scope
        TotalResources = $totalResources
        CompliantResources = $compliantCount
        NonCompliantResources = $nonCompliantCount
        CompliancePercentage = $compliancePercentage
        Status = if ($nonCompliantCount -eq 0) { "COMPLIANT" } else { "NON_COMPLIANT" }
        LastEvaluated = $currentTime
    }
    
    $results += $result
    
    # Display summary
    $statusColor = if ($result.Status -eq "COMPLIANT") { "Green" } else { "Red" }
    Write-Host "  Status: $($result.Status)" -ForegroundColor $statusColor
    Write-Host "  Compliance: $($result.CompliancePercentage)% ($compliantCount/$totalResources)" -ForegroundColor White
    
    # Show non-compliant resources
    if ($nonCompliantCount -gt 0) {
        Write-Host "  Non-compliant resources:" -ForegroundColor Yellow
        $nonCompliantResources = $complianceStates | Where-Object { $_.ComplianceState -eq "NonCompliant" } | Select-Object -First 10
        
        foreach ($resource in $nonCompliantResources) {
            Write-Host "    - $($resource.ResourceId) ($($resource.PolicyDefinitionReferenceId))" -ForegroundColor Red
        }
        
        if ($nonCompliantCount -gt 10) {
            Write-Host "    ... and $($nonCompliantCount - 10) more resources" -ForegroundColor Red
        }
        
        # Remediation option
        if ($RemediateNonCompliant) {
            Write-Host "  Attempting remediation..." -ForegroundColor Magenta
            
            try {
                $remediationName = "remediation-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                $remediation = Start-AzPolicyRemediation -Name $remediationName -PolicyAssignmentId $assignment.ResourceId -ResourceDiscoveryMode ReEvaluateCompliance
                
                Write-Host "    Remediation task created: $($remediation.Name)" -ForegroundColor Green
                Write-Host "    Task ID: $($remediation.ResourceId)" -ForegroundColor White
            }
            catch {
                Write-Host "    Remediation failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Generate compliance summary
Write-Host "`nPolicy Compliance Summary:" -ForegroundColor Cyan

$totalPolicies = $results.Count
$compliantPolicies = ($results | Where-Object { $_.Status -eq "COMPLIANT" }).Count
$nonCompliantPolicies = $totalPolicies - $compliantPolicies

$totalResourcesAll = ($results | Measure-Object -Property TotalResources -Sum).Sum
$compliantResourcesAll = ($results | Measure-Object -Property CompliantResources -Sum).Sum
$nonCompliantResourcesAll = ($results | Measure-Object -Property NonCompliantResources -Sum).Sum

$overallCompliance = if ($totalResourcesAll -gt 0) { 
    [math]::Round(($compliantResourcesAll / $totalResourcesAll) * 100, 2) 
} else { 
    100 
}

Write-Host "  Policy Assignments: $totalPolicies" -ForegroundColor White
Write-Host "  Compliant Policies: $compliantPolicies" -ForegroundColor Green
Write-Host "  Non-compliant Policies: $nonCompliantPolicies" -ForegroundColor Red
Write-Host "  Total Resources Evaluated: $totalResourcesAll" -ForegroundColor White
Write-Host "  Overall Compliance: $overallCompliance%" -ForegroundColor $(if ($overallCompliance -ge 95) { "Green" } elseif ($overallCompliance -ge 80) { "Yellow" } else { "Red" })

# Display policy recommendations
Write-Host "`nPolicy Recommendations:" -ForegroundColor Yellow

if ($overallCompliance -lt 95) {
    Write-Host "  • Review non-compliant resources and remediate issues" -ForegroundColor White
    Write-Host "  • Consider automatic remediation for supported policies" -ForegroundColor White
    Write-Host "  • Update resource configurations to meet policy requirements" -ForegroundColor White
}

if ($nonCompliantPolicies -gt 0) {
    Write-Host "  • Focus on policies with highest non-compliance rates" -ForegroundColor White
    Write-Host "  • Review policy definitions for clarity and accuracy" -ForegroundColor White
}

# Save detailed report
$outputFile = "policy-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report = @{
    Timestamp = $currentTime.ToString("yyyy-MM-dd HH:mm:ss")
    Scope = $scope
    Summary = @{
        TotalPolicies = $totalPolicies
        CompliantPolicies = $compliantPolicies
        NonCompliantPolicies = $nonCompliantPolicies
        TotalResources = $totalResourcesAll
        CompliantResources = $compliantResourcesAll
        NonCompliantResources = $nonCompliantResourcesAll
        OverallCompliance = $overallCompliance
    }
    PolicyResults = $results
    Recommendations = @(
        "Review and remediate non-compliant resources",
        "Enable automatic remediation where appropriate",
        "Regular policy compliance monitoring"
    )
}

$report | ConvertTo-Json -Depth 4 | Out-File $outputFile
Write-Host "`nDetailed policy compliance report saved to: $outputFile" -ForegroundColor Yellow

# Exit with appropriate code based on compliance
if ($overallCompliance -lt 80) {
    Write-Host "`nCritical policy compliance issues detected!" -ForegroundColor Magenta
    exit 2
} elseif ($nonCompliantPolicies -gt 0) {
    Write-Host "`nPolicy compliance issues detected!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll policies are compliant!" -ForegroundColor Green
    exit 0
}
