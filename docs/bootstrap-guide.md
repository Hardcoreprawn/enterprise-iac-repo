# Bootstrap Guide

Getting from zero to automated Azure DevOps infrastructure

## Overview

This guide covers the automated bootstrap process using our enterprise IaC toolkit. The bootstrap script handles the
"chicken-and-egg" problem: Terraform needs state storage and permissions, but those require Terraform to create.

## Prerequisites

- Azure subscription with Global Admin or equivalent permissions
- Azure CLI installed and authenticated (`az login`)
- PowerShell 7+ (included in DevContainer)
- Enterprise IaC toolkit repository cloned and opened in DevContainer

## Automated Bootstrap Process

### Step 1: Configure Bootstrap Settings

Edit `bootstrap-config.json` with your organization details:

```json
{
  "organization": {
    "prefix": "yourorg",        // 2-10 lowercase alphanumeric
    "location": "eastus",
    "environment": "dev"
  },
  "azure": {
    "subscription_id": "your-subscription-id",
    "tenant_id": "your-tenant-id"
  },
  "devops": {
    "organization_url": "https://dev.azure.com/yourorg",
    "project_name": "Enterprise Infrastructure"
  },
  "features": {
    "create_key_vault": true,
    "enable_private_endpoints": false,
    "configure_monitoring": true
  }
}
```

### Step 2: Authenticate to Azure

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

### Step 3: Preview Bootstrap Changes

```bash
# Preview what will be created (recommended first step)
make bootstrap-whatif
```

### Step 4: Execute Bootstrap

```bash
# Create the actual infrastructure
make bootstrap
```

The bootstrap script will create:

- Resource group for Terraform state storage
- Storage account with secure configuration
- Storage container for state files
- Service principal for Terraform automation
- Proper RBAC assignments

### Step 5: Configure Environment Variables

After successful bootstrap, set the environment variables for Terraform:

```bash
# Set these from the bootstrap script output
export ARM_CLIENT_ID="service-principal-app-id"
export ARM_CLIENT_SECRET="service-principal-password"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

## Phase 2: Terraform Foundation

### Manual Backend Configuration

After bootstrap, configure your Terraform backend using the outputs:

Create `terraform/environments/bootstrap/backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-yourorg-terraform-state"  # From bootstrap output
    storage_account_name = "yourorgtfstate1234"          # From bootstrap output
    container_name       = "terraform-state"
    key                  = "bootstrap.tfstate"
  }
}
```

### Deploy Terraform Modules

```bash
cd terraform/environments/bootstrap
terraform init
terraform plan -target=module.entra_groups
terraform apply -target=module.entra_groups
```

### Deploy Azure Bootstrap Module

```bash
terraform plan -target=module.azure_bootstrap  
terraform apply -target=module.azure_bootstrap
```

### Deploy Azure DevOps Project

```bash
terraform plan -target=module.azure_devops_project
terraform apply -target=module.azure_devops_project
```

## Phase 3: Pipeline Enablement

### Step 1: Configure Service Connections

Use outputs from Terraform to configure Azure DevOps service connections:

```bash
# Get service principal details from Terraform output
terraform output azure_devops_service_principals
```

### Step 2: Import Pipeline Templates

```bash
# Import pipeline templates to Azure DevOps
# This will be automated in future versions
```

## Troubleshooting

### Common Issues

**Terraform Backend Authentication Fails:**

- Verify ARM_* environment variables are set correctly
- Check service principal has Storage Blob Data Contributor on state storage account

**Insufficient Permissions:**

- Bootstrap service principal needs Owner role at subscription level
- For Entra ID operations, needs Application Administrator or Global Admin

**State Lock Issues:**

- Check for existing locks: `az storage blob list --container-name terraform-state`
- Manual unlock if needed: delete the `.tflock` blob

### Recovery Procedures

**Lost Service Principal Credentials:**

1. Reset credentials: `az ad sp credential reset --id <app-id>`
2. Update ARM_CLIENT_SECRET environment variable
3. Update any stored secrets in Key Vault

**Corrupted Terraform State:**

1. Backup current state: `terraform state pull > backup.tfstate`
2. Import existing resources: `terraform import <resource> <azure-resource-id>`
3. Verify with `terraform plan`

## Security Considerations

- **Service Principal Rotation**: Bootstrap SP should be rotated regularly
- **State File Encryption**: Enable encryption at rest for storage account
- **Access Logging**: Enable diagnostics on state storage account
- **Least Privilege**: Remove Owner role from bootstrap SP after initial setup

## Next Steps

After successful bootstrap:

1. Review outputs and validate all resources created correctly
2. Test pipeline deployment using created service connections
3. Begin deploying enterprise modules (landing zones, IPAM, etc.)
4. Document any organization-specific customizations needed

## Reference

- **Related ADRs**: ADR-002 (Module Architecture)
- **Dependencies**: Requires completion before any other module deployment
- **Outputs**: Service principals, Key Vault, DevOps project ready for automation
