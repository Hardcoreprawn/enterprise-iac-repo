# Infrastructure Validation and Monitoring Scripts

Scripts for testing and monitoring enterprise cloud infrastructure to ensure compliance and connectivity.

## Script Purpose

These scripts validate that deployed infrastructure meets enterprise security standards and maintains required connectivity. Each script produces binary pass/fail results with detailed logging for monitoring integration.

## Compliance Testing

### validate-security-compliance.ps1

Validates security configurations against enterprise standards.

**Required Parameters:**

- `ResourceGroupName` - Target resource group for validation

**Optional Parameters:**

- `SubscriptionId` - Azure subscription ID
- `ComplianceConfigFile` - Path to compliance rules (default: compliance-rules.json)

**Validation Checks:**

- Network Security Group rules and default deny policies
- Storage Account encryption and HTTPS enforcement
- Key Vault soft delete and purge protection
- Firewall configuration drift detection

**Usage:**

```powershell
.\validate-security-compliance.ps1 -ResourceGroupName "rg-enterprise-prod"
```

**Exit Codes:**

- 0: All checks passed
- 1: Non-critical failures detected
- 2: Critical security failures detected

### compliance-rules.json

Configuration file defining enterprise security requirements.

**Sections:**

- `requiredPortRules` - Network port access requirements
- `storageAccountRules` - Storage security configurations
- `keyVaultRules` - Key Vault security settings
- `networkSecurityRules` - NSG configuration requirements
- `monitoringRules` - Required logging and alerting
- `complianceThresholds` - Failure tolerance levels

## Connectivity Testing

### test-network-connectivity.ps1

Tests network connectivity between services and validates firewall configurations.

**Required Parameters:**

- `TestConfigFile` - JSON file with connectivity test definitions

**Validation Checks:**

- Port connectivity between services
- DNS resolution validation
- HTTP/HTTPS endpoint accessibility
- Certificate validation for HTTPS endpoints

**Usage:**

```powershell
.\test-network-connectivity.ps1 -TestConfigFile "connectivity-tests.json"
```

### connectivity-tests.json

Configuration file defining required network connectivity paths.

**Test Types:**

- `portTests` - TCP/UDP port connectivity
- `dnsTests` - DNS resolution validation
- `httpTests` - HTTP/HTTPS endpoint testing

## Monitoring Integration

All scripts output JSON results for Log Analytics ingestion:

```json
{
  "Timestamp": "2024-01-15 14:30:00",
  "TestType": "SecurityCompliance",
  "ResourceGroup": "rg-enterprise-prod",
  "Summary": {
    "TotalChecks": 25,
    "Passed": 23,
    "Failed": 2,
    "CriticalFailures": 0
  },
  "Details": [...]
}
```

## CI/CD Integration

These scripts integrate with Azure DevOps pipelines for:

1. **Pre-deployment validation** - Check configurations before applying changes
2. **Post-deployment testing** - Validate infrastructure after deployment
3. **Continuous monitoring** - Regular compliance and connectivity checks
4. **Drift detection** - Alert on configuration changes

## Alert Configuration

Failed tests trigger monitoring alerts based on severity:

- **Critical failures** - Immediate escalation to security team
- **High failures** - Alert infrastructure team within 15 minutes
- **Medium failures** - Daily summary report

## Maintenance

Update compliance rules and connectivity tests when:

- New services are deployed
- Firewall rules are modified
- Security requirements change
- New monitoring requirements are added

## Test Results

All test results are:

- **Logged** to centralized monitoring
- **Alerted** on failures
- **Tracked** for trends and analysis
- **Reported** in compliance dashboards

## Test Development

When adding new infrastructure:

1. **Define connectivity requirements** - What needs to talk to what
2. **Create specific tests** - Test actual network paths and ports
3. **Add compliance checks** - Validate against enterprise standards
4. **Set up monitoring** - Continuous validation of connectivity
5. **Document expected behavior** - Clear test criteria and expected results
