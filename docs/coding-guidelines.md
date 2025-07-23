# Coding Guidelines

Enterprise Infrastructure as Code - Development Standards

## Principles

### 1. Idempotent Operations

Everything must be safely re-runnable

```bash
# Good: Check if exists before creating
if ! az group show --name "rg-$PREFIX-terraform-state" 2>/dev/null; then
    az group create --name "rg-$PREFIX-terraform-state" --location $LOCATION
fi

# Bad: Always tries to create
az group create --name "rg-$PREFIX-terraform-state" --location $LOCATION
```

### 2. Variables-First Design

All configuration through variables, no hardcoded values

```hcl
# Good: Configurable
variable "organization_prefix" { 
  description = "Organization prefix for naming"
  type        = string
}

# Bad: Hardcoded
resource "azurerm_resource_group" "main" {
  name = "contoso-devops-prod"  # Never hardcode
}
```

### 3. Clear Output Contract

Explicit outputs for integration between modules

```hcl
# Required outputs for integration
output "service_principal_id" {
  description = "Service principal object ID for role assignments"
  value       = azuread_service_principal.main.object_id
}

output "key_vault_uri" {
  description = "Key Vault URI for secret storage"
  value       = azurerm_key_vault.main.vault_uri
}
```

## Module Coupling Strategy

### 1. Loose Coupling via Outputs

Modules communicate through explicit output contracts

```hcl
# Producer module outputs
output "devops_service_principals" {
  description = "Service principals created for DevOps automation"
  value = {
    subscription_vending = {
      object_id     = azuread_service_principal.sub_vending.object_id
      application_id = azuread_service_principal.sub_vending.application_id
    }
    landing_zone_deploy = {
      object_id     = azuread_service_principal.lz_deploy.object_id
      application_id = azuread_service_principal.lz_deploy.application_id
    }
  }
}

# Consumer module inputs
variable "service_principal_assignments" {
  description = "Service principals to assign roles"
  type = map(object({
    object_id = string
    roles     = list(string)
  }))
}
```

### 2. Shared State Strategy

Modules reference each other through remote state

```hcl
# Reference other module state
data "terraform_remote_state" "entra_groups" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account
    container_name       = "terraform-state"
    key                  = "entra-groups.tfstate"
  }
}

# Use outputs from other modules
resource "azurerm_role_assignment" "devops_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = data.terraform_remote_state.entra_groups.outputs.service_principal_object_ids["devops_automation"]
}
```

### 3. Configuration Inheritance

Common configuration passed down through variables

```hcl
# Root module variables
variable "enterprise_config" {
  description = "Enterprise-wide configuration"
  type = object({
    organization_prefix = string
    default_location   = string
    default_tags       = map(string)
    security_contact   = string
    log_analytics_workspace_id = string
  })
}

# Pass to child modules
module "entra_groups" {
  source = "./modules/entra-groups"
  
  organization_prefix = var.enterprise_config.organization_prefix
  default_tags       = var.enterprise_config.default_tags
  security_contact   = var.enterprise_config.security_contact
}
```

## Script Development Standards

### 1. PowerShell Script Template

For Windows/cross-platform compatibility

```powershell
#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Bootstrap Azure DevOps infrastructure setup
.DESCRIPTION
    Creates initial Azure resources required for Terraform automation
.PARAMETER ConfigFile
    Path to configuration file (default: bootstrap-config.json)
.PARAMETER WhatIf
    Show what would be created without making changes
.EXAMPLE
    ./bootstrap-azure.ps1 -ConfigFile "my-org-config.json"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "bootstrap-config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf = $false
)

# Set strict error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Import configuration
if (-not (Test-Path $ConfigFile)) {
    throw "Configuration file not found: $ConfigFile"
}

$config = Get-Content $ConfigFile | ConvertFrom-Json

# Validation function
function Test-Prerequisites {
    $checks = @()
    
    # Check Azure CLI
    try {
        $azVersion = az version --output json | ConvertFrom-Json
        $checks += @{ Name = "Azure CLI"; Status = "OK"; Version = $azVersion.'azure-cli' }
    } catch {
        $checks += @{ Name = "Azure CLI"; Status = "FAIL"; Error = $_.Exception.Message }
    }
    
    return $checks
}

# Idempotent resource creation
function New-ResourceGroupIfNotExists {
    param($Name, $Location)
    
    $existing = az group show --name $Name 2>$null | ConvertFrom-Json
    if ($existing) {
        Write-Host "✓ Resource group '$Name' already exists" -ForegroundColor Green
        return $existing
    }
    
    if ($WhatIf) {
        Write-Host "WHATIF: Would create resource group '$Name' in '$Location'" -ForegroundColor Yellow
        return $null
    }
    
    Write-Host "Creating resource group '$Name'..." -ForegroundColor Cyan
    $result = az group create --name $Name --location $Location | ConvertFrom-Json
    Write-Host "✓ Created resource group '$Name'" -ForegroundColor Green
    return $result
}
```

