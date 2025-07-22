variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-cloudstandards-automation"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project identifier for resource naming"
  type        = string
  default     = "cloudstd"
}

variable "azdo_org_service_url" {
  description = "Azure DevOps organization URL"
  type        = string
}

variable "azdo_project_name" {
  description = "Azure DevOps project name"
  type        = string
  default     = "CloudStandardsAutomation"
}
