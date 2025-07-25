# Architectural Decision Records (ADRs)

Compact architectural decisions for the Enterprise Infrastructure as Code Toolkit

## Principle: Architectural Haikus

**Make decisions compact, clear, and only when needed.**

- **Small**: Few sentences, not essays
- **Clear**: Concrete reasoning, not abstract theory  
- **Necessary**: Real problems requiring decisions, not premature optimization
- **Reversible**: Document what we can change later vs what we can't

## ADR-001: DevContainer-First Development (July 22, 2025)

**Decision**: Standardize on DevContainer for development environment

**Why**:

- Eliminates "works on my machine" issues
- Fast team onboarding (2-3 minutes vs hours of tool installation)
- Consistent toolchain across all developers

**Trade-offs**:

- Requires Docker installation
- Less flexibility for developers preferring local setup

**Status**: Active

## ADR-002: Azure DevOps Module Architecture (July 22, 2025)

**Decision**: Modular approach with bootstrap sequence for Azure DevOps automation

**Structure**:

```text
terraform/modules/
├── entra-groups/            # Entra ID security groups and service principals
├── azure-bootstrap/         # Initial Azure setup for Terraform automation  
└── azure-devops-project/    # DevOps project with enterprise standards
```

**Naming**: `{prefix}-{purpose}-{environment}` (configurable prefix for portability)

**Service Principals**: Least privilege with different SPs for different automation levels

**Why**:

- Handles Terraform bootstrap chicken-and-egg problem
- Modular for maintenance without sprawl
- Portable across organizations
- Aligns with enterprise security standards

**Trade-offs**:

- Initial setup requires manual bootstrap steps
- Multiple modules to coordinate
- Requires understanding of deployment sequence

**Status**: Active

## ADR-003: Information Architecture for Agent Continuity (July 22, 2025)

**Decision**: Structure documentation for AI agent handoffs and user continuity

**Structure**:

```text
docs/
├── ADRS.md                    # Architectural decisions (this file)
├── bootstrap-guide.md         # Step-by-step bootstrap procedures
├── module-development.md      # How to create new modules
├── troubleshooting.md         # Common issues and solutions
├── project-overview.md        # Complete project understanding
└── standards/                 # Enterprise standards and principles
```

**Why**:

- AI agents need structured context to pick up work
- Decision traceability prevents repeated discussions
- Operational focus on getting things working
- Knowledge organized by concern area

**Trade-offs**:

- More documentation to maintain
- Need discipline to keep current

**Status**: Active

## ADR-002: On-Demand Azure Module Installation (July 22, 2025)

**Decision**: Install Azure PowerShell modules on-demand rather than during container build

**Why**:

- Container startup: 2-3 minutes vs 5-10 minutes
- Only install what you actually use
- Better development experience

**Trade-offs**:

- Extra step when Azure modules needed
- Slightly more complex module management

**Status**: Active

## ADR-003: Remove Cross-Platform Complexity (July 22, 2025)

**Decision**: Simplify build scripts to assume Linux DevContainer environment

**Why**:

- DevContainer provides consistent Linux environment
- Eliminates conditional logic (`ifeq ($(OS),Windows_NT)`)
- Easier maintenance and debugging

**Trade-offs**:

- Manual setup becomes harder
- Less portable to non-container environments

**Status**: Active

## ADR-004: Eliminate Thin Wrapper Scripts (July 23, 2025)

**Decision**: Remove root-level PowerShell wrapper scripts in favor of Makefile-first architecture

**Why**:

- Reduces complexity - fewer files to maintain and understand
- Eliminates confusion - one clear way to perform operations
- Makefile already provides consistent interface for all operations
- Power users can call scripts directly when needed

**Implementation**:

- **Remove**: `./setup.ps1`, `./install-azure-modules.ps1`, `./test-setup.ps1`
- **Keep**: Makefile targets (`make install-az`, `make validate`, `make test-setup`)
- **Keep**: Implementation scripts in `./scripts/` for direct access

**Trade-offs**:

- Slightly longer commands for power users who bypass Make
- Requires Make knowledge for all operations
- Less "discoverable" - users must know about Makefile

**Status**: Active

## ADR-005: Consolidate Documentation Architecture (July 23, 2025)

**Problem**: Documentation sprawl creates confusion and maintenance overhead. We have duplicate
content across root-level and docs/ directory files, plus scattered information that should be
consolidated.

**Current Issues**:

- Root duplicates: README.md vs docs/project-overview.md
- Quick start duplicates: QUICK-START.md vs docs/quick-start.md  
- PROJECT-OVERVIEW.md duplicates content in docs/
- CONTRIBUTING.md isolated from other docs/standards/ content
- Difficult to find authoritative information source

**Decision**: Consolidate to clean docs/ structure with single root README.md entry point.

**Implementation**:

- **Keep**: Single root `README.md` as project entry point
- **Consolidate**: All detailed docs in `docs/` directory
- **Remove**: Root-level `QUICK-START.md`, `PROJECT-OVERVIEW.md`, `CONTRIBUTING.md`
- **Merge**: Content into appropriate `docs/` files
- **Standards**: Development standards consolidated in `docs/standards/`

**Status**: Active

---

**Format**: Keep each ADR to 3-5 sentences. Focus on the essential decision and reasoning.