### 2. Bash Script Template

For Linux environments

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-bootstrap-config.json}"
WHAT_IF="${WHAT_IF:-false}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${CYAN}INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# Validation function
check_prerequisites() {
    local errors=0
    
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found"
        ((errors++))
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq not found"
        ((errors++))
    fi
    
    return $errors
}

# Idempotent resource creation
create_resource_group_if_not_exists() {
    local name="$1"
    local location="$2"
    
    if az group show --name "$name" &>/dev/null; then
        log_success "Resource group '$name' already exists"
        return 0
    fi
    
    if [[ "$WHAT_IF" == "true" ]]; then
        log_warning "WHATIF: Would create resource group '$name' in '$location'"
        return 0
    fi
    
    log_info "Creating resource group '$name'..."
    az group create --name "$name" --location "$location" >/dev/null
    log_success "Created resource group '$name'"
}
```

## Configuration Management

### 1. JSON Configuration Schema

Structured configuration with validation

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Bootstrap Configuration",
  "type": "object",
  "required": ["organization", "azure", "devops"],
  "properties": {
    "organization": {
      "type": "object",
      "required": ["prefix", "location", "environment"],
      "properties": {
        "prefix": {
          "type": "string",
          "pattern": "^[a-z0-9]{2,10}$",
          "description": "Organization prefix (2-10 lowercase alphanumeric)"
        },
        "location": {
          "type": "string",
          "enum": ["eastus", "westus2", "centralus", "westeurope"],
          "description": "Primary Azure region"
        },
        "environment": {
          "type": "string",
          "enum": ["dev", "test", "prod"],
          "description": "Environment designation"
        }
      }
    },
    "azure": {
      "type": "object",
      "required": ["subscription_id", "tenant_id"],
      "properties": {
        "subscription_id": {
          "type": "string",
          "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        },
        "tenant_id": {
          "type": "string",
          "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        }
      }
    },
    "devops": {
      "type": "object",
      "required": ["organization_url", "project_name"],
      "properties": {
        "organization_url": {
          "type": "string",
          "format": "uri",
          "pattern": "^https://dev\\.azure\\.com/[a-zA-Z0-9-]+/?$"
        },
        "project_name": {
          "type": "string",
          "minLength": 1,
          "maxLength": 64
        }
      }
    }
  }
}
```

### 2. Example Configuration Files

**bootstrap-config.json**:

```json
{
  "organization": {
    "prefix": "contoso",
    "location": "eastus",
    "environment": "prod"
  },
  "azure": {
    "subscription_id": "12345678-1234-1234-1234-123456789012",
    "tenant_id": "87654321-4321-4321-4321-210987654321"
  },
  "devops": {
    "organization_url": "https://dev.azure.com/contoso",
    "project_name": "Enterprise Infrastructure"
  },
  "features": {
    "create_key_vault": true,
    "enable_private_endpoints": true,
    "configure_monitoring": true
  }
}
```

## Error Handling & Logging

### 1. Structured Error Handling

```powershell
# PowerShell error handling
try {
    $result = Invoke-AzureOperation -Parameters $params
    Write-Output "Operation completed successfully"
    return $result
} catch [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationFailedException] {
    Write-Error "Azure authentication failed. Run 'az login' to authenticate."
    exit 1
} catch [System.UnauthorizedAccessException] {
    Write-Error "Insufficient permissions. Check your Azure RBAC assignments."
    exit 1
} catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
```

