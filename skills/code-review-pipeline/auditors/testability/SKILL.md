# Testability Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`testability`)
3. Read ONLY the files listed in your row — Changeset Input and Pre-built Artifacts
4. Do NOT read `changeset-full.md` or source files unless your row's Changeset Input column explicitly points to them
5. If your Changeset Input is `changeset-full.md`, proceed normally as if you had the full diff
6. If you believe the slice excluded something relevant to your findings, note it in your audit output under a **Dispatcher Coverage Note** section

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/testability/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/testability/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/testability-audit.md`

**Audit report format**: Use the **standard compact format** from `audit-report-template.md`. The testability discriminator field is `**Dimension**: {DependencyInjection | ExternalDependencies | Complexity | LawOfDemeter | HiddenDependencies | ObservableOutcomes}`.

---

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

## 1. Evaluate Testability Dimensions

### Dependency Injection & Boundaries
- Constructor injection vs hard-coded dependencies
- Service locator patterns (anti-pattern)
- Hidden global state

### External Dependencies Behind Adapters
**Are hard-to-test dependencies abstracted?**
- **IO Operations**: File system access wrapped?
- **Network Calls**: HTTP clients, external APIs abstracted?
- **Time/Date**: Clock dependencies injectable?
- **Randomness**: Random number generation controllable?
- **Environment Variables**: Config injectable?
- **Database**: Direct SQL vs repository pattern?

### Complexity & Method Length
**Is code simple enough to test effectively?**
- Cyclomatic complexity (aim for < 10)
- Method length (< 20-30 lines ideal)
- Nested conditionals (avoid deep nesting)
- Long parameter lists
- Multiple responsibilities in single function

### Law of Demeter
**Does code avoid inappropriate intimacy?**
- Chain calls like `obj.getA().getB().getC()`
- Reaching deep into object structures
- Feature envy (using other classes' data more than own)

### Hidden Dependencies
**Are all dependencies visible and explicit?**
- Singletons (hidden global state)
- Static method calls
- Direct instantiation of dependencies
- Framework coupling (tight binding to frameworks)

### Observable Outcomes
**Can test results be easily verified?**
- Pure functions with clear outputs
- Side effects that can be observed
- Return values vs void methods
- State changes accessible for assertion

#### Special Rule — Wildcard Assertions Do Not Pin Output-Equivalence Requirements

When two code paths are required to produce **identical** output (e.g., identical exception messages for non-disclosure), wildcard assertions (`.WithMessage("*{id}*")`) verify only that both contain the variable portion — not that the messages are textually identical. **Severity:** Low when the two paths use the same format-string literal; Medium when there is no shared constant or structural protection against divergence. For output-equivalence requirements, at least one test must assert the exact string.

## 2. Identify Testability Issues

Categorize by severity:

### 🔴 Critical - Code cannot be effectively tested
- Hard-coded external dependencies (network, file system)
- Untestable singletons managing critical state
- No way to inject test doubles
- Extreme complexity (cyclomatic > 20)

### 🟠 High - Testing is very difficult
- Significant Law of Demeter violations
- High coupling to frameworks
- Hidden dependencies
- High complexity (cyclomatic 10-20)
- Long methods (> 50 lines)

### 🟡 Medium - Testing is possible but awkward
- Some hard-coded dependencies
- Moderate complexity
- Minor Law of Demeter issues
- Partial abstraction of external dependencies

### 🟢 Low - Testability is good, minor improvements possible
- Could use better abstractions
- Slight complexity reduction beneficial
- Interface extraction opportunities

## 3. Write Testability Audit Report

Write findings to `/code-review/testability-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

> **Zero-findings rule**: If all dimensions pass, write ONLY the header stats line (all zeros) and `## Clean: All dimensions pass`. Do NOT describe what was analyzed, confirmed, or found to be good. The synthesizer only needs to know what to fix.

## 4. Update LessonsLearned

Write qualifying workflow process improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/testability/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>

