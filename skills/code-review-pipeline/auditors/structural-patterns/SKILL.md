# Structural Patterns Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`structural-patterns`)
3. Read ONLY the files listed in your row — Changeset Input and Pre-built Artifacts
4. Do NOT read `changeset-full.md` or source files unless your row's Changeset Input column explicitly points to them
5. If your Changeset Input is `changeset-full.md`, proceed normally as if you had the full diff
6. If you believe the slice excluded something relevant to your findings, note it in your audit output under a **Dispatcher Coverage Note** section

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/structural-patterns/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/structural-patterns/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/structural-patterns-audit.md`

**Audit report template**: Already in your context from Phase 0. This auditor uses the standard compact format with this finding block field between `**Where**:` and `**Issue**:`:
```
**Pattern**: {SP-XXX — pattern name}
```
Additionally, this auditor's report header includes an extra stats line:
```
**Patterns applied**: {comma-separated list, e.g., SP-001, SP-002, SP-003}
```
And after `## Clean`, two additional sections are required:
```markdown
## Clean Patterns
{Comma-separated list of applied patterns with no issues: e.g., "SP-001, SP-003"}

## Suggested New Catalog Entries
{Draft any new pattern entries observed. Leave blank if none.}
```

---

> This auditor works from an explicit **pattern catalog** — not open-ended heuristics. Apply the catalog faithfully and recommend additions for uncatalogued smells.

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns and false-positive suppressions before beginning analysis.

## 1. Load the Pattern Catalog

Read `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/STRUCTURAL-PATTERN-CATALOG.md` in full.

For each pattern entry, record:
- Pattern ID (e.g., SP-001)
- Signal (what to search for)
- Review question
- Severity guidance

You will apply each pattern independently in step 3.

## 2. Apply Each Pattern to Changed Files

For each pattern in the catalog, scan all changed files for the signal. When a signal appears:

1. Read the surrounding code in context (full method, constructor, or class header)
2. Ask the review question from the catalog
3. Determine whether the question reveals a real problem or a false positive
4. If a real problem, classify severity using the pattern's guidance plus context

**False-positive discipline — do not flag when:**
- The code is in a composition root or DI registration class (concrete types and many dependencies are expected there)
- The class is an explicit integration adapter at the outermost system boundary
- The requirements audit explicitly describes this as an intentional design constraint
- A LessonsLearned entry suppresses this pattern for this codebase

For each dismissed signal, record **why** it was dismissed (this feeds LessonsLearned step 5).

## 3. Identify Structural Pattern Issues

Categorize by severity:

### 🔴 Critical — Structural defect creating a correctness risk
- Gate misplacement where the pre-gate side effect is non-reversible (SP-005 Critical tier)
- Any pattern signal that co-occurs with a bug identified by the Correctness Auditor

### 🟠 High — Structural smell that significantly hinders testability or future change
- SP-002: >6 constructor dependencies spanning separable domains with a clear refactoring seam
- SP-003: Concrete infrastructure type injected into a business/domain-layer class
- SP-004: Tell-Don't-Ask bridge duplicated at multiple call sites
- SP-008: Excessive test arrangement complexity caused by multiple unrelated domains coupled in one class
- SP-009: Untestable business rules, conditional routing, or validation logic mixed with infrastructure calls

### 🟡 Medium — Structural smell worth addressing this sprint or the next
- SP-001: Numbered step comments in a method body
- SP-002: 5–6 constructor parameters with moderate mixing
- SP-004: Single clean Tell-Don't-Ask pass-through (not yet duplicated)
- SP-005: Gate misplacement with a reversible side effect but no compensation path
- SP-008: Arrangement complexity caused by missing abstraction interfaces over infrastructure
- SP-009: Untestable transformation/mapping logic mixed with infrastructure calls

### 🟢 Low — Minor structural observation
- Signal partially applies but the context makes refactoring premature
- Naming that obscures a pattern without fully instantiating it
- SP-009: Untestable path contains only pure plumbing (logging, metrics, retry telemetry) with no business behavior

## 4. Catalog Gap Assessment

After applying all patterns, assess whether you observed any structural smells NOT covered by an existing catalog entry. If so, draft a new catalog entry for each:

- Use the template at the bottom of `STRUCTURAL-PATTERN-CATALOG.md`
- Describe the signal, review question, and severity guidance abstractly (no class names, file paths, or work item IDs)
- Include the draft under **"## Suggested New Catalog Entries"** in your report

> **Important**: Do NOT edit the catalog file yourself during a review. Only document proposed additions in your report.

## 5. Write Structural Patterns Audit Report

Write findings to `/code-review/structural-patterns-audit.md` using the audit report template (already in your context from Phase 0). Use the extended format fields defined in Skill Metadata above.

## 6. Update LessonsLearned

Write qualifying workflow process improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/structural-patterns/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>
