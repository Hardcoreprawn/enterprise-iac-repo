# Enterprise Infrastructure as Code Toolkit

Portable infrastructure automation toolkit for enterprise cloud deployments. Designed to work locally before commits and be portable across organizations and roles.

## Quick Start

1. **Configure your environment**: Edit `local-validation-config.json`
2. **Run validation**: `make validate` or `./validate-local.ps1`
3. **Install git hooks**: `make install-hooks`
4. **Start building**: Use the `terraform/` modules and testing framework

## DevContainer Setup (Recommended)

For isolated, reproducible development:

1. **Install Prerequisites**:
   - VS Code with "Dev Containers" extension
   - Docker Desktop

2. **Open in Container**:
   - Open this repository in VS Code
   - Click "Reopen in Container" when prompted
   - Wait for automatic setup to complete

3. **Start Developing**:

   ```bash
   # Check everything works
   ./health-check.sh
   
   # Quick validation test
   make validate-dry
   ```

See [DevContainer Guide](.devcontainer/README.md) for detailed instructions.

## Local-First Workflow

This toolkit is designed for local validation before commits:

```bash
# Quick validation (fast, for development)
make validate-dry

# Full validation (includes Azure resource checks)
make validate

# Run specific test types
make test-connectivity
make test-security
make test-monitoring

# Terraform operations
make plan
make apply
```

## Portability Features

- **No vendor lock-in**: Scripts work with Azure CLI, PowerShell, or Terraform
- **Cross-platform**: Works on Windows, Linux, and macOS
- **Self-contained**: All dependencies documented and checkable
- **Role-portable**: Take this toolkit to any organization

## Repository Structure

```text
├── docs/                          # Documentation and standards
│   └── standards/                 # Infrastructure standards and principles
├── terraform/                     # Infrastructure as Code
│   ├── foundation/                # Core infrastructure setup
│   └── modules/                   # Reusable Terraform modules
├── policies/                      # Azure Policy definitions
│   └── security/                  # Security-related policies
├── pipelines/                     # Azure DevOps pipeline definitions
│   └── infrastructure/            # Infrastructure deployment pipelines
└── .github/                       # GitHub configuration and instructions
```

## Configuration

The toolkit uses `local-validation-config.json` for environment-specific settings:

```json
{
  "resourceGroup": "rg-your-test-environment", 
  "subscription": "your-subscription-id",
  "runConnectivityTests": true,
  "runSecurityTests": false,
  "runMonitoringTests": false
}
```

## Prerequisites

- PowerShell (pwsh) or Windows PowerShell
- Azure CLI or Azure PowerShell modules
- Terraform >= 1.0 (optional)
- Make (optional, for convenience commands)

## Local Development

1. **Configure environment**: Edit `local-validation-config.json`

2. **Run validation locally**:

   ```bash
   # Quick validation (dry-run, fast)
   make validate-dry
   
   # Full validation (includes Azure checks)
   make validate
   ```

3. **Install git hooks** (optional):

   ```bash
   make install-hooks
   ```

## Documentation

- **[Cloud Infrastructure Definition of Done](docs/standards/cloud-infrastructure-definition-of-done.md)** - Enterprise standards checklist
- **[Writing Principles](docs/standards/writing-principles.md)** - Guidelines for clear, actionable documentation
- **[Testing Framework](tests/README.md)** - Infrastructure validation and monitoring scripts

## Portable Workflow

1. **Create feature branch** for all infrastructure changes
2. **Run validation** - Terraform plan and policy checks
3. **Submit pull request** with required reviews
4. **Deploy via pipeline** after approval

## Standards Compliance

All infrastructure deployments must meet the enterprise standards defined in our [Definition of Done](docs/standards/cloud-infrastructure-definition-of-done.md). This includes:

- Security configurations (MFA, RBAC, encryption)
- Monitoring and observability setup
- Operational requirements (IaC, backups, scaling)
- Governance and compliance validation

## Contributing

Follow the established [writing principles](docs/standards/writing-principles.md) when creating documentation or standards. Focus on concrete, actionable requirements rather than aspirational language.

---

**Project Status:** 🚧 In Development  
**Last Updated:** July 22, 2025
