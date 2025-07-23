output "storage_account_name" {
  description = "Name of the Terraform state storage account"
  value       = azurerm_storage_account.terraform_state.name
}

output "storage_account_id" {
  description = "ID of the Terraform state storage account"
  value       = azurerm_storage_account.terraform_state.id
}

output "storage_container_name" {
  description = "Name of the Terraform state storage container"
  value       = azurerm_storage_container.terraform_state.name
}

output "resource_group_name" {
  description = "Name of the Terraform state resource group"
  value       = azurerm_resource_group.terraform_state.name
}

output "resource_group_id" {
  description = "ID of the Terraform state resource group"
  value       = azurerm_resource_group.terraform_state.id
}

output "backend_config" {
  description = "Backend configuration for Terraform remote state"
  value = {
    storage_account_name = azurerm_storage_account.terraform_state.name
    container_name       = azurerm_storage_container.terraform_state.name
    key                  = "terraform.tfstate"
  }
}

output "backend_config_template" {
  description = "Template for Terraform backend configuration block"
  value = <<-EOT
terraform {
  backend "azurerm" {
    storage_account_name = "${azurerm_storage_account.terraform_state.name}"
    container_name       = "${azurerm_storage_container.terraform_state.name}"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}
EOT
}

output "private_endpoint_id" {
  description = "ID of the private endpoint (if created)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.terraform_state_storage[0].id : null
}
