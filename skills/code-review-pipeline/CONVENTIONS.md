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
- `security-audit.md` - Security Auditor output
- `ripple-effect-audit.md` - Ripple Effect Auditor output
- `structural-patterns-audit.md` - Structural Patterns Auditor output
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

Each auditor structures their output as a compact, header-grouped finding list. No intro prose, no summary section, no conclusion. The verdict in the report header is the summary.

```markdown
# {Auditor Name} Audit — {PASS | MERGE WITH CONDITIONS | BLOCKED}
**Files**: {N} | **🔴**: {N} | **🟠**: {N} | **🟡**: {N} | **🟢**: {N}

### 🔴 {Issue Title}
- **Where**: [file.cs](file.cs#L10-20)
- **Issue**: {1-2 sentences — what is wrong}
- **Fix**: {1-2 sentences — specific remediation}

### 🟡 {Issue Title}
- **Where**: ...
- **Issue**: ...
- **Fix**: ...

## Clean
{Comma-separated list of areas with no findings, or "None"}
```

**Rules:**
- Omit severity sections entirely when empty — never write an empty `### 🟢` block
- Do not write a `## Summary` or `## Conclusion` section — the header verdict and finding list are sufficient
- One `**Where**:` link per finding; if multiple locations, list them on the same line

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

## Output Token Budget — Intermediate Audit Files

All `*-audit.md` files (except `final-review.md`) are consumed only by the FinalSynthesizer — **not by humans**. Write the minimum content needed for the synthesizer to make accurate merge/block decisions.

**Word-count targets:**
- Clean-pass audit (0 findings, or only 🟢 Low): ≤400 words
- Standard audit (1–4 findings): ≤600 words
- Finding-heavy audit (5+ findings): ≤800 words

**Do NOT include:**
- Reasoning traces, exploratory analysis, or "I checked X and found Y" walkthrough prose
- Background or codebase tour sections
- Headers for empty severity levels — omit the section entirely
- Closing summary paragraphs that restate the verdict already in the header
- Any sentence that does not carry a finding, a fix, or a severity judgment

**Compact field rules:**
- `## Clean` section: one comma-separated list, not a paragraph
- `**Issue**:` and `**Fix**:` fields: 1–2 sentences each, 3 sentences maximum
- If a finding has only Low severity, the entire findings section should fit in ≤150 words

## Auditor Input Index Protocol

All parallel specialist auditors (Stage 5) MUST follow this input protocol:

1. **Read `code-review/auditor-input-index.md` first** — before reading any other audit input
2. **Find your row** in the index by auditor name (first column)
3. **Read only the files listed in your row** — Changeset Input, Parallel Brief, and Pre-built Artifacts
4. **Do NOT read `changeset-full.md`** unless your row's Changeset Input column explicitly points to it
5. **Slice precedence:** if your row points to a slice file in `code-review/slices/`, that slice IS your changeset — treat it as authoritative
6. **Dispatcher Coverage Note:** if you believe your slice excluded relevant content, add a `## Dispatcher Coverage Note` section to your audit output describing what you believe is missing and why — do not silently compensate by reading the full file

The `auditor-input-index.md` is written by `REVIEW-ChangesetDispatcher` in Stage 2. If it does not exist when Stage 5 launches, the pipeline gate check will have already caught that condition.
