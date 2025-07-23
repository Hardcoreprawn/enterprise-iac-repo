# Enterprise Infrastructure as Code Toolkit

DevContainer-based infrastructure automation toolkit for enterprise cloud deployments. Provides a
consistent development environment with all tools pre-configured.

**Key Features:**

- Fast Setup: DevContainer with all tools pre-configured
- Enterprise Standards: Built-in security and compliance validation
- Local-First: Test everything before deploying
- Consistent Environment: Same toolchain for everyone
- Clear Standards: Binary completion criteria for all infrastructure

## Getting Started

**New team member?** Start with the [Quick Start Guide](docs/quick-start.md)

**Need project details?** See the [Project Overview](docs/project-overview.md)

**Ready to contribute?** Check the [Contribution Guide](docs/standards/contribution-guide.md)

## DevContainer Setup (Required)

This toolkit requires a DevContainer for consistent development:

1. **Prerequisites**: VS Code with "Dev Containers" extension and Docker Desktop
2. **Open Repository**: Open in VS Code and click "Reopen in Container" when prompted
3. **Wait for Setup**: 2-3 minutes for automatic configuration
4. **Start Working**: Run `make test-setup` to verify everything works

## Quick Commands

```bash
# Verify setup
make test-setup

# Quick validation (development)
make validate-dry

# Full validation (pre-commit) 
make validate

# Install Azure modules
make install-az

# See all commands
make help
```

## Repository Structure

```text
├── terraform/          # Infrastructure as Code modules and foundation
├── docs/               # Complete project documentation
├── scripts/            # Automation and validation scripts  
├── tests/              # Compliance and connectivity testing
├── policies/           # Azure Policy definitions
└── Makefile           # Build and automation interface
```

## Documentation

- **[Quick Start Guide](docs/quick-start.md)** - Get up and running in 5 minutes
- **[Project Overview](docs/project-overview.md)** - Complete project details and architecture
- **[Contribution Guide](docs/standards/contribution-guide.md)** - Development workflow and standards
- **[Architecture Decisions](docs/ADRS.md)** - Key architectural decisions and rationale

## Requirements

- Azure subscription with appropriate permissions
- VS Code with Dev Containers extension
- Docker Desktop
- Git

## Enterprise Standards

All infrastructure meets enterprise requirements:

- Security: Resources follow security policies and compliance rules
- Monitoring: Infrastructure includes monitoring and alerting
- Naming: Resources use enterprise naming conventions
- Documentation: All components are documented with clear purpose
- Testing: Validation scripts verify configuration before deployment
