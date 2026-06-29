# Performance Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`performance`)
3. Read ONLY the files listed in your row — Changeset Input and Pre-built Artifacts
4. Do NOT read `changeset-full.md` or source files unless your row's Changeset Input column explicitly points to them
5. If your Changeset Input is `changeset-full.md`, proceed normally as if you had the full diff
6. If you believe the slice excluded something relevant to your findings, note it in your audit output under a **Dispatcher Coverage Note** section

## Caller Context (Section D)

Your Pre-built Artifacts row in the index will include `code-review/symbol-index.md`. This file lists all call sites for each changed public symbol. Use it to:
- Identify callers that may pass large or unbounded collections to changed methods
- Check whether a performance-impacting loop runs once per call or once per element in a larger chain

For each call site you identify as suspicious, use `vscode_listCodeUsages` to trace one level deeper. Do not traverse more than two levels without a clear performance signal — flag "further traversal warranted" as a finding instead.

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/performance/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/performance/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/performance-audit.md`

**Audit report template**: Already in your context from Phase 0. This auditor uses the standard compact format with this finding block field between `**Where**:` and `**Issue**:`:
```
**Category**: {Memory | Algorithm | Network | Database}
```
Include complexity or scale estimates in `**Issue**:` where they strengthen the finding (e.g., "O(n²) over unbounded list"). Use `## Clean` to list dimensions with no findings (e.g., "Memory, Database queries").

---

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

## 1. Evaluate Performance Dimensions

### Memory Performance
- Peak RSS: Large objects allocated? Memory spikes?
- Transient Spikes: Temporary allocations that could be avoided?
- Allocator Pressure: Excessive small allocations? GC pressure?
- Object Lifetime: Objects held longer than necessary?
- Pooling: Should objects be pooled/reused?
- Memory Leaks: Event listeners not cleaned up? Closures capturing too much?
- Caching: Unbounded caches? No eviction policy?

### Algorithmic Efficiency
- Big-O Changes: Did complexity increase (O(n) → O(n²))?
- Unnecessary Operations: Sorting when not needed? Multiple passes?
- Hash Lookups: Linear search when Map/Set would be better?
- Nested Loops: Can inner loops be eliminated?
- Repeated Computation: Calculations done multiple times?

### Concurrency & Network
- Chatty Network Patterns: Multiple sequential API calls that could be batched?
- N+1 Queries: Loop making individual requests?
- Parallel Opportunities: Serial operations that could run in parallel?
- Async/Await Patterns: Blocking when could be non-blocking?

### Database Performance
- N+1 Queries: Loop making individual queries instead of batch?
- Parameterization: Queries parameterized for plan caching?
- Projection: Selecting unnecessary columns?
- Pagination: Large result sets without limits?

## 2. Identify Performance Issues

Severity: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

## 3. Write Performance Audit Report

Write findings to `/code-review/performance-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

## 4. Update LessonsLearned

Write qualifying workflow process improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/performance/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>

