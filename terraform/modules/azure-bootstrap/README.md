# Azure Bootstrap Module

Creates secure Azure infrastructure for Terraform remote state management with enterprise-grade security features.

## Purpose

This module creates the foundational infrastructure needed to migrate from local Terraform state to secure remote  
state storage in Azure. It follows enterprise security best practices and enables centralized state management for  
the platform automation.

## Resources Created

- **Resource Group**: Dedicated group for Terraform state management
- **Storage Account**: Zone-redundant storage with enterprise security features
- **Storage Container**: Private container for state files
- **RBAC Assignments**: Service principal permissions for state access
- **Diagnostic Logging**: Complete audit trail of state access
- **Private Endpoint**: Optional network isolation (when enabled)

## Security Features

### Storage Account Security

- **HTTPS Only**: All traffic encrypted in transit
- **TLS 1.2 Minimum**: Modern encryption standards
- **OAuth Authentication**: Azure AD-based access control
- **No Public Blob Access**: Prevents accidental exposure
- **Shared Access Keys Disabled**: Forces RBAC-based access

### Data Protection

- **Blob Versioning**: Track all state file changes
- **Soft Delete**: 30-day recovery window for deleted blobs
- **Change Feed**: Audit log of all blob operations
- **Point-in-Time Restore**: 6-day restoration capability
- **Zone-Redundant Storage**: High availability across zones

### Access Control

- **Service Principal RBAC**: Least privilege access
- **Diagnostic Logging**: Complete audit trail
- **Private Endpoint Support**: Network isolation option

## Usage

### Basic Configuration

```hcl
module "azure_bootstrap" {
  source = "./modules/azure-bootstrap"
  
  organization_prefix        = "contoso"
  environment               = "prod"
  location                  = "eastus"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  service_principal_object_ids = {
    devops_automation     = module.entra_groups.service_principal_object_ids["devops_automation"]
    landing_zone_deploy   = module.entra_groups.service_principal_object_ids["landing_zone_deploy"]
    subscription_vending  = module.entra_groups.service_principal_object_ids["subscription_vending"]
  }
  
  common_tags = {
    Organization = "contoso"
    Environment  = "prod"
    ManagedBy    = "Terraform"
    Purpose      = "PlatformAutomation"
  }
}
```

### With Private Endpoint

```hcl
module "azure_bootstrap" {
  source = "./modules/azure-bootstrap"
  
  # ... basic configuration ...
  
  enable_private_endpoint     = true
  private_endpoint_subnet_id  = azurerm_subnet.private_endpoints.id
  enable_public_access        = false
}
```

## State Migration Process

After creating the bootstrap infrastructure:

### 1. Get Backend Configuration

```bash
terraform output -raw backend_config_template
```

### 2. Add Backend Configuration

Add the output to your main Terraform configuration:

```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "stcontosoterraformstate12345"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

### 3. Initialize Remote State

```bash
# Authenticate with Azure
az login

# Initialize with new backend
terraform init -migrate-state

# Confirm migration when prompted
```

### 4. Verify Migration

```bash
# Plan should show no changes
terraform plan

# Validate state is stored remotely
az storage blob list --container-name tfstate --account-name <storage-account>
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| organization_prefix | Organization prefix for resource naming | string | - | yes |
| location | Azure region for resources | string | eastus | no |
| environment | Environment (dev, test, prod) | string | - | yes |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostic logging | string | - | yes |
| service_principal_object_ids | Map of service principal object IDs that need access | map(string) | {} | no |
| enable_public_access | Enable public network access to storage account | bool | true | no |
| enable_private_endpoint | Create private endpoint for storage account | bool | false | no |
| private_endpoint_subnet_id | Subnet ID for private endpoint | string | null | no |
| enable_versioning | Enable versioning on the storage account | bool | true | no |
| retention_days | Number of days to retain deleted blobs | number | 30 | no |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_name | Name of the Terraform state storage account |
| storage_account_id | ID of the Terraform state storage account |
| storage_container_name | Name of the Terraform state storage container |
| resource_group_name | Name of the Terraform state resource group |
| backend_config | Backend configuration for Terraform remote state |
| backend_config_template | Template for Terraform backend configuration block |

## Enterprise Considerations

### Subscription Strategy

This module should be deployed in your management subscription as outlined in the subscription strategy:

- Creates isolated infrastructure for platform automation
- Centralizes state management across all environments
- Enables proper RBAC and auditing for infrastructure changes

### Backup and Recovery

- **State File Versioning**: Every change creates a new version
- **Soft Delete Protection**: 30-day recovery window
- **Point-in-Time Restore**: Restore to any point in the last 6 days
- **Zone Redundancy**: Automatic replication across availability zones

### Compliance and Auditing

- **Complete Audit Trail**: All access logged to Log Analytics
- **Change Tracking**: Change feed captures all modifications
- **Access Control**: RBAC-based permissions only
- **Network Security**: Optional private endpoint isolation

## Dependencies

- Azure Provider ~> 3.0
- Random Provider ~> 3.6
- Existing Log Analytics workspace
- Service principal object IDs (typically from entra-groups module)

## Related Documentation

- [Subscription Strategy](../../../docs/subscription-strategy.md)
- [Terraform State Migration Guide](../../../docs/terraform-state-migration.md)
- [Enterprise Security Standards](../../../docs/standards/)
