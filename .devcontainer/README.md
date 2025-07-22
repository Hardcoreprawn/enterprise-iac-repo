# DevContainer Development Guide

Complete guide for using the Infrastructure Toolkit in a development container for consistent, portable development environments.

## Why DevContainer?

- **Consistent Environment**: Everyone gets the same tools and versions
- **Fast Setup**: No manual tool installation
- **Performance**: Linux filesystem for faster Terraform operations
- **Isolation**: No conflicts with local machine setup
- **Portable**: Works on Windows, macOS, and Linux

## Getting Started

### Prerequisites

- **VS Code** with "Dev Containers" extension
- **Docker Desktop** (or Docker Engine on Linux)
- **Git** for cloning the repository

### First Time Setup

1. **Clone Repository**

   ```bash
   git clone https://github.com/Hardcoreprawn/enterprise-iac-repo.git
   cd enterprise-iac-repo
   ```

2. **Open in VS Code**

   ```bash
   code .
   ```

3. **Reopen in Container**
   - VS Code will detect the devcontainer configuration
   - Click "Reopen in Container" when prompted
   - Alternative: `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

4. **Wait for Setup**
   - Initial setup takes 2-3 minutes (much faster now!)
   - Container will install Azure CLI, Terraform, PowerShell, and extensions
   - Azure PowerShell modules install on-demand when needed
   - Progress shown in VS Code terminal

5. **Verify Installation**

   ```bash
   # Run health check
   ./health-check.sh
   
   # Install Azure PowerShell modules when needed
   make install-az
   
   # Quick validation test
   make validate-dry
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

### Performance Optimization

- **Linux Filesystem** - Repository runs entirely on Linux filesystem for maximum performance
- **Fast Terraform Operations** - No Windows bind mount performance penalties
- **Optimized I/O** - All file operations run at native container speeds

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

The repository is cloned into the container's Linux filesystem for optimal performance. This means:

- **Code changes persist** across container rebuilds (as long as you commit/push)
- **Performance is optimized** - no Windows filesystem binding penalties
- **Terraform runs fast** - all operations on native Linux filesystem
- **Tool installations in container** are reset on rebuild (this is by design)

**Important**: Commit and push your changes regularly since the container filesystem is ephemeral.

### Multi-Environment

Create multiple devcontainer configurations for different scenarios:

- `.devcontainer/azure/devcontainer.json` - Azure-focused
- `.devcontainer/aws/devcontainer.json` - AWS-focused
- `.devcontainer/minimal/devcontainer.json` - Lightweight setup
