# Contributing Guide

How to contribute to the Enterprise Infrastructure as Code Toolkit

## Before You Start

1. **Read the fundamentals**:
   - [Quick Start Guide](docs/quick-start.md) - Get your environment working
   - [Project Overview](docs/project-overview.md) - Understand the project structure
   - [Writing Principles](docs/standards/writing-principles.md) - How we write documentation

2. **Set up your environment**:
   - Use the DevContainer for consistent development (much faster setup now!)
   - Configure `local-validation-config.json` for your Azure environment
   - Install Azure PowerShell modules when needed: `make install-az`
   - Run `make validate-dry` to ensure everything works

## Making Changes

### Development Workflow

1. **Create Feature Branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Edit infrastructure code in `terraform/`
   - Update policies in `policies/`
   - Modify validation tests in `tests/`
   - Update documentation as needed

3. **Validate Locally**

   ```bash
   # Quick validation during development
   make validate-dry
   
   # Full validation before commit
   make validate
   ```

4. **Commit Changes**

   ```bash
   git add .
   git commit -m "feat: add new security policy for storage accounts"
   git push origin feature/your-feature-name
   ```

5. **Create Pull Request**
   - Use a clear, descriptive title
   - Include summary of changes
   - Reference any related issues

### Commit Message Format

Use conventional commit format:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions or modifications
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

Examples:

```text
feat: add Azure Storage account security policy
fix: correct network security group validation
docs: update quick start guide for new team members
test: add compliance validation for encryption requirements
```

## Code Standards

### Infrastructure Code (Terraform)

- **Use modules** for reusable components
- **Include documentation** (README.md) for each module
- **Add variables and outputs** with descriptions
- **Follow naming conventions**: lowercase, hyphens for separation
- **Include resource tags** for governance

### Validation Scripts (PowerShell)

- **Use approved verbs** (Get, Set, Test, New, Remove)
- **Include parameter validation** and help text
- **Return structured data** (objects, not strings)
- **Use try/catch** for error handling
- **Write output suitable for automation**

### Documentation (Markdown)

- **Follow writing principles** - direct, not performative
- **Use binary completion** - done or not done
- **Include concrete examples** with commands
- **Pass markdown linting** (davidanson.vscode-markdownlint)
- **Structure for scanning** - headings, lists, code blocks

## Testing Requirements

### Before Committing

All changes must pass local validation:

```bash
# Run all validation tests
make validate

# Run specific test types
make test-connectivity    # Network connectivity
make test-security       # Security compliance
make test-monitoring     # Monitoring configuration
```

### Infrastructure Changes

For Terraform changes:

1. **Test in development environment** first
2. **Run terraform plan** and review changes
3. **Validate against enterprise standards**
4. **Include documentation updates**

### Policy Changes

For Azure Policy changes:

1. **Test policy definitions** in development subscription
2. **Validate compliance rules** against existing resources
3. **Update compliance validation scripts** if needed
4. **Document impact and remediation steps**

## Documentation Standards

### Required Documentation

Every component needs:

- **README.md** - Purpose, usage, configuration
- **Examples** - Working code samples
- **Prerequisites** - Required tools and permissions
- **Troubleshooting** - Common issues and solutions

### Documentation Review

Before submitting:

1. **Check for clarity** - Can a new team member follow it?
2. **Verify examples** - Do code samples actually work?
3. **Test instructions** - Follow your own guide from scratch
4. **Run markdown linting** - Fix all formatting issues

## Review Process

### Pull Request Requirements

- [ ] All validation tests pass
- [ ] Code follows established patterns
- [ ] Documentation updated
- [ ] Examples work as documented
- [ ] Commit messages follow format

### Review Criteria

Reviewers check for:

1. **Standards Compliance** - Meets enterprise standards
2. **Code Quality** - Follows established patterns
3. **Documentation** - Clear and actionable
4. **Testing** - Adequate validation coverage
5. **Security** - No security anti-patterns

## Getting Help

### Resources

- **Project Documentation** - Start with [docs/project-overview.md](docs/project-overview.md)
- **Enterprise Standards** - Review [Definition of Done](docs/standards/cloud-infrastructure-definition-of-done.md)
- **Validation Framework** - See [tests/README.md](tests/README.md)

### Troubleshooting

- **Environment Issues** - See [docs/quick-start.md](docs/quick-start.md) troubleshooting section
- **Validation Failures** - Run `make validate-dry` for detailed output
- **DevContainer Problems** - Run `./health-check.sh` to diagnose

### Getting Support

1. **Check existing documentation** first
2. **Search closed issues** for similar problems
3. **Create new issue** with clear description and steps to reproduce
4. **Include environment details** (OS, tools versions, configuration)

## Project Maintenance

### Regular Tasks

- **Update dependencies** (Terraform providers, CLI tools)
- **Review enterprise standards** quarterly
- **Validate documentation** against actual usage
- **Clean up unused code** and configurations

### Quality Assurance

- **Monitor validation test results**
- **Review and update compliance rules**
- **Ensure documentation stays current**
- **Test new team member onboarding process**

---

**Questions?** Create an issue or check the existing documentation in the `docs/` folder.
