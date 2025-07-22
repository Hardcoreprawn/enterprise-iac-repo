# Network Connectivity Testing

# Test network connectivity between infrastructure components
# Validates that services can communicate as designed and no unauthorized ports are open

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$TestConfigFile = "connectivity-tests.json"
)

Write-Host "Starting network connectivity tests for Resource Group: $ResourceGroupName" -ForegroundColor Green

# Load test configuration
if (-not (Test-Path $TestConfigFile)) {
    Write-Error "Test configuration file not found: $TestConfigFile"
    exit 1
}

$testConfig = Get-Content $TestConfigFile | ConvertFrom-Json
$testResults = @()

foreach ($test in $testConfig.connectivityTests) {
    Write-Host "Testing connectivity: $($test.name)" -ForegroundColor Yellow
    
    $result = @{
        TestName = $test.name
        Source = $test.source
        Destination = $test.destination
        Port = $test.port
        Protocol = $test.protocol
        Expected = $test.expected
        Actual = $null
        Status = "Unknown"
        Details = ""
    }
    
    try {
        switch ($test.testType) {
            "port" {
                # Test specific port connectivity
                $tcpTest = Test-NetConnection -ComputerName $test.destination -Port $test.port -WarningAction SilentlyContinue
                $result.Actual = $tcpTest.TcpTestSucceeded
                $result.Status = if ($result.Actual -eq $test.expected) { "PASS" } else { "FAIL" }
                $result.Details = "TCP connection test to $($test.destination):$($test.port)"
            }
            
            "ping" {
                # Test basic network connectivity
                $pingTest = Test-Connection -ComputerName $test.destination -Count 1 -Quiet
                $result.Actual = $pingTest
                $result.Status = if ($result.Actual -eq $test.expected) { "PASS" } else { "FAIL" }
                $result.Details = "ICMP ping test to $($test.destination)"
            }
            
            "dns" {
                # Test DNS resolution
                try {
                    $dnsTest = Resolve-DnsName -Name $test.destination -ErrorAction Stop
                    $result.Actual = $true
                    $result.Details = "DNS resolution successful: $($dnsTest.IPAddress -join ', ')"
                } catch {
                    $result.Actual = $false
                    $result.Details = "DNS resolution failed: $($_.Exception.Message)"
                }
                $result.Status = if ($result.Actual -eq $test.expected) { "PASS" } else { "FAIL" }
            }
            
            "http" {
                # Test HTTP/HTTPS endpoint
                try {
                    $httpTest = Invoke-WebRequest -Uri "http://$($test.destination):$($test.port)" -TimeoutSec 10 -UseBasicParsing
                    $result.Actual = $httpTest.StatusCode -eq 200
                    $result.Details = "HTTP response: $($httpTest.StatusCode)"
                } catch {
                    $result.Actual = $false
                    $result.Details = "HTTP request failed: $($_.Exception.Message)"
                }
                $result.Status = if ($result.Actual -eq $test.expected) { "PASS" } else { "FAIL" }
            }
        }
    } catch {
        $result.Status = "ERROR"
        $result.Details = "Test execution failed: $($_.Exception.Message)"
    }
    
    $testResults += $result
    
    # Output test result
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "ERROR" { "Magenta" }
        default { "Yellow" }
    }
    
    Write-Host "  Result: $($result.Status) - $($result.Details)" -ForegroundColor $color
}

# Generate summary report
$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$errorCount = ($testResults | Where-Object { $_.Status -eq "ERROR" }).Count
$totalCount = $testResults.Count

Write-Host "`nConnectivity Test Summary:" -ForegroundColor Cyan
Write-Host "  Total Tests: $totalCount" -ForegroundColor White
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "  Errors: $errorCount" -ForegroundColor Magenta

# Save detailed results to JSON
$outputFile = "connectivity-test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 3 | Out-File $outputFile
Write-Host "`nDetailed results saved to: $outputFile" -ForegroundColor Yellow

# Send results to monitoring system (Log Analytics)
if ($testConfig.monitoring.enabled) {
    Write-Host "Sending results to monitoring system..." -ForegroundColor Yellow
    
    # TODO: Send to Log Analytics workspace
    # This would integrate with Azure Monitor to track connectivity over time
}

# Exit with appropriate code
if ($failCount -gt 0 -or $errorCount -gt 0) {
    Write-Host "`nConnectivity tests completed with failures!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll connectivity tests passed!" -ForegroundColor Green
    exit 0
}
