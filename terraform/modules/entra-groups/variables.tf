variable "organization_prefix" {
  description = "Organization prefix for resource naming (2-10 lowercase alphanumeric)"
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

variable "security_contact" {
  description = "Email address for security contact"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.security_contact))
    error_message = "Security contact must be a valid email address."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "devops_service_principals" {
  description = "Map of service principals to create for DevOps automation"
  type = map(object({
    description = string
    roles       = list(string)
  }))
  default = {
    subscription_vending = {
      description = "Service principal for subscription vending automation"
      roles       = ["Owner"]
    }
    landing_zone_deploy = {
      description = "Service principal for landing zone deployment"
      roles       = ["Contributor", "User Access Administrator"]
    }
    devops_automation = {
      description = "Service principal for general DevOps automation"
      roles       = ["Contributor"]
    }
  }
}

variable "security_groups" {
  description = "Map of security groups to create"
  type = map(object({
    description = string
    members     = list(string)
  }))
  default = {
    platform_engineers = {
      description = "Platform engineering team with elevated access"
      members     = []
    }
    devops_engineers = {
      description = "DevOps engineers with automation access"
      members     = []
    }
    security_team = {
      description = "Security team with monitoring and compliance access"
      members     = []
    }
  }
}
