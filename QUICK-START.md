# Quick Start Guide

Get the Enterprise IaC Toolkit running in 5 minutes.

## Prerequisites

- VS Code with "Dev Containers" extension
- Docker Desktop  
- Git (for cloning)

All other tools install automatically in the container.

## Setup Steps

### 1. Clone and Open

```bash
git clone https://github.com/Hardcoreprawn/enterprise-iac-repo.git
cd enterprise-iac-repo
code .
```

### 2. Open in Container

- VS Code will detect DevContainer configuration
- Click "Reopen in Container" when prompted
- Wait 2-3 minutes for automatic setup

### 3. Verify Installation

```bash
# Check that everything installed correctly
./health-check.sh

# Test the validation framework
make validate-dry
```

### 4. Configure for Your Environment

```bash
# Edit configuration file
cp local-validation-config.json.example local-validation-config.json
# Update with your Azure subscription and resource group details
```

### 5. Azure Authentication

```bash
# Sign in to Azure
az login

# Verify access
az account show

# Install Azure PowerShell modules when needed
make install-az
```

## Daily Workflow

### Development Loop

```bash
# 1. Quick validation during development
make validate-dry

# 2. Make infrastructure changes
# - Edit files in terraform/
# - Update policies in policies/
# - Modify tests in tests/

# 3. Full validation before commit  
make validate

# 4. Commit with automatic validation
git add .
git commit -m "feat: add new infrastructure module"
```

### Terraform Operations

```bash
# Plan infrastructure changes
make plan

# Apply infrastructure  
make apply

# Clean up resources
make destroy
```

### Testing

```bash
# Run all tests
make test

# Run specific test categories
make test-connectivity    # Network connectivity
make test-security       # Security compliance  
make test-monitoring     # Monitoring configuration
```

## Configuration

### Required Configuration

Edit `local-validation-config.json`:

```json
{
  "resourceGroup": "rg-your-dev-environment",
  "subscription": "your-subscription-id", 
  "runConnectivityTests": true,
  "runSecurityTests": true,
  "runMonitoringTests": true
}
```

### Environment Variables

```bash
# Optional: Set for easier testing
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_RESOURCE_GROUP="rg-your-dev-environment"
```

## Available Commands

```bash
make help                # Show all available commands

# Development
make validate-dry        # Fast validation (dry-run mode)
make validate           # Full validation with Azure checks
make test-setup         # Verify toolkit setup

# Infrastructure  
make plan              # Generate Terraform plan
make apply             # Apply Terraform configuration
make destroy           # Destroy Terraform resources

# Testing
make test              # Run all tests
make test-connectivity # Test network connectivity
make test-security     # Validate security compliance
make test-monitoring   # Check monitoring configuration

# Setup
make install-az        # Install Azure PowerShell modules
make install-hooks     # Install git pre-commit hooks
make clean            # Clean up temporary files
```

## Troubleshooting

### Container Issues

```bash
# Container not starting
docker system prune -a

# Rebuild container if needed
# Command Palette: "Dev Containers: Rebuild Container"
```

### Authentication Issues

```bash
# Clear Azure credentials
az logout
rm -rf ~/.azure
az login

# Verify authentication  
az account show
```

### Validation Failures

```bash
# Check Azure permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Verify resource group access
az group show --name "your-resource-group"

# Run in dry-run mode to debug
make validate-dry
```

## Next Steps

1. **Deploy foundation infrastructure**: Run `make apply` to create core resources
2. **Explore modules**: Check `terraform/modules/` for available infrastructure patterns
3. **Read documentation**: See `docs/` for detailed guides and standards
4. **Customize for your organization**: Adapt modules and policies for your requirements

## Support

- **Documentation**: Comprehensive guides in `docs/` directory
- **Examples**: Working examples in each module's README
- **Standards**: Enterprise requirements in `docs/standards/`
- **Architecture**: Technical decisions in `docs/ARCHITECTURE.md`
