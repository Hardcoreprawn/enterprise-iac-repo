# Azure Bootstrap Module - Secure Terraform State Backend
# Creates storage account, container, and security configuration for remote state

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Generate unique suffix for storage account name (must be globally unique)
resource "random_string" "storage_suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# Resource group for Terraform state management
resource "azurerm_resource_group" "terraform_state" {
  name     = "rg-${var.organization_prefix}-terraform-state"
  location = var.location

  tags = merge(var.common_tags, {
    Purpose = "TerraformStateManagement"
  })
}

# Storage account for Terraform state with enterprise security
resource "azurerm_storage_account" "terraform_state" {
  name                = "st${var.organization_prefix}tfstate${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.terraform_state.name
  location            = azurerm_resource_group.terraform_state.location

  account_tier                      = "Standard"
  account_replication_type          = "ZRS"
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  public_network_access_enabled     = var.enable_public_access
  default_to_oauth_authentication   = true

  # Enterprise security features
  blob_properties {
    versioning_enabled       = var.enable_versioning
    change_feed_enabled      = true
    change_feed_retention_in_days = 7
    
    delete_retention_policy {
      days = var.retention_days
    }
    
    container_delete_retention_policy {
      days = var.retention_days
    }

    restore_policy {
      days = 6
    }
  }

  tags = merge(var.common_tags, {
    Purpose = "TerraformStateStorage"
    Security = "EnterpriseGrade"
  })
}

# Container for Terraform state files
resource "azurerm_storage_container" "terraform_state" {
  name                 = "tfstate"
  storage_account_name = azurerm_storage_account.terraform_state.name
}

# Enable diagnostic logging for the storage account
resource "azurerm_monitor_diagnostic_setting" "terraform_state_storage" {
  name                       = "terraform-state-diagnostics"
  target_resource_id         = azurerm_storage_account.terraform_state.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }
}

# Create private endpoint for storage account (optional, for enhanced security)
resource "azurerm_private_endpoint" "terraform_state_storage" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${azurerm_storage_account.terraform_state.name}"
  location            = azurerm_resource_group.terraform_state.location
  resource_group_name = azurerm_resource_group.terraform_state.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.terraform_state.name}"
    private_connection_resource_id = azurerm_storage_account.terraform_state.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = merge(var.common_tags, {
    Purpose = "TerraformStatePrivateAccess"
  })
}

# RBAC assignments for service principals
resource "azurerm_role_assignment" "terraform_state_contributor" {
  for_each = var.service_principal_object_ids

  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# Additional role for reading storage account keys (if needed for legacy compatibility)
resource "azurerm_role_assignment" "storage_account_key_operator" {
  for_each = var.service_principal_object_ids

  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = each.value
}
