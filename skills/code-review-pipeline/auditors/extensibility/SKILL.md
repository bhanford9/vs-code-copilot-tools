# Extensibility Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`extensibility`)
3. Read ONLY the files listed in your row — Changeset Input and Pre-built Artifacts
4. Do NOT read `changeset-full.md` or source files unless your row's Changeset Input column explicitly points to them
5. If your Changeset Input is `changeset-full.md`, proceed normally as if you had the full diff
6. If you believe the slice excluded something relevant to your findings, note it in your audit output under a **Dispatcher Coverage Note** section

## Caller Context (Section D)

Your Pre-built Artifacts row in the index will include `code-review/symbol-index.md`. Use it to check whether existing callers would break if a concrete type were replaced with an interface, or whether a new switch case would require updates at all call sites.

For deeper traversal, use `vscode_listCodeUsages` targeted at specific symbols. Flag "shim layer — further traversal warranted" when a call site is itself just a pass-through. Do not traverse more than two levels without a clear extensibility signal.

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/extensibility/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/extensibility/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/extensibility-audit.md`

**Audit report template**: Already in your context from Phase 0. This auditor uses the standard compact format with this finding block field between `**Where**:` and `**Issue**:`:
```
**Principle**: {OCP | DIP | Coupling | Configuration | APIEvolution}
```
Use `## Clean` to list dimensions with no findings (e.g., "Dependency Inversion, API versioning").

---

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

## 1. Evaluate Extensibility Dimensions

### Open/Closed Principle
- Use of inheritance vs composition
- Strategy pattern for variations
- Rigid switch/case statements that need modification for new cases

### Dependency Inversion
- Use of interfaces and abstract classes
- Dependency injection enabling swap-ability
- Hard-coded implementations vs pluggable components

### Extension Points
- Hook methods and callbacks
- Event systems
- Middleware/interceptor patterns
- Template methods
- Configuration-driven behavior

### Coupling & Cohesion
- Circular dependencies preventing changes
- Shotgun surgery (one change requires many file edits)

### Configuration vs Code
- Hard-coded values that should be configurable
- Business rules in code vs configuration
- Feature flags for new functionality

### Data & API Evolution
- Breaking changes to APIs
- Versioning strategy
- Deprecation patterns

## 2. Identify Extensibility Issues

**Before flagging any symbol as dead code or unreferenced:** run a full-file usage search — not just the changed sections. Use `search/usages` or `Select-String -Path <file> -Pattern <symbol>`. A symbol removed from one code path may still be referenced by other methods in the same file. An unverified dead-code finding is the most common extensibility auditor false positive.

Severity: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

## 3. Write Extensibility Audit Report

Write findings to `/code-review/extensibility-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

## 4. Update LessonsLearned

Write qualifying workflow process improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/extensibility/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>

