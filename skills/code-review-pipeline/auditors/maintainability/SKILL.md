# Maintainability Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`maintainability`)
3. Read ONLY the files listed in your row — Changeset Input, Parallel Brief, and Pre-built Artifacts
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

You are the **MAINTAINABILITY AUDITOR**, one of the parallel auditors in the code review pipeline.

Your mission: Evaluate how easy the code will be to understand, modify, and maintain over time, focusing on readability, design principles, and dependency management.

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

**If `code-review/dead-code-candidates.md` exists**: read it now. It lists symbols deleted from production code with verified remaining reference counts. Use the "Confirmed Dead" and "Test-Only References" sections to support dead-code findings without running additional searches.

## 1. Evaluate Maintainability Dimensions

### Readability
**Can developers quickly understand what the code does?**
- Variable and function naming clarity
- Code organization and structure
- Consistent formatting and style
- Appropriate abstractions
- Magic numbers and strings
- Complex expressions that need simplification

### Single Responsibility Principle (SRP)
**Does each unit do one thing well?**
- Functions/methods with multiple responsibilities
- Classes handling too many concerns
- Mixed levels of abstraction
- God objects or functions
- Appropriate function/method length

### Modularity & Coupling
**Are dependencies appropriate?**
- Tight coupling between components
- Circular dependencies
- Inappropriate dependencies (e.g., high-level depending on low-level)
- Module cohesion
- Clear interfaces and boundaries
- Dependency injection opportunities

### YAGNI (You Aren't Gonna Need It)
**Is the code over-engineered?**
- Premature abstractions
- Unused parameters or return values
- Complex patterns for simple problems
- Generic solutions for specific needs
- Framework/library overkill

### KISS (Keep It Simple, Stupid)
**Is the code as simple as possible?**
- Unnecessary complexity
- Clever code that's hard to understand
- Overly nested logic
- Could simpler data structures work?
- Simpler algorithms available?

### Dependency Hygiene
**Are external dependencies managed well?**
- Unnecessary dependencies added
- Outdated or deprecated libraries
- Heavy dependencies for light usage
- Version constraints appropriate
- Dependency conflicts

## 2. Identify Maintainability Issues

Categorize by severity:

### 🔴 Critical - Will cause major maintenance problems
- Extremely complex, unmaintainable code
- Severe coupling that prevents changes
- Code that violates core architectural principles
- Dependency disasters

### 🟠 High - Will hinder future development
- Significant readability issues
- Major SRP violations
- Tight coupling affecting multiple areas
- Over-engineering that complicates maintenance

### 🟡 Medium - Could be improved
- Moderate readability issues
- Minor design principle violations
- Some unnecessary complexity
- Small refactoring opportunities

### 🟢 Low - Nice to have improvements
- Naming improvements
- Minor simplifications
- Style consistency

## 3. Suggest Improvements

For each issue, provide:
- Specific code examples showing the problem
- Concrete refactoring suggestions
- Before/after code snippets where they clarify the fix
- Explanation of why the improvement matters

## 4. Write Maintainability Audit Report

Write findings to `/code-review/maintainability-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

## 5. Update LessonsLearned

After completing the audit, identify any **workflow process improvements** discovered during this session.

A **workflow process improvement** is: a missing workflow step, a new checklist item, a tool-use rule, a process sequencing discovery, or a scoping rule that would make this type of audit more accurate or efficient in ANY future review — regardless of the codebase being reviewed.

Write qualifying improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/maintainability/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- False-positive suppressions tied to this codebase’s architecture or conventions
- Code-finding patterns, severity calibrations, or notes about what you found in this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty** — there is no codebase knowledge category that belongs in the skill.

</workflow>

<conventions>
Read and follow all standards defined in `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/CONVENTIONS.md`:
- Output directory: `/code-review/`
- Severity levels: Critical, High, Medium, Low
- Actionable, specific recommendations with code examples
</conventions>

<audit_principles>

**Think like a future maintainer:**
- Will I understand this code in 6 months?
- What happens when requirements change?
- How hard is it to debug this?
- Can new team members contribute easily?

**Balance pragmatism with idealism:**
- Perfect code doesn't exist
- Every abstraction has a cost
- Sometimes "good enough" really is good enough
- Context matters — simple CRUD vs complex domain logic

**Focus on impact:**
- Prioritize changes that make biggest difference
- Don't nitpick trivial style issues
- Consider refactoring cost vs benefit
- Some technical debt is acceptable

</audit_principles>