### 2. Comprehensive Logging

```powershell
# Logging with structured output
function Write-OperationLog {
    param(
        [string]$Operation,
        [string]$Status,
        [string]$Message,
        [hashtable]$Metadata = @{}
    )
    
    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Operation = $Operation
        Status    = $Status
        Message   = $Message
        Metadata  = $Metadata
    }
    
    # Console output
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    
    Write-Host "[$($logEntry.Timestamp)] $($logEntry.Operation): $($logEntry.Message)" -ForegroundColor $color
    
    # Structured log for automation
    $logEntry | ConvertTo-Json -Compress | Add-Content -Path "bootstrap-$(Get-Date -Format 'yyyyMMdd').log"
}
```

## Testing Strategy

### 1. Script Validation

```powershell
# PowerShell script testing
function Test-BootstrapScript {
    param([string]$ConfigFile)
    
    # Test configuration loading
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    if (-not $config.organization.prefix) {
        throw "Invalid configuration: missing organization prefix"
    }
    
    # Test Azure connectivity
    $currentUser = az account show | ConvertFrom-Json
    if (-not $currentUser) {
        throw "Not authenticated to Azure. Run 'az login'"
    }
    
    # Test permissions
    $subscriptionAccess = az role assignment list --assignee $currentUser.user.name --scope "/subscriptions/$($config.azure.subscription_id)" | ConvertFrom-Json
    if (-not $subscriptionAccess) {
        throw "No access to specified subscription"
    }
    
    Write-Output "All validation checks passed"
}
```

### 2. Dry-Run Mode

```bash
# Bash dry-run implementation
perform_operation() {
    local operation="$1"
    shift
    local args=("$@")
    
    if [[ "$WHAT_IF" == "true" ]]; then
        log_warning "WHATIF: Would execute: $operation ${args[*]}"
        return 0
    fi
    
    log_info "Executing: $operation"
    if "$operation" "${args[@]}"; then
        log_success "Completed: $operation"
        return 0
    else
        log_error "Failed: $operation"
        return 1
    fi
}
```

## Integration Patterns

### 1. Module Dependencies

```hcl
# Dependency management through data sources
data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    key = "bootstrap.tfstate"
    # ... backend config
  }
}

# Explicit dependency on bootstrap completion
resource "azuredevops_project" "main" {
  # Ensure bootstrap module has created required resources
  depends_on = [data.terraform_remote_state.bootstrap]
  
  project_name = var.project_name
  # Use outputs from bootstrap
  service_principal_id = data.terraform_remote_state.bootstrap.outputs.devops_service_principal_id
}
```

### 2. Secret Management

```hcl
# Secure secret handling
resource "azurerm_key_vault_secret" "service_principal_secret" {
  name         = "devops-sp-secret"
  value        = azuread_service_principal_password.devops.value
  key_vault_id = data.terraform_remote_state.bootstrap.outputs.key_vault_id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Reference secrets in other modules
data "azurerm_key_vault_secret" "sp_secret" {
  name         = "devops-sp-secret"
  key_vault_id = var.key_vault_id
}
```

## Code Quality Standards

### 1. Mandatory Validations

```hcl
# Input validation
variable "organization_prefix" {
  description = "Organization prefix for resource naming"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.organization_prefix))
    error_message = "Organization prefix must be 2-10 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment designation"
  type        = string
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}
```

### 2. Documentation Requirements

```hcl
# Every resource must have:
# 1. Clear description
# 2. Proper naming convention
# 3. Required tags
# 4. Dependencies documented

resource "azurerm_key_vault" "automation" {
  # Clear purpose in name
  name = "${var.organization_prefix}-automation-kv-${random_string.suffix.result}"
  
  # Standard location and resource group
  location            = var.location
  resource_group_name = azurerm_resource_group.automation.name
  
  # Required for enterprise compliance
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  
  # Standard enterprise tags
  tags = merge(var.default_tags, {
    Purpose     = "Terraform automation secrets"
    Module      = "azure-bootstrap"
    Environment = var.environment
  })
}
```

**Next step: Create the actual bootstrap script and modules following these guidelines?**
