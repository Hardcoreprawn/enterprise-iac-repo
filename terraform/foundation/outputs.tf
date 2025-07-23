output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = azurerm_resource_group.main.location
}

output "automation_identity_id" {
  description = "ID of the automation managed identity"
  value       = azurerm_user_assigned_identity.automation.id
}

output "automation_identity_principal_id" {
  description = "Principal ID of the automation managed identity"
  value       = azurerm_user_assigned_identity.automation.principal_id
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_key" {
  description = "Primary shared key of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

# Bootstrap Module Outputs
output "terraform_state_storage_account" {
  description = "Name of the Terraform state storage account"
  value       = module.azure_bootstrap.storage_account_name
}

output "terraform_state_container" {
  description = "Name of the Terraform state container"
  value       = module.azure_bootstrap.storage_container_name
}

output "terraform_backend_config" {
  description = "Complete backend configuration for Terraform remote state"
  value       = module.azure_bootstrap.backend_config
}

output "terraform_backend_template" {
  description = "Template for Terraform backend configuration block"
  value       = module.azure_bootstrap.backend_config_template
}
