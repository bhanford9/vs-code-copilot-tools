# Lessons Learned (Global): code-review-pipeline

> This file contains process/model observations applicable to any user of the code-review-pipeline skill.
> Read it before starting a review session. Update it only for `Category: Process/Model` findings.
>
> For codebase-specific discoveries (recurring false positives in this codebase, project-specific patterns),
> write to `LessonsLearned.md` (gitignored, local to your workspace).

---

### Structural refactoring commits: flag toggle evaluation timing shift as a targeted correctness check
Category: Process/Model

When a private `BuildX()` method is extracted into a factory `Build()` method, pay attention to **when** toggle checks inside the old method were evaluated. If the old method was called once at construction time (e.g., in a constructor body), the toggle was evaluated once. If the factory `Build()` is called multiple times per request (e.g., once for left and once for right seat), the toggle is evaluated N times. This is almost always equivalent, but it is worth noting for the correctness auditor if toggle values could theoretically change between calls within a single request. Frame it as a "verify immutability" check rather than a "defect" finding — 9 times out of 10 it is a non-issue, but it is easy to overlook and cheap to verify.

---

### Method-extraction refactors: "field removed, parameter retained" is a valid pattern — not an orphan
Category: Process/Model

When a private method is extracted out of a class into a factory, some constructor parameters of the original class may appear to lose their field assignment in the diff (the `private readonly _x = x;` line is removed). Do NOT flag this as an orphaned parameter or a bug. It means the parameter had **two usages** before the extraction:

1. Stored as a field to feed the now-removed private method
2. Used directly inline in the constructor body to construct other objects (no field needed)

After extraction, usage (1) disappears (the factory gets the service via its own DI injection), but usage (2) remains. The parameter must stay; only the field assignment goes. Check the full constructor body for inline usages before writing a "dead parameter" finding. Typical examples: any service that is used both by the extracted method AND by other inline object construction within the same constructor — the field assignment disappears while the parameter remains because the latter usage survives.

---

### Keyword/scoring array audits: check for duplicates AND substring relationships
Category: Process/Model

When auditing a classification or scoring engine that uses a static string array for keyword matching against free text (e.g., an importance scorer, a crisis keyword detector, a category classifier), always check for two defect classes:

1. **Literal duplicates** — the same keyword string appears at two different indices. If the scorer counts `hits.Count` over the full array, a single text match produces a count of 2 instead of 1. Causes inflated scores for any text containing that keyword.

2. **Substring relationships** — keyword A is a proper substring of keyword B (both in the array). Any text containing B will also match A, producing a count of 2 from a single textual concept. Common pairs: `"test"` / `"testing"`, `"automate"` / `"automation"`, `"doc"` / `"documentation"`.

Both defects are invisible in happy-path tests (single keyword, no overlap) and only emerge when reviewing the array contents directly. Detection steps:
- Scan the array for literal duplicates (sort and compare adjacent, or use a Set)
- For each pair (A, B), test `B.Contains(A, StringComparison.Ordinal)` — if true, text containing B will double-count

Flag these as High severity when the scoring threshold is close to the overcounting delta (e.g., threshold=3, duplicate adds +1 → a 2-keyword task becomes incorrectly "important").

---

### Always invoke REVIEW-ParallelAuditCoordinator — never call specialist auditors directly
Category: Process/Model

When the orchestrator reaches the parallel phase of a code review, it must invoke `REVIEW-ParallelAuditCoordinator` as a single subagent call — **never** call each specialist auditor (`UnitTestCoverage`, `Maintainability`, `Performance`, `Security`, `Extensibility`, `RippleEffect`, `Testability`) individually and sequentially. The `runSubagent` tool blocks until the called agent finishes; looping through 7 sequential `runSubagent` calls produces a fully serial execution even though the agents are labeled "parallel." The `ParallelAuditCoordinator` exists precisely to solve this: it launches all 7 as concurrent subagents from within a single agent turn. Calling specialists directly one-by-one is always wrong at the orchestrator level.

---

### Dead code claims require full-file verification
Category: Process/Model

Before including any "dead code" or "unreferenced symbol" finding, verify zero usages across the **entire file** — not just the sections that changed in the PR. Use `Select-String -Path <file> -Pattern <symbol>` or the `search/usages` tool. A symbol removed from one code path may still be referenced by other methods in the same file. An unverified dead-code claim produces a concrete, actionable-looking "remove before merge" finding that is wrong and damages report credibility.


