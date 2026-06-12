# Audit Report Template

This file defines the shared report format used by all parallel auditors.
It is read once per batch session in Phase 0 and stays in context throughout.

> **Output budget**: These files are synthesizer input only — not human docs. Write the minimum needed for the synthesizer to make merge/block decisions. Targets: clean-pass ≤400 words, standard ≤600 words, finding-heavy ≤800 words. Omit empty severity sections. No reasoning traces, no codebase tours, no closing summary paragraphs.

---

## Standard Compact Format

Most auditors use this format. Auditor-specific fields are noted in each SKILL.md.

```markdown
# {Auditor Name} Audit — {PASS | MERGE WITH CONDITIONS | BLOCKED}
**Files**: {N} | **🔴**: {N} | **🟠**: {N} | **🟡**: {N} | **🟢**: {N}

## Findings

### 🔴 {Title}
**Where**: [file.cs](file.cs#L10-20)
{AUDITOR-SPECIFIC DISCRIMINATOR FIELD — see skill for this auditor}
**Issue**: {1-3 sentences describing the problem}
**Fix**: {1-3 sentences or short code snippet with the specific remediation}

### 🟠 {Title}
...

### 🟡 {Title}
...

### 🟢 {Title}
...

## Clean
{Comma-separated list of dimensions or areas with no findings}
```

**Rules:**
- Group findings by severity: 🔴 Critical first, then 🟠 High, 🟡 Medium, 🟢 Low
- Every finding must include a `**Where**:` with a markdown file link and line number
- Every finding must include `**Issue**:` and `**Fix**:` — no finding without both
- The `## Clean` section is required even when empty — write "None" if everything had findings
- Use `BLOCKED` verdict only when a Critical finding is present and unresolved
- Use `MERGE WITH CONDITIONS` when High or Medium findings require action before or after merge
- Use `PASS` when only Low findings or none

---

## Auditor-Specific Discriminator Fields

Each auditor adds one identifying field between `**Where**:` and `**Issue**:`:

| Auditor | Discriminator field |
|---|---|
| Ripple Effect | `**Changed**: [file]` + `**Missing update**: [file]` + `**Category**: {CallSite \| SymmetricPath \| CompanionLogic \| ImplicitContract \| DeadActivation}` |
| Unit Test Coverage | `**Requirement**: {Which AC or requirement this gap exposes}` |
| Maintainability | `**Principle**: {SRP \| DRY \| KISS \| YAGNI \| Coupling \| Readability}` |
| Performance | `**Category**: {Memory \| Algorithm \| Network \| Database}` |
| Security | `**Category**: {Injection \| AccessControl \| SensitiveData \| Cryptography \| InputValidation \| Misconfiguration \| Authentication}` + `**OWASP**: {e.g., A03:2021 – Injection}` |
| Extensibility | `**Principle**: {OCP \| DIP \| Coupling \| Configuration \| APIEvolution}` |
| Structural Patterns | `**Pattern**: {SP-XXX — pattern name}` |

Structural Patterns also adds two additional sections after `## Clean`:
```markdown
## Clean Patterns
{Comma-separated list of applied patterns with no issues: e.g., "SP-001, SP-003"}

## Suggested New Catalog Entries
{Draft any new pattern entries observed that are not in the catalog. Leave blank if none.}
```

And a `**Patterns applied**:` line in the header stats:
```
**Patterns applied**: {comma-separated list, e.g., SP-001, SP-002, SP-003}
```

---

## Testability Auditor Exception

The Testability Auditor uses a different, more verbose format defined in its own SKILL.md.
It does not use the compact format above.
