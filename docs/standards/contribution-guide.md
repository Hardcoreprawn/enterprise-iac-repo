# Contribution Guide

Standards and workflow for contributing to the enterprise infrastructure project.

## Development Environment

**Required**: Use the DevContainer for all development work.

```bash
# Open in DevContainer (VS Code)
# Ctrl+Shift+P -> "Dev Containers: Reopen in Container"

# Verify setup
make test-setup
```

## Development Workflow

### 1. Before Starting Work

```bash
# Pull latest changes
git pull origin main

# Verify environment
make validate-dry
```

### 2. Making Changes

```bash
# Create feature branch
git checkout -b feature/your-change-description

# Work on your changes
# - Edit Terraform files in terraform/
# - Update policies in policies/
# - Modify validation scripts in tests/

# Test changes
make validate
```

### 3. Pre-Commit Validation

```bash
# Full validation before commit
make validate

# Check specific areas
make test-compliance
make test-connectivity
make test-terraform-plan
```

### 4. Commit and Push

```bash
# Git hooks run automatically
git add .
git commit -m "feat: your change description"
git push origin feature/your-change-description
```

## Standards Compliance

All contributions must meet enterprise standards:

- Security: All resources follow security policies
- Compliance: Infrastructure passes all compliance checks
- Documentation: Changes include updated documentation
- Testing: Validation scripts pass without errors
- Naming: Resources follow enterprise naming conventions

## Code Standards

### Terraform

- Use enterprise naming conventions
- Include appropriate resource tags
- Follow module structure patterns
- Include proper variable descriptions

### Documentation

- Follow markdown formatting standards (run `make validate-docs`)
- Use direct, job-focused language (see `docs/standards/writing-principles.md`)
- Update relevant documentation when making changes
- Keep documentation consolidated in `docs/` directory

### PowerShell Scripts

- Use approved verb-noun naming
- Include proper error handling
- Follow enterprise security practices
- Test scripts in DevContainer environment

## Pull Request Process

1. **Create PR** with clear description of changes
2. **Ensure CI passes** - all validation checks must pass
3. **Request review** from appropriate team members
4. **Address feedback** and update as needed
5. **Merge** only after approval and passing checks

## Testing

All changes must pass validation:

```bash
# Quick validation (development)
make validate-dry

# Full validation (pre-commit)
make validate

# Specific test types
make test-compliance      # Policy compliance
make test-connectivity    # Network connectivity
make test-monitoring      # Monitoring configuration
```

## Getting Help

- **Documentation**: Check `docs/` directory for detailed guides
- **Quick Start**: See `docs/quick-start.md` for setup help
- **Standards**: Review `docs/standards/` for requirements
- **Architecture**: See `docs/ADRS.md` for architectural decisions

## Common Issues

### DevContainer Problems

```bash
# Rebuild container
Ctrl+Shift+P -> "Dev Containers: Rebuild Container"

# Check container health
make test-setup
```

### Validation Failures

```bash
# Check Azure authentication
az account show

# Run in debug mode
make validate-dry

# Review specific error logs
# (Check validation output for specific file paths)
```

### Permission Issues

```bash
# Verify Azure permissions
az account list
az role assignment list --assignee $(az account show --query user.name -o tsv)
```
