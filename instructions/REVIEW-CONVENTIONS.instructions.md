# Code Review Agent Conventions

This document defines shared conventions used by all code review agents to ensure consistency and interoperability.

## Output Directory

All audit reports are written to: `/code-review/`

This directory is created automatically if it doesn't exist. Files are overwritten on subsequent reviews.

## File Naming Standards

Each auditor creates a single markdown file named according to its role:

- `requirements-audit.md` - Requirements Auditor output
- `code-correctness-audit.md` - Code Correctness Auditor output
- `unit-test-coverage-audit.md` - Unit Test Coverage Auditor output
- `maintainability-audit.md` - Maintainability Auditor output
- `testability-audit.md` - Testability Auditor output
- `performance-audit.md` - Performance Auditor output
- `extensibility-audit.md` - Extensibility Auditor output
- `final-review.md` - Code Review Orchestrator final synthesis

## Git Changes Scope

All auditors analyze **all changes since the master branch**, including:
- **Committed changes**: All commits on current branch since master (master...HEAD)
- **Uncommitted changes**: Both staged and unstaged modifications (working directory)

The #tool:search/changes tool automatically captures both types. Agents must ensure they review the complete changeset.

## Severity Levels

Use these standardized severity levels in audit reports:

- **🔴 Critical** - Must fix before merge; blocks functionality or causes data loss
- **🟠 High** - Should fix before merge; significant maintainability/performance impact
- **🟡 Medium** - Should address soon; affects code quality or future maintenance
- **🟢 Low** - Nice to have; minor improvements or suggestions

## Report Structure Template

Each auditor should structure their output as:

```markdown
# {Auditor Name} Report

## Summary
{Brief overview of findings - 2-4 sentences}

## Issues & Recommendations

### 🔴 Critical
**{Issue Title}**
- **Location**: [file.ts](file.ts#L10-L20)
- **Problem**: {Clear description of what's wrong}
- **Impact**: {Why this matters}
- **Recommendation**: {Specific actionable steps to fix}

### 🟠 High
{Same structure...}

### 🟡 Medium
{Same structure...}

### 🟢 Low
{Same structure...}

## Conclusion
{1-2 sentence summary of overall assessment}
```

## Actionable Advice Guidelines

All recommendations must be:
1. **Specific** - Reference exact files, lines, functions, or patterns
2. **Actionable** - Provide clear steps the developer can take
3. **Justified** - Explain the impact and why it matters
4. **Constructive** - Frame as improvements, not criticisms

## Context Gathering

Auditors should:
- Read beyond just the changed files when needed for context
- Use semantic search to understand patterns across the codebase
- Look at related tests, documentation, and configuration
- Consider the broader system architecture
