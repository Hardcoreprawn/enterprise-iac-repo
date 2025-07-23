variable "organization_prefix" {
  description = "Organization prefix for resource naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.organization_prefix))
    error_message = "Organization prefix must be 2-10 characters, lowercase letters and numbers only."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic logging"
  type        = string
}

variable "enable_public_access" {
  description = "Enable public network access to storage account"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Create private endpoint for storage account"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (required if enable_private_endpoint is true)"
  type        = string
  default     = null
}

variable "service_principal_object_ids" {
  description = "Map of service principal object IDs that need access to Terraform state"
  type        = map(string)
  default     = {}
}

variable "enable_versioning" {
  description = "Enable versioning on the storage account"
  type        = bool
  default     = true
}

variable "retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}