---

### Null/empty-sentinel coverage: verify the sentinel-triggering input is present in parametrized tests
Category: Process/Model

When reviewing a toggle-gated fix whose mechanism is replacing one sentinel value with another (e.g., `DefaultIfEmpty(safeDefault)` replacing `DefaultIfEmpty(badDefault)`), verify that at least one parametrized test case supplies the specific input that produces an empty or null collection — the only input that actually exercises the sentinel path. If the `[TestCase]` attributes enumerate only the typical non-empty inputs, the sentinel path is silently uncovered even when the method name says "when no items."

---

### Empirical test output supersedes code-tracing for Critical findings
Category: Process/Model

When the developer provides a same-day validation or characterization test run, scan its output (e.g., Differences.xlsx files, test logs) **before** writing any Critical finding into a report. Empirical evidence resolves ambiguities faster than code tracing and can demote a Critical to a Non-Issue before it is published. Requirements and Correctness auditors are prone to flagging a missing code change as Critical when the behavior is already delivered via an emergent side-effect of a different fix. Rule: if validation data is available, analyze it first; rate a finding Critical only when the data confirms the gap, or when no validation data is available.


---

### Toggle-ON test branch dead code: check ToggleBuilder state before trusting if/else test assertions
Category: Process/Model

When a test file uses an all-features-disabled toggle fixture (e.g., built with a builder pattern that disables every flag by default) and then branches assertions with `if (toggles.IsEnabled(SomeFeature)) { ... } else { ... }`, the `if` branch is permanently dead code. The assertions inside will never execute. This pattern appears when a developer updates existing tests for toggle-aware behavior but forgets that the toggle instance is hardcoded to all-disabled. Before writing Requirements or Correctness findings about toggle-ON test coverage, always verify whether the toggle instance used in the test fixture is all-disabled vs. explicitly enabled. If all-disabled, every toggle-ON assertion in the file is dead and should be flagged as a Medium coverage gap.


---

### Special-case value guard: verify non-standard enum values before calling downstream mappers
Category: Process/Model

When reviewing a toggle-gated fix that calls a mapper or converter inside a helper that receives a typed enum parameter, always trace which enum values can reach that helper from the outermost callers. Some enum values may represent "special" or "sentinel" cases (e.g., test harness modes, placeholder values, non-numeric identifiers) that the downstream mapper does not handle and will throw on. Any helper called before a branch that filters those values, but that itself invokes the mapper without guarding for the special cases, will throw at runtime when those values arrive. The fix is a guard placed before the mapper call: `if (value is SpecialCaseA or SpecialCaseB) return fallback;`. Flag this pattern whenever a new toggle-gated helper performs enum-to-type mapping on a parameter whose full value range is not filtered upstream.


---

### Dead code verification on Windows: use `Get-ChildItem | Select-String` not `Select-String -Recurse`
Category: Process/Model

On Windows PowerShell, `Select-String -Recurse` does not accept a `-Recurse` parameter — it is not a valid flag. Use the pipeline pattern instead: `Get-ChildItem <path> -Recurse -Include "*.cs","*.razor" | Select-String -Pattern <symbol>`. This produces reliable cross-file symbol search results. The `Select-String -Path <file> -Pattern <symbol>` form works for single-file searches. Any auditor or synthesizer that needs to verify a dead-code claim on Windows should use the `Get-ChildItem | Select-String` pattern, not `Select-String -Recurse`.

---

### Environment lifecycle verification is required for conditional skip decisions that test mutable state
Category: Process/Model

When auditing a conditional skip (e.g., "skip this step if flag X is set"), always trace the **full lifecycle** of flag X — not just where it is set, but where it is cleared. Specifically:

1. Find every call site that sets flag X to a truthy value
2. Find every call site that resets flag X to null/false
3. Map those calls against the flow execution order: does reset happen **before** the guarded step on every path where it should not skip?

This is particularly easy to overlook when the flag is set inside a nested sub-flow and the guarded step is in an outer loop that reruns. A developer reading the conditional skip logic in isolation may not trace whether the flag is still set from the previous iteration's nested sub-flow. On the other hand, a framework-level reset at the start of the outer iteration may silently make the logic safe — but only if you verify it exists.

Rule: for any "is state X set?" check in a conditional gate, verify that X is cleared by a reliable mechanism before the gate is re-evaluated in any subsequent pass.



