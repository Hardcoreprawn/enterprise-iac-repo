<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Enterprise Infrastructure as Code Project

This is an enterprise infrastructure automation project using:

- **Terraform** for Infrastructure as Code
- **Azure DevOps** for CI/CD pipelines
- **Azure Policy** for compliance automation
- **Mono-repo structure** for team collaboration

## Coding Standards

- **Direct, not performative language** in all documentation
- **Binary completion** - either done or not done
- **Job-focused** - describe what work needs completing
- **Strict markdown formatting** - all linters must pass
- **Enterprise naming conventions** for all resources

### Markdown Formatting Requirements

**MANDATORY**: All markdown must pass linting without errors. Common violations to avoid:

- **MD022**: Always add blank lines before and after headings
- **MD036**: Never use `**Bold text**` as headings - use proper `### Heading` levels
- **MD040**: All code blocks must specify language: ````bash`, ````json`, ````hcl`
- **MD031**: Code blocks need blank lines before and after
- **MD024**: No duplicate headings in the same document

**Validation workflow**: Always run `get_errors` tool after markdown edits and fix all formatting issues before completing tasks. Use `make validate-docs` for local validation.

## Project Structure

- `terraform/` - Infrastructure as Code with modules and environments
- `policies/` - Azure Policy definitions organized by domain
- `pipelines/` - Azure DevOps pipeline templates
- `docs/` - Standards, architecture docs, and runbooks

## Key Principles

When generating code or documentation:

1. Focus on actual job completion, not aspirational quality
2. Use concrete, testable requirements
3. Apply enterprise security and governance standards
4. Ensure all infrastructure meets defined compliance checkboxes
5. Follow the established mono-repo structure
