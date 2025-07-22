# Quick Start Guide

Get productive with the Infrastructure Toolkit in 5 minutes

## 🚀 New Team Member Setup

### DevContainer Setup (Required)

1. **Install Prerequisites**
   - VS Code with "Dev Containers" extension
   - Docker Desktop

2. **Open Repository**

   ```bash
   # Clone and open in VS Code
   git clone https://github.com/Hardcoreprawn/enterprise-iac-repo.git
   cd enterprise-iac-repo
   code .
   ```

3. **Launch DevContainer**
   - Click "Reopen in Container" when prompted
   - Wait 2-3 minutes for setup to complete
   - Run health check: `./health-check.sh`

### Alternative: Manual Setup

If you can't use DevContainers, you'll need to manually install:

- PowerShell 7+
- Azure CLI  
- Terraform
- Git
- Make

Then run `./setup.ps1` to configure the environment.

## ⚡ Daily Workflow

### First Time Configuration

```bash
# Configure for your environment
# Edit local-validation-config.json:
{
  "resourceGroup": "rg-your-test-environment",
  "subscription": "your-subscription-id",
  "runConnectivityTests": true,
  "runSecurityTests": false,
  "runMonitoringTests": false
}

# Sign in to Azure
az login
az account set --subscription "your-subscription-id"

# Install Azure PowerShell modules (on-demand, only when needed)
make install-az
```

### Development Loop

```bash
# 1. Quick validation during development
make validate-dry

# 2. Work on infrastructure changes
# - Edit Terraform files in terraform/
# - Update policies in policies/
# - Modify validation scripts in tests/

# 3. Full validation before commit
make validate

# 4. Commit changes (hooks run automatically)
git add .
git commit -m "feat: add new security policy"
git push
```

## 🎯 Common Tasks

### Run Specific Tests

```bash
make test-connectivity    # Test network connectivity
make test-security       # Validate security compliance
make test-monitoring     # Check monitoring configuration
```

### Terraform Operations

```bash
make plan               # Generate Terraform plan
make apply              # Apply infrastructure changes
make destroy            # Clean up resources
```

### View All Commands

```bash
make help              # Show all available commands
```

## 📋 Enterprise Standards Checklist

Before any deployment, ensure you meet the [Cloud Infrastructure Definition of Done](docs/standards/cloud-infrastructure-definition-of-done.md):

**Security:**

- [ ] MFA enabled for privileged accounts
- [ ] RBAC with least privilege
- [ ] Network security groups configured
- [ ] Encryption at rest and in transit

**Monitoring:**

- [ ] APM and infrastructure monitoring
- [ ] Health checks configured
- [ ] Centralized logging (90-day retention)
- [ ] Critical alerts defined

**Operations:**

- [ ] Infrastructure as Code
- [ ] Automated backups
- [ ] Auto-scaling policies
- [ ] Zero-downtime deployment

**Governance:**

- [ ] Policy enforcement
- [ ] Resource tagging
- [ ] Cost management alerts
- [ ] Documentation updated

## 🚨 Troubleshooting

### DevContainer Issues

```bash
# Container not starting
docker system prune -a

# Tools not installed
./health-check.sh
# Reinstall if needed: ./setup.ps1 -Force

# Install Azure PowerShell modules on-demand
make install-az
```

### Validation Failures

```bash
# Check Azure authentication
az account show

# Run in dry-run mode to debug
make validate-dry

# Check configuration
cat local-validation-config.json
```

### Permission Issues

```bash
# Check Azure permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Verify resource group access
az group show --name "your-resource-group"
```

## 📚 Key Documents

- **[Enterprise Standards](docs/standards/cloud-infrastructure-definition-of-done.md)** - What "done" means
- **[Writing Principles](docs/standards/writing-principles.md)** - How to write clear documentation
- **[DevContainer Guide](.devcontainer/README.md)** - Detailed container setup
- **[Testing Framework](tests/README.md)** - Infrastructure validation details

## 🎓 Learning Path

1. **Day 1**: Get environment working (this guide)
2. **Day 2**: Review enterprise standards and principles
3. **Day 3**: Run through validation framework
4. **Day 4**: Make first infrastructure change
5. **Day 5**: Deploy to test environment

---

**Need Help?** Check the troubleshooting section above or review the detailed documentation in the `docs/` folder.
