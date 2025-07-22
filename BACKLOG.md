# Project Backlog

Future enhancements and improvements for the Enterprise Infrastructure as Code Toolkit

## High Priority

### Reduce DevContainer Setup Requirements

**Goal**: Replace Docker Desktop requirement with Docker CLI + Docker Engine  
**Current State**: DevContainer requires Docker Desktop installation  
**Target State**: Support Docker CLI + Docker Engine for lighter, cost-free setup  

**Benefits**:

- Lower install cost (Docker Desktop has commercial licensing fees)
- Lighter resource usage
- No licensing concerns for enterprise use
- More accessible to organizations with restricted software policies

**Implementation Notes**:

- Update DevContainer documentation to include Docker CLI setup instructions
- Test DevContainer functionality with Docker Engine vs Docker Desktop
- Update quick start guides and prerequisites
- Verify VS Code Dev Containers extension compatibility

**Complexity**: Medium  
**Impact**: High (accessibility and cost reduction)

## Medium Priority

### Multi-Subscription Support

**Goal**: Support infrastructure deployments across multiple Azure subscriptions  
**Current State**: Single subscription configuration in local-validation-config.json  
**Target State**: Multi-subscription awareness with subscription-specific validation

### Enhanced Terraform Module Library

**Goal**: Build comprehensive library of enterprise-ready Terraform modules  
**Current State**: Basic foundation module structure  
**Target State**: Complete module ecosystem for common infrastructure patterns

## Low Priority

### AWS Support

**Goal**: Extend toolkit to support AWS infrastructure alongside Azure  
**Current State**: Azure-focused with Azure CLI and Azure PowerShell  
**Target State**: Multi-cloud support with AWS CLI and appropriate tooling

### Pipeline Template Library

**Goal**: Comprehensive Azure DevOps pipeline templates for different deployment scenarios  
**Current State**: Basic pipeline structure  
**Target State**: Complete CI/CD template library

## Completed

Items will be moved here when completed

---

**Last Updated**: July 22, 2025  
**Next Review**: As needed based on team priorities
