# Enterprise Azure Subscription Standards

Standards for Azure subscription architecture and management in enterprise environments.

## Subscription Architecture Principles

### Management Subscription Pattern

**Principle**: Separate platform automation from application workloads.

**Implementation**:

- Dedicated management subscription for platform automation infrastructure
- Contains Terraform state storage, service principals, centralized monitoring
- Isolated from application workload subscriptions
- Naming pattern: `{org}-mgmt-{environment}` (e.g., "contoso-mgmt-prod")

### Subscription Types

**Standard subscription classifications**:

1. **Management** - Platform automation and shared services
2. **Sandbox** - Developer experimentation with auto-cleanup policies
3. **Development** - Application development environments
4. **Testing** - Pre-production testing environments
5. **Production** - Live application hosting environments

### Security and Governance

**Required security controls**:

- Service principal access follows least privilege principles
- All subscription operations require approval workflow
- Audit trail maintained for all subscription activities
- Regular access reviews for platform automation accounts

**Blast radius management**:

- Management subscription isolated from workload subscriptions
- Cross-subscription access explicitly defined and audited
- Landing zone templates enforce security baselines

## Implementation Requirements

### Management Subscription Setup

**Required resources in management subscription**:

```text
Management Subscription
├── Terraform State Storage
│   ├── Storage account with versioning and soft delete
│   ├── Container for Terraform state files
│   └── RBAC controls for state access
├── Platform Automation
│   ├── Service principals with defined scopes
│   ├── Key Vault for automation secrets
│   └── Managed identities where possible
└── Centralized Monitoring
    ├── Log Analytics workspace
    ├── Application Insights for automation monitoring
    └── Azure Monitor for infrastructure oversight
```

### Service Principal Scoping

**Subscription vending service principal permissions**:

- Enrollment Account Owner (for EA customers)
- MCA Invoice Section Contributor (for MCA customers)
- Owner at Management Group level for RBAC assignments

**Deployment automation service principals**:

- Contributor role at subscription scope
- Specific resource provider permissions as needed
- Time-limited access where possible

### Landing Zone Standards

**Each subscription must include**:

- Standardized network topology following hub-spoke model
- Security baseline via Azure Policy assignments
- Monitoring configuration connected to centralized workspace
- RBAC structure aligned with team responsibilities
- Budget controls and cost alerting
- Compliance scanning and reporting

## Compliance Requirements

### Naming Conventions

**Subscription naming**: `{organization}-{type}-{environment}-{workload}`

Examples:

- `contoso-mgmt-prod` (management)
- `contoso-sandbox-dev-teamalpha` (sandbox)
- `contoso-app-prod-customerportal` (production application)

### Required Governance

**Policy assignments**:

- Security baseline policies applied at subscription creation
- Resource naming convention enforcement
- Location restrictions based on compliance requirements
- Required tagging for cost tracking and governance

**Monitoring requirements**:

- Diagnostic settings configured for all resources
- Activity logs forwarded to centralized workspace
- Security alerts configured for privileged operations
- Cost monitoring and alerting enabled

## Operational Standards

### Lifecycle Management

**Subscription provisioning**:

- Automated via approved workflows
- Landing zone deployment follows standard templates
- Documentation generated automatically
- Team handoff includes access instructions and standards

**Decommissioning process**:

- Data retention policy followed
- Resources cleaned up systematically
- Access revoked through automated process
- Compliance records maintained per requirements

### Access Management

**Access request process**:

- Role-based access following principle of least privilege
- Time-limited access for elevated permissions
- Regular access reviews conducted quarterly
- Emergency access procedures documented and tested
