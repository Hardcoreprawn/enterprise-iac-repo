terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.10"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azuredevops" {
  org_service_url = var.azdo_org_service_url
}

# Create Entra ID groups and service principals
module "entra_groups" {
  source = "../modules/entra-groups"
  
  organization_prefix = var.organization_prefix
  environment        = var.environment
  security_contact   = "security@${var.organization_prefix}.com"
  
  default_tags = {
    Organization = var.organization_prefix
    Environment  = var.environment
    Purpose      = "CloudStandardsAutomation"
    ManagedBy    = "Terraform"
  }
}

# Create secure Terraform state storage
module "azure_bootstrap" {
  source = "../modules/azure-bootstrap"
  
  organization_prefix        = var.organization_prefix
  environment               = var.environment
  location                  = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  service_principal_object_ids = module.entra_groups.service_principal_object_ids
  
  common_tags = {
    Organization = var.organization_prefix
    Environment  = var.environment
    ManagedBy    = "Terraform"
    Purpose      = "CloudStandardsAutomation"
  }
}

# Resource Group for the project
resource "azurerm_resource_group" "main" {
  name     = "${var.organization_prefix}-${var.environment}-automation"
  location = var.location

  tags = {
    Environment = var.environment
    Organization = var.organization_prefix
    Purpose     = "CloudStandardsAutomation"
    ManagedBy   = "Terraform"
  }
}

# Service Principal for automation
resource "azurerm_user_assigned_identity" "automation" {
  name                = "${var.project_name}-automation-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = azurerm_resource_group.main.tags
}

# Key Vault for secrets management
resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-kv-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  enable_rbac_authorization = true
  purge_protection_enabled  = true

  tags = azurerm_resource_group.main.tags
}

# Random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Current Azure configuration
data "azurerm_client_config" "current" {}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = azurerm_resource_group.main.tags
}
