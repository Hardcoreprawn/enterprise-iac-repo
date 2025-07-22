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

---

**Format**: Keep each ADR to 3-5 sentences. Focus on the essential decision and reasoning.
