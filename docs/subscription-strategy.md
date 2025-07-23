# Enterprise Azure Subscription Strategy

## Phase 1: Manual Management Subscription Bootstrap

### Initial Setup (Manual)

1. **Create first subscription manually** in Azure portal
   - Use naming: `{org}-mgmt-{environment}` (e.g., "contoso-mgmt-prod")
   - Purpose: Houses platform automation infrastructure
   - NOT for application workloads

2. **Bootstrap platform automation** in management subscription:
   - Terraform state storage
   - Service principals for subscription vending
   - Key Vault for automation secrets
   - Log Analytics for centralized monitoring

### Resources Created in Management Subscription

```text
Management Subscription (contoso-mgmt-prod)
├── Resource Groups
│   ├── rg-contoso-terraform-state
│   ├── rg-contoso-automation-platform
│   └── rg-contoso-monitoring-hub
├── Storage Account (terraform state)
├── Key Vault (automation secrets)
├── Service Principals
│   ├── subscription-vending-sp (Owner at EA/MCA level)
│   ├── landing-zone-deploy-sp (Contributor)
│   └── monitoring-automation-sp (Reader + specific roles)
└── Log Analytics Workspace (centralized logging)
```

## Phase 2: Automated Subscription Vending

### Subscription Vending Pipeline Architecture

Once bootstrap is complete, create automated subscription vending:

```text
Azure DevOps Project: Enterprise Infrastructure
├── Pipeline: subscription-vending.yml
├── Pipeline: landing-zone-deployment.yml
└── Pipeline: monitoring-setup.yml

Subscription Request Flow:
1. Team submits subscription request (JSON/YAML)
2. Approval workflow (Azure DevOps + Teams)
3. Automated subscription creation via Azure CLI/REST API
4. Landing zone deployment via Terraform
5. Monitoring and compliance setup
6. Handoff to team with documentation
```

### Subscription Vending Service Principal Scope

The subscription-vending service principal needs:

- **Enrollment Account Owner** (for EA customers)
- **MCA Invoice Section Contributor** (for MCA customers)
- **Owner** at Management Group level for RBAC assignments

## Phase 3: Enterprise Landing Zones

### Subscription Types to Automate

1. **Sandbox** - Developer experimentation (auto-cleanup)
2. **Dev/Test** - Application development environments
3. **Production** - Live application hosting
4. **Shared Services** - Cross-team shared resources

### Landing Zone Templates

Each subscription type gets:

- Standardized network topology
- Security baseline (Azure Policy assignments)
- Monitoring configuration
- RBAC structure
- Budgets and cost alerts

## Implementation Priority

### Week 1-2: Foundation Bootstrap

- [ ] Manual management subscription creation
- [ ] Terraform state storage setup
- [ ] Service principal creation with proper scopes
- [ ] Initial platform automation deployment

### Week 3-4: Subscription Vending MVP

- [ ] Azure DevOps pipeline for subscription creation
- [ ] Basic landing zone template
- [ ] Approval workflow integration
- [ ] Documentation and runbooks

### Month 2: Enterprise Landing Zones

- [ ] Multiple subscription type templates
- [ ] Policy-driven governance
- [ ] Cost management automation
- [ ] Self-service portal (optional)

## Security Considerations

### Subscription Vending Permissions

- Limit subscription creation to dedicated service principal
- Require approval workflow for all new subscriptions
- Audit trail for all subscription operations
- Regular access reviews for platform automation accounts

### Blast Radius Management

- Management subscription isolated from workload subscriptions
- Platform automation uses least privilege principles
- Cross-subscription access explicitly defined and audited

## State Migration Process

Once the bootstrap infrastructure is deployed:

### 1. Deploy Bootstrap Infrastructure

```bash
cd terraform/foundation
terraform apply
```

### 2. Get Backend Configuration

```bash
terraform output terraform_backend_template
```

### 3. Add Backend Configuration

Add the output to your main Terraform configuration:

```hcl
terraform {
  backend "azurerm" {
    storage_account_name = "stjablabterraformstate12345"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

### 4. Initialize Remote State

```bash
# Authenticate with Azure
az login

# Initialize with new backend
terraform init -migrate-state

# Confirm migration when prompted
```

### 5. Verify Migration

```bash
# Plan should show no changes
terraform plan

# Validate state is stored remotely
az storage blob list --container-name tfstate --account-name <storage-account>
```

## Current Status

### Phase 1: Foundation Bootstrap ✅ Ready

- [x] Azure bootstrap module created with enterprise security
- [x] Service principal automation configured
- [x] Secure state storage with RBAC and auditing
- [x] Diagnostic logging and monitoring
- [ ] **NEXT**: Deploy foundation infrastructure

### Future Phases

- [ ] Build azure-devops-project module
- [ ] Create subscription vending automation
- [ ] Implement landing zone templates
- [ ] Set up governance and compliance automation
