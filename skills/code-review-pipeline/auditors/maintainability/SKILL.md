# Maintainability Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`maintainability`)
3. Read ONLY the files listed in your row — Changeset Input and Pre-built Artifacts
4. Do NOT read `changeset-full.md` or source files unless your row's Changeset Input column explicitly points to them
5. If your Changeset Input is `changeset-full.md`, proceed normally as if you had the full diff
6. If you believe the slice excluded something relevant to your findings, note it in your audit output under a **Dispatcher Coverage Note** section

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/maintainability/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/maintainability/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/maintainability-audit.md`

**Audit report template**: Already in your context from Phase 0. This auditor uses the standard compact format with this finding block field between `**Where**:` and `**Issue**:`:
```
**Principle**: {SRP | DRY | KISS | YAGNI | Coupling | Readability}
```
Use `## Clean` to list dimensions with no findings (e.g., "Dependency Hygiene, KISS, YAGNI").

---

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

**If `code-review/dead-code-candidates.md` exists**: read it now. It lists symbols deleted from production code with verified remaining reference counts. Use the "Confirmed Dead" and "Test-Only References" sections to support dead-code findings without running additional searches.

## 1. Evaluate Maintainability Dimensions

### Readability
- Magic numbers and strings
- When a document claims behaviors are "test-verified" or states counts ("N entries," "M providers"), cross-reference against actual code before accepting as fact

### Single Responsibility Principle (SRP)

### Modularity & Coupling
- When an interface method is newly added, scan all changeset callers for ones still using the concrete static/instance method — partial adoption is a coupling finding
- After a toggle-promotion changeset, check classes whose toggle guard was removed for orphaned toggle-bag fields — these compile cleanly and evade dead-code tools; rate Medium

### YAGNI
- New records/DTOs: verify each public property is read by a caller outside the declaring file — unpopulated-write-only properties compile cleanly and are invisible without a usage search

### KISS

### Dependency Hygiene

### DRY: Hotspot Cross-Reference

Slice-based auditing is structurally unlikely to catch DRY violations where each file independently implements the same operation — no single file looks wrong in isolation. Scan all changeset files together and compare any repeated conceptual operation for behavioral drift.

**Common hotspot patterns to look for**:
- String parsing / splitting / trimming (e.g., comma-separated value parsing with varying `.Trim()` / `.Replace(" ", "")` / whitespace normalization)
- Path construction (same directory path assembled independently in multiple files)
- Status or state string matching (e.g., pattern-matched against process output or log lines)
- Null/empty guards repeated inline instead of delegated to a shared utility
- New shared helper extracted from inline logic: verify all pre-existing inline copies were replaced — a helper coexisting with remaining copies creates multi-way divergence
- Multiple new classes in the same namespace: scan private static methods for verbatim duplicates, especially mapping/conversion helpers
- Cross-assembly: when a lower-level assembly (e.g., Core) defines a path-construction method, check higher-level assemblies (ViewModels, UI) for independent re-implementations

**Severity guide**:
- 🟠 High: Two or more implementations of the same logic exist **and** have measurably different behavior (different character classes stripped, different null handling, different edge-case results) — a behavioral inconsistency that can silently produce different outputs depending on which code path runs
- 🟡 Medium: Two or more copies exist but behave identically — pure duplication with no behavioral gap yet, but a future maintainer editing one will miss the other

## 2. Identify Maintainability Issues

Severity: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

## 3. Write Maintainability Audit Report

Write findings to `/code-review/maintainability-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

## 4. Update LessonsLearned

Write qualifying workflow process improvements to `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/maintainability/LessonsLearned.GLOBAL.md`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>

