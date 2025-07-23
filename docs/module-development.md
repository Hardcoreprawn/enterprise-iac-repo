# Module Development Guide

How to create and maintain Terraform modules in the enterprise IaC toolkit

## Module Standards

### Directory Structure

```text
terraform/modules/[module-name]/
├── README.md              # Module documentation
├── main.tf                # Primary resource definitions
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Provider version constraints
├── examples/             # Usage examples
│   └── basic/           # Basic usage example
│       ├── main.tf
│       ├── variables.tf
│       └── README.md
└── tests/               # Module-specific tests
    └── integration_test.go
```

### Naming Conventions

**Resources**: `{organization_prefix}-{purpose}-{environment}`

- Example: `contoso-devops-prod`
- Configurable via `var.organization_prefix`

**Files**: Use lowercase with underscores

- Good: `azure_devops_project`, `service_principal`
- Avoid: `AzureDevOpsProject`, `servicePrincipal`

## Module Template

### main.tf

```hcl
# Configure required providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.5"
}

# Example resource with proper naming
resource "azurerm_resource_group" "main" {
  name     = "${var.organization_prefix}-${var.purpose}-${var.environment}"
  location = var.location

  tags = merge(var.default_tags, {
    Purpose = var.purpose
    Module  = "example-module"
  })
}
```

### variables.tf

```hcl
variable "organization_prefix" {
  description = "Prefix for all resources to ensure uniqueness across organizations"
  type        = string
  validation {
    condition     = length(var.organization_prefix) >= 2 && length(var.organization_prefix) <= 10
    error_message = "Organization prefix must be between 2 and 10 characters."
  }
}

variable "purpose" {
  description = "Purpose of the resources (e.g., 'devops', 'landing-zone')"
  type        = string
}

variable "environment" {
  description = "Environment designation (e.g., 'prod', 'dev', 'test')"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Source    = "enterprise-iac-toolkit"
  }
}
```

### outputs.tf

```hcl
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

# Sensitive outputs for service principals, connection strings, etc.
output "service_principal_secret" {
  description = "Secret for the service principal"
  value       = azuread_service_principal_password.main.value
  sensitive   = true
}
```

### versions.tf

```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.10"
    }
  }
}
```

## Module Documentation

### README.md Template

```markdown
# [Module Name]

Brief description of what this module creates and why.

## Usage

\```hcl
module "example" {
  source = "../../modules/example-module"

  organization_prefix = "contoso"
  purpose            = "devops"
  environment        = "prod"
  location           = "East US"
}
\```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| azurerm | ~> 3.0 |
| azuread | ~> 2.0 |

## Providers

List of providers used by this module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization_prefix | Organization prefix for naming | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Name of the created resource group |

## Examples

See the [examples](./examples/) directory for usage examples.
```

## Testing Strategy

### Integration Tests

Create `tests/integration_test.go`:

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestModuleIntegration(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
        Vars: map[string]interface{}{
            "organization_prefix": "test",
            "purpose":            "integration",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
    assert.Contains(t, resourceGroupName, "test-integration")
}
```

### Validation Tests

Use our existing validation framework:

```bash
# Test module with validation framework
make validate-module MODULE=azure-devops-project
```

## Enterprise Standards Compliance

### Required Features

All modules must include:

**Security:**

- RBAC with least privilege principles
- Encryption at rest and in transit
- Network security groups (where applicable)
- Integration with Azure Policy

**Monitoring:**

- Diagnostic settings for all resources
- Integration with centralized logging
- Health check endpoints (where applicable)

**Operations:**

- Proper tagging strategy
- Backup configuration (where applicable)
- Auto-scaling policies (where applicable)

**Governance:**

- Resource naming standards
- Cost management tags
- Policy compliance validation

### Example Security Implementation

```hcl
# Example: Proper RBAC setup
resource "azurerm_role_assignment" "contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = var.service_principal_object_id
}

# Example: Enable diagnostics
resource "azurerm_monitor_diagnostic_setting" "main" {
  name               = "${var.organization_prefix}-${var.purpose}-diagnostics"
  target_resource_id = azurerm_resource_group.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Administrative"
  }

  metric {
    category = "AllMetrics"
  }
}
```

## Module Release Process

### Version Control

1. **Feature Branch**: Create branch for new module or changes
2. **Testing**: Run integration tests and validation
3. **Documentation**: Update README and examples
4. **Pull Request**: Submit for review
5. **Tagging**: Tag stable releases with semantic versioning

### Breaking Changes

- Document breaking changes in CHANGELOG.md
- Provide migration guidance
- Maintain backward compatibility when possible
- Use semantic versioning to indicate breaking changes

## Common Patterns

### Conditional Resources

```hcl
resource "azurerm_key_vault" "main" {
  count = var.create_key_vault ? 1 : 0
  
  name                = "${var.organization_prefix}-${var.purpose}-kv"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  
  # ... rest of configuration
}
```

### Dynamic Blocks

```hcl
resource "azurerm_network_security_group" "main" {
  name                = "${var.organization_prefix}-${var.purpose}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
```

## Troubleshooting

### Common Issues

**Provider Authentication:**

- Ensure ARM_* environment variables are set
- Check service principal permissions
- Verify subscription access

**State Management:**

- Use remote state for all modules
- Avoid state conflicts with proper key naming
- Regular state backup procedures

**Resource Naming Conflicts:**

- Use organization prefix consistently
- Include randomization for globally unique names
- Validate naming conventions in variables

### Debug Commands

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform plan

# Validate module syntax
terraform validate

# Check formatting
terraform fmt -check -recursive

# Security scanning
checkov --directory terraform/modules/
```

## Reference

- **Related ADRs**: ADR-002 (Module Architecture), ADR-003 (Information Architecture)
- **Standards**: See [Definition of Done](standards/cloud-infrastructure-definition-of-done.md)
- **Examples**: Check `terraform/modules/*/examples/` directories
