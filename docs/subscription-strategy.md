# Azure Subscription Management

Current status and guidance for Azure subscription management in this enterprise environment.

## Current Setup

### Management Subscription Bootstrap

**Status**: Foundation infrastructure ready for deployment

The project includes a complete bootstrap solution for setting up the management subscription that
will house platform automation infrastructure.

**Key Components**:

- Terraform state storage with versioning and access controls
- Service principals with least privilege access
- Centralized monitoring and logging configuration
- Azure DevOps integration for automated workflows

**Next Step**: Deploy using the [Bootstrap Guide](bootstrap-guide.md)

### Architecture

This implementation follows the management subscription pattern where platform automation
infrastructure is separated from application workloads.

**Management Subscription Contains**:

- Terraform state storage
- Service principals for automation
- Centralized monitoring workspace
- Key Vault for automation secrets

**Workload Subscriptions**: Separate subscriptions for applications (to be created later)

## Getting Started

### For New Teams

1. **Environment Setup**: Follow the [Quick Start Guide](quick-start.md) to set up your development environment
2. **Deploy Foundation**: Use the [Bootstrap Guide](bootstrap-guide.md) to deploy the management subscription infrastructure
3. **Review Standards**: Understand requirements in [Azure Subscription Standards](standards/azure-subscription-standards.md)

### For Platform Teams

**Deploy the foundation infrastructure**:

```bash
# Configure your organization settings
edit bootstrap-config.json

# Deploy foundation infrastructure
make bootstrap
```

**Migrate to remote state** (after bootstrap):

```bash
# Get backend configuration from Terraform output
terraform output terraform_backend_template

# Follow state migration steps in bootstrap guide
```

## Future Capabilities

**Planned additions** (not yet implemented):

- Automated subscription vending pipeline
- Landing zone templates for different subscription types
- Self-service subscription request workflow

These capabilities will be added once the foundation infrastructure is deployed and tested.

## Documentation

**Detailed Standards**: [Azure Subscription Standards](standards/azure-subscription-standards.md)
**Installation Steps**: [Bootstrap Guide](bootstrap-guide.md)  
**Development Setup**: [Quick Start Guide](quick-start.md)
