<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Enterprise Infrastructure as Code Project - AI Agent Navigation

This file directs AI agents to the relevant project documentation and standards.

## Project Context

Enterprise infrastructure automation project using Terraform, Azure DevOps, Azure Policy, and mono-repo structure.

## Essential Documentation Links

Before working on any task, read the relevant documentation:

**Project Understanding**:
- Project scope and goals: `docs/project-overview.md`
- Technology stack and architecture: `docs/ARCHITECTURE.md`
- Development workflow: `docs/standards/contribution-guide.md`

**Standards and Requirements**:
- Enterprise infrastructure standards: `docs/standards/cloud-infrastructure-definition-of-done.md`
- Azure subscription standards: `docs/standards/azure-subscription-standards.md`
- Writing and documentation principles: `docs/standards/writing-principles.md`
- Architectural decisions: `docs/ADRS.md`

**Getting Started**:
- New team member setup: `docs/quick-start.md`
- Bootstrap process: `docs/bootstrap-guide.md`
- Module development: `docs/module-development.md`

## Coding Standards

**Documentation Style**:
- Follow principles in `docs/standards/writing-principles.md`
- Direct, job-focused language (not performative or aspirational)
- Binary completion criteria (done or not done)
- No emojis in markdown files
- Strict markdown formatting - all linters must pass

**Validation Requirements**:
- Always run `get_errors` tool after markdown edits
- Fix all formatting issues before completing tasks
- Use `make validate-docs` for local validation

## Project Structure

Navigate to appropriate directories based on task:
- `terraform/` - Infrastructure as Code modules and foundation
- `policies/` - Azure Policy definitions organized by domain
- `scripts/` - PowerShell automation scripts
- `tests/` - Compliance and connectivity validation
- `docs/` - All detailed documentation and standards

## Architecture Decisions (ADRs)

Read `docs/ADRS.md` for complete architectural decisions. Key enforcement rules:

**ADR-004: No Thin Wrapper Scripts** - Do NOT create root-level PowerShell wrapper scripts. Use Makefile targets for user interface and direct script access for power users. Prevents complexity and maintenance overhead.

**Implementation**: 
- User operations: `make install-az`, `make validate`, `make test-setup`
- Power users: `./scripts/script-name.ps1` (direct access)
- Never create: `./setup.ps1`, `./install-modules.ps1`, etc.

**ADR-005: Documentation Consolidation** - Maintain single root README.md as entry point, with all detailed documentation in docs/ directory. Do NOT create duplicate documentation files at root level.

**Implementation**:
- Single entry point: Root `README.md` only
- Detailed docs: All in `docs/` directory structure
- Never create: Root-level `QUICK-START.md`, `PROJECT-OVERVIEW.md`, `CONTRIBUTING.md`, etc.
