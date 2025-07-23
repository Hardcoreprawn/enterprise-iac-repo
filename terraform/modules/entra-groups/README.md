# Entra Groups Module

Creates Azure Entra ID groups and service principals for enterprise DevOps automation.

## Purpose

This module handles all identity-related setup required for secure infrastructure automation:

- Security groups for team organization
- Service principals for automation with least privilege access
- Application registrations for DevOps tooling

## Usage

```hcl
module "entra_groups" {
  source = "./modules/entra-groups"
  
  organization_prefix = "contoso"
  environment        = "prod"
  security_contact   = "security@contoso.com"
  
  default_tags = {
    Organization = "Contoso"
    Department   = "Engineering"
    Environment  = "Production"
  }
}
```

## Requirements

- Azure CLI authenticated with Global Admin or Application Administrator role
- Terraform AzureAD provider configured

## Outputs

- `devops_service_principals`: Map of service principal details for use by other modules
- `security_groups`: Map of created security groups
- `application_registrations`: Application registration details for DevOps tools
