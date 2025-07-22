# DevContainer Development Guide

Guide for using the Infrastructure Toolkit in a development container.

## Getting Started

1. **Open in DevContainer**
   - Install the "Dev Containers" extension in VS Code
   - Open the repository in VS Code
   - Click "Reopen in Container" when prompted, or use Command Palette: "Dev Containers: Reopen in Container"

2. **First Run Setup**

   ```bash
   # Check everything is working
   ./health-check.sh
   
   # Run quick validation test
   make validate-dry
   ```

3. **Azure Authentication**

   ```bash
   # Sign in to Azure
   az login
   
   # List available subscriptions
   az account list --output table
   
   # Set default subscription
   az account set --subscription "your-subscription-id"
   ```

## Development Workflow

### Daily Development

```bash
# Start with a health check
./health-check.sh

# Quick validation during development
make validate-dry

# Full validation before commits
make validate

# View all available commands
make help
```

### Configuration

Edit `local-validation-config.json` for your environment:

```json
{
  "resourceGroup": "rg-your-dev-environment",
  "subscription": "your-subscription-id",
  "runConnectivityTests": true,
  "runSecurityTests": true,
  "runMonitoringTests": true
}
```

### Testing Infrastructure

```bash
# Test connectivity (works without Azure resources)
make test-connectivity

# Test security compliance (requires Azure resources)
make test-security

# Test monitoring configuration (requires Azure resources)
make test-monitoring
```

### Terraform Operations

```bash
# Plan infrastructure changes
make plan

# Apply infrastructure
make apply

# Destroy infrastructure
make destroy
```

## DevContainer Features

### Pre-installed Tools

- **PowerShell 7+** - Main scripting environment
- **Azure CLI** - Azure command-line tools
- **Terraform** - Infrastructure as Code
- **Git** - Version control
- **Make** - Build automation
- **jq** - JSON processing
- **Various utilities** - curl, wget, unzip, tree, htop

### VS Code Extensions

- PowerShell language support
- Terraform language support
- Azure CLI tools
- Azure resource management
- YAML support
- Markdown linting
- Makefile support

### Mounted Directories

- **Azure credentials** - Your local `~/.azure` directory is mounted for authentication persistence

## Troubleshooting

### Container Issues

```bash
# Rebuild container if issues occur
# Command Palette: "Dev Containers: Rebuild Container"

# Or rebuild without cache
# Command Palette: "Dev Containers: Rebuild and Reopen in Container"
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

### PowerShell Issues

```bash
# Check PowerShell version
pwsh --version

# Reinstall Azure PowerShell modules if needed
pwsh -c "Uninstall-Module Az -Force; Install-Module Az -Force"
```

### Permission Issues

```bash
# Make scripts executable
find . -name "*.ps1" -type f -exec chmod +x {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;
```

## Benefits

### Isolation

- Clean environment every time
- No conflicts with host system tools
- Consistent across team members

### Portability

- Same environment on any machine with Docker
- Take to any organization or role
- No host system pollution

### Safety

- Break things without affecting your laptop
- Easy to reset to clean state
- Isolated networking and file system

## Advanced Usage

### Custom Container

Modify `.devcontainer/devcontainer.json` to add:

- Additional tools
- VS Code extensions
- Environment variables
- Port forwarding

### Container Persistence

Data in the workspace is persistent, but container state is not. This means:

- Your code changes persist
- Configuration files persist
- Tool installations in container are reset on rebuild

### Multi-Environment

Create multiple devcontainer configurations for different scenarios:

- `.devcontainer/azure/devcontainer.json` - Azure-focused
- `.devcontainer/aws/devcontainer.json` - AWS-focused
- `.devcontainer/minimal/devcontainer.json` - Lightweight setup
