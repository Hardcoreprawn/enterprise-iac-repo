# Terraform Foundation

Core infrastructure setup for the enterprise cloud standards project

## Purpose

This directory contains Terraform configurations for setting up the foundational infrastructure required to support the enterprise cloud standards implementation, including:

- Azure DevOps project and service principals
- Azure Policy assignments
- Core networking and security configurations
- Monitoring and logging infrastructure

## Directory Structure

```text
foundation/
├── azure-devops/              # Azure DevOps project setup
├── policy-assignments/        # Azure Policy assignments
├── service-principals/        # Service principal configurations
└── main.tf                    # Main configuration
```

## Usage

1. **Configure variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

2. **Initialize and deploy**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Variables

Key variables that need to be configured:

- `subscription_id` - Azure subscription ID
- `resource_group_name` - Resource group for infrastructure
- `location` - Azure region
- `environment` - Environment name (dev/staging/prod)
- `project_name` - Project identifier

## Outputs

This configuration outputs key information needed for subsequent deployments:

- Resource group details
- Service principal credentials
- Azure DevOps project information
