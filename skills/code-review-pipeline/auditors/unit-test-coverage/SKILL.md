# Unit Test Coverage Audit Skill

## Input Protocol

> **This section governs how this auditor locates its input files. Follow it before doing any other work.**

1. Read `code-review/auditor-input-index.md`
2. Find your row by auditor name (`unit-test-coverage`)
3. Read ONLY the files listed in your row — Changeset Input and Pre-built Artifacts
4. Do NOT read `changeset-full.md` or source files unless your row's Changeset Input column explicitly points to them
5. If your Changeset Input is `changeset-full.md`, proceed normally as if you had the full diff
6. If you believe the slice excluded something relevant to your findings, note it in your audit output under a **Dispatcher Coverage Note** section

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/unit-test-coverage/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/unit-test-coverage/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/unit-test-coverage-audit.md`

**Audit report template**: Already in your context from Phase 0. This auditor uses the standard compact format with this finding block field between `**Where**:` and `**Issue**:`:
```
**Requirement**: {Which AC or requirement this gap exposes}
```
Use `## Clean` to list well-covered areas (e.g., "Happy-path flows, Error handling, Edge cases for X").

---

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

## 1. Analyze Test Coverage

For each changed code element, find corresponding tests using `search/usages` and `file_search`.

Identify:
- New functions/methods added
- Modified functions/methods
- New classes/modules
- Changed business logic
- New API endpoints or interfaces

### Coverage Analysis
- **Are there tests for this code?** Use `search/usages` to find test files
- **Do tests cover all code paths?** Branch coverage, conditional paths
- **Are edge cases tested?** Null, empty, boundary conditions, errors
- **Are requirements verified?** Do tests validate acceptance criteria from the parallel-brief?
- **Are parameters tested through call chains?** Data flows correctly verified

**Before reporting a test as missing**: open the test file and search for the behavior — tests are frequently delivered under a different label but cover the required behavior. A planned method name that doesn't exist is not sufficient evidence of a gap.

## 2. Identify Coverage Gaps

Categorize by severity:

### 🔴 Critical - No tests for critical functionality
- Core business logic untested
- New features completely untested
- Security-critical code untested
- Data validation untested

### 🟠 High - Incomplete coverage of important code
- Major code paths untested
- Error handling untested
- Important edge cases missed
- Integration points not verified

### 🟡 Medium - Good coverage but gaps exist
- Some edge cases missed
- Weak assertions
- Missing negative test cases
- Insufficient boundary testing

### 🟢 Low - Excellent coverage, minor improvements possible
- Additional edge cases for robustness
- More comprehensive parameter testing
- Better test organization

## 3. Write Unit Test Coverage Audit Report

Write findings to `/code-review/unit-test-coverage-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

## 4. Update LessonsLearned

Write qualifying workflow process improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/unit-test-coverage/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>

