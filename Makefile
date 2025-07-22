# Makefile for portable infrastructure operations
# Works across Windows, Linux, and macOS environments

.PHONY: help validate test plan apply destroy clean install-hooks

# Default target
help:
	@echo "Infrastructure Toolkit Commands"
	@echo "==============================="
	@echo ""
	@echo "Local Development:"
	@echo "  validate      - Run all validation tests locally"
	@echo "  validate-dry  - Run validation in dry-run mode (fast)"
	@echo "  test          - Run connectivity and compliance tests"
	@echo "  plan          - Generate Terraform plan"
	@echo "  apply         - Apply Terraform configuration"
	@echo "  destroy       - Destroy Terraform resources"
	@echo ""
	@echo "Setup:"
	@echo "  install-hooks - Install git pre-commit hooks"
	@echo "  clean         - Clean up temporary files"
	@echo ""
	@echo "Configuration:"
	@echo "  - Edit local-validation-config.json for your environment"
	@echo "  - Set AZURE_SUBSCRIPTION_ID and AZURE_RESOURCE_GROUP env vars"

# Validation commands
validate:
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File "./validate-local.ps1"
else
	@pwsh -ExecutionPolicy Bypass -File "./validate-local.ps1"
endif

validate-dry:
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File "./validate-local.ps1" -DryRun
else
	@pwsh -ExecutionPolicy Bypass -File "./validate-local.ps1" -DryRun
endif

# Test commands
test: test-connectivity test-security test-monitoring

test-connectivity:
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File "./tests/connectivity/test-network-connectivity.ps1" -TestConfigFile "tests/connectivity/connectivity-tests.json"
else
	@pwsh -ExecutionPolicy Bypass -File "./tests/connectivity/test-network-connectivity.ps1" -TestConfigFile "tests/connectivity/connectivity-tests.json"
endif

test-security:
ifdef AZURE_RESOURCE_GROUP
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File "./tests/compliance/validate-security-compliance.ps1" -ResourceGroupName "$(AZURE_RESOURCE_GROUP)"
else
	@pwsh -ExecutionPolicy Bypass -File "./tests/compliance/validate-security-compliance.ps1" -ResourceGroupName "$(AZURE_RESOURCE_GROUP)"
endif
else
	@echo "Set AZURE_RESOURCE_GROUP environment variable to run security tests"
endif

test-monitoring:
ifdef AZURE_RESOURCE_GROUP
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File "./tests/compliance/validate-monitoring-config.ps1" -ResourceGroupName "$(AZURE_RESOURCE_GROUP)"
else
	@pwsh -ExecutionPolicy Bypass -File "./tests/compliance/validate-monitoring-config.ps1" -ResourceGroupName "$(AZURE_RESOURCE_GROUP)"
endif
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
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File "./hooks/pre-commit.ps1" -Install
else
	@cp hooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed"
endif

# Cleanup
clean:
	@echo "Cleaning up temporary files..."
ifeq ($(OS),Windows_NT)
	@if exist "validation-report-*.json" del "validation-report-*.json"
	@if exist "compliance-validation-*.json" del "compliance-validation-*.json"
	@if exist "monitoring-validation-*.json" del "monitoring-validation-*.json"
	@if exist "connectivity-test-*.json" del "connectivity-test-*.json"
else
	@rm -f validation-report-*.json
	@rm -f compliance-validation-*.json
	@rm -f monitoring-validation-*.json
	@rm -f connectivity-test-*.json
endif
	@echo "Cleanup complete"
