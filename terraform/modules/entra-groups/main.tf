terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Get current client configuration
data "azuread_client_config" "current" {}

# Create security groups
resource "azuread_group" "security_groups" {
  for_each = var.security_groups

  display_name     = "${var.organization_prefix}-${each.key}-${var.environment}"
  description      = each.value.description
  security_enabled = true
  mail_enabled     = false

  # Prevent accidental deletion
  prevent_duplicate_names = true

  owners = [data.azuread_client_config.current.object_id]
}

# Create application registrations for service principals
resource "azuread_application" "devops_apps" {
  for_each = var.devops_service_principals

  display_name = "${var.organization_prefix}-${each.key}-${var.environment}"
  description  = each.value.description

  # Configure application settings
  sign_in_audience = "AzureADMyOrg"

  # Required resource access for Azure management
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  # Prevent accidental deletion
  prevent_duplicate_names = true

  tags = [
    "Environment:${var.environment}",
    "Purpose:DevOpsAutomation",
    "Contact:${var.security_contact}"
  ]
}

# Create service principals
resource "azuread_service_principal" "devops_sps" {
  for_each = var.devops_service_principals

  client_id   = azuread_application.devops_apps[each.key].client_id
  description = each.value.description

  # Use application name from app registration
  use_existing = false

  tags = [
    "Environment:${var.environment}",
    "Purpose:DevOpsAutomation",
    "Contact:${var.security_contact}"
  ]
}

# Create service principal passwords (secrets)
resource "azuread_service_principal_password" "devops_sp_passwords" {
  for_each = var.devops_service_principals

  service_principal_id = azuread_service_principal.devops_sps[each.key].object_id
  display_name         = "${var.organization_prefix}-${each.key}-secret"

  # Password expires in 2 years
  end_date = timeadd(timestamp(), "17520h") # 2 years
}

# Generate random suffix for unique naming
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}
