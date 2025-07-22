# Enterprise Infrastructure as Code Toolkit

DevContainer-based infrastructure automation toolkit for enterprise cloud deployments. Provides a consistent development environment with all tools pre-configured.

**Key Features:**

- 🚀 **Fast Setup**: DevContainer with all tools pre-configured
- 🔒 **Enterprise Standards**: Built-in security and compliance validation
- 🧪 **Local-First**: Test everything before deploying
- 📦 **Consistent Environment**: Same toolchain for everyone
- 🎯 **Clear Standards**: Binary completion criteria for all infrastructure

## 🚀 Quick Start

**New to this project?** See the [Quick Start Guide](docs/quick-start.md) for a 5-minute setup.

## DevContainer Setup (Required)

This toolkit requires a DevContainer for consistent development:

1. **Install Prerequisites**:
   - VS Code with "Dev Containers" extension
   - Docker Desktop

2. **Open in Container**:
   - Open this repository in VS Code
   - Click "Reopen in Container" when prompted
   - Wait 2-3 minutes for automatic setup to complete

3. **Start Developing**:

   ```bash
   # Check everything works
   ./health-check.sh
   
   # Quick validation test
   make validate-dry
   ```

See [DevContainer Guide](.devcontainer/README.md) for detailed instructions.

## DevContainer-First Workflow

This toolkit is designed for consistent DevContainer development:

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

- **Container-based**: Consistent environment across all machines
- **No local dependencies**: Everything runs inside the container
- **Self-contained**: All dependencies documented and pre-installed
- **Organization-portable**: Take this toolkit anywhere

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

- VS Code with "Dev Containers" extension
- Docker Desktop
- Git (for cloning the repository)

All other tools (PowerShell, Azure CLI, Terraform, Make) are pre-installed in the DevContainer.

## Development Workflow

1. **Configure environment**: Edit `local-validation-config.json`

2. **Run validation in DevContainer**:

   ```bash
   # Quick validation (dry-run, fast)
   make validate-dry
   
   # Full validation (includes Azure checks)
   make validate
   
   # Install Azure modules when needed
   make install-az
   ```

3. **Git hooks automatically validate** when you commit

## Documentation

- **[Quick Start Guide](docs/quick-start.md)** - Get up and running in 5 minutes
- **[Project Overview](docs/project-overview.md)** - Comprehensive project structure and goals
- **[Architecture Overview](docs/ARCHITECTURE.md)** - High-level design and technology decisions
- **[Cloud Infrastructure Definition of Done](docs/standards/cloud-infrastructure-definition-of-done.md)** - Enterprise standards checklist
- **[Writing Principles](docs/standards/writing-principles.md)** - Guidelines for clear, actionable documentation
- **[Testing Framework](tests/README.md)** - Infrastructure validation and monitoring scripts
- **[DevContainer Guide](.devcontainer/README.md)** - Detailed container development setup

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

See the [Contributing Guide](CONTRIBUTING.md) for detailed information on development workflow, testing requirements, and code standards.

---

**Project Status:** 🚧 In Development  
**Last Updated:** July 22, 2025
