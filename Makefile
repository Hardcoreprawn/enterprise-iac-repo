# Makefile for DevContainer infrastructure operations
# Optimized for consistent Linux container environment

.PHONY: help validate test test-setup plan apply destroy clean install-hooks install-az

# Default target
help:
	@echo "Infrastructure Toolkit Commands (DevContainer)"
	@echo "=============================================="
	@echo ""
	@echo "Local Development:"
	@echo "  test-setup    - Test that toolkit setup is working correctly"
	@echo "  validate      - Run all validation tests locally"
	@echo "  validate-dry  - Run validation in dry-run mode (fast)"
	@echo "  test          - Run connectivity and compliance tests"
	@echo "  plan          - Generate Terraform plan"
	@echo "  apply         - Apply Terraform configuration"
	@echo "  destroy       - Destroy Terraform resources"
	@echo ""
	@echo "Setup:"
	@echo "  install-hooks - Install git pre-commit hooks"
	@echo "  install-az    - Install Azure PowerShell modules on-demand"
	@echo "  clean         - Clean up temporary files"
	@echo ""
	@echo "Configuration:"
	@echo "  - Edit local-validation-config.json for your environment"
	@echo "  - Set AZURE_SUBSCRIPTION_ID and AZURE_RESOURCE_GROUP env vars"

# Validation commands (DevContainer uses pwsh)
validate:
	@pwsh -ExecutionPolicy Bypass -File "./scripts/validate-local.ps1"

validate-dry:
	@pwsh -ExecutionPolicy Bypass -File "./scripts/validate-local.ps1" -DryRun

# Test commands
test: test-connectivity test-security test-monitoring

test-connectivity:
	@pwsh -ExecutionPolicy Bypass -File "./tests/connectivity/test-network-connectivity.ps1" -TestConfigFile "tests/connectivity/connectivity-tests.json"

test-security:
ifdef AZURE_RESOURCE_GROUP
	@pwsh -ExecutionPolicy Bypass -File "./tests/compliance/validate-security-compliance.ps1" -ResourceGroupName "$(AZURE_RESOURCE_GROUP)"
else
	@echo "Set AZURE_RESOURCE_GROUP environment variable to run security tests"
endif

test-monitoring:
ifdef AZURE_RESOURCE_GROUP
	@pwsh -ExecutionPolicy Bypass -File "./tests/compliance/validate-monitoring-config.ps1" -ResourceGroupName "$(AZURE_RESOURCE_GROUP)"
else
	@echo "Set AZURE_RESOURCE_GROUP environment variable to run monitoring tests"
endif

# Terraform commands
plan:
	@cd terraform && terraform init && terraform plan

apply:
	@cd terraform && terraform init && terraform apply

destroy:
	@cd terraform && terraform destroy

# Setup commands
install-hooks:
	@cp hooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed"

# Azure PowerShell module installation
install-az:
	@pwsh -ExecutionPolicy Bypass -File "./scripts/install-azure-modules.ps1"

# Testing and validation
test-setup:
	@pwsh -ExecutionPolicy Bypass -File "./scripts/test-setup.ps1"

# Cleanup
clean:
	@echo "Cleaning up temporary files..."
	@rm -f validation-report-*.json
	@rm -f compliance-validation-*.json
	@rm -f monitoring-validation-*.json
	@rm -f connectivity-test-*.json
	@echo "Cleanup complete"
