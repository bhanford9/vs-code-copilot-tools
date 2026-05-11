# Lessons Learned (Global): code-review-pipeline

> This file contains process/model observations applicable to any user of the code-review-pipeline skill.
> Read it before starting a review session. Update it only for `Category: Process/Model` findings.
>
> For codebase-specific discoveries (recurring false positives in this codebase, project-specific patterns),
> write to `LessonsLearned.md` (gitignored, local to your workspace).

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

### Dead code claims require full-file verification
Category: Process/Model

Before including any "dead code" or "unreferenced symbol" finding, verify zero usages across the **entire file** — not just the sections that changed in the PR. Use `Select-String -Path <file> -Pattern <symbol>` or the `search/usages` tool. A symbol removed from one code path may still be referenced by other methods in the same file. An unverified dead-code claim produces a concrete, actionable-looking "remove before merge" finding that is wrong and damages report credibility.

---

### Base branch detection: always strip the full ref prefix in one atomic step
Category: Process/Model

`git symbolic-ref refs/remotes/origin/HEAD` returns the **full ref path** (e.g., `refs/remotes/origin/master`), not just the branch name. If this raw value is written to a session config before stripping, all subsequent `git diff master...HEAD` commands fail or produce wrong results. Fix: either (a) strip inline with `-replace '.*/',''` in the same command that writes the config, or (b) use `git remote show origin | Select-String 'HEAD branch' | ForEach-Object { $_ -replace '.*: ','' }`. Never split the detection and the strip into two sequential commands — the intermediate wrong value can propagate.

---

### Cross-load-category coverage: check for SW (self-weight) in test parametrization
Category: Process/Model

When reviewing toggle-gated fixes where the fix mechanism is `DefaultIfEmpty(0)` replacing `DefaultIfEmpty(NaN)`, verify that the self-weight (SW/null load category) is covered by at least one parametrized test case. SW is the only load category that can produce a genuinely empty `concentratedLoads` list in normal operation, making it the specific category that exercises the `DefaultIfEmpty` sentinel. If test `[TestCase]` attributes enumerate only `CL` and `DL`, the SW path is silently uncovered even when the method name says "when no loads."

---

### Empirical test output supersedes code-tracing for Critical findings
Category: Process/Model

When the developer provides a same-day validation or characterization test run, scan its output (e.g., Differences.xlsx files, test logs) **before** writing any Critical finding into a report. Empirical evidence resolves ambiguities faster than code tracing and can demote a Critical to a Non-Issue before it is published. Requirements and Correctness auditors are prone to flagging a missing code change as Critical when the behavior is already delivered via an emergent side-effect of a different fix. Rule: if validation data is available, analyze it first; rate a finding Critical only when the data confirms the gap, or when no validation data is available.

---

### Worktree-as-master: "all changes since master" requires fallback to explicit commit list
Category: Process/Model

When a repo uses git worktrees and the current worktree branch IS `master` (i.e., `HEAD -> master`), `git log master..HEAD` and `git diff master...HEAD` both return nothing — there is no divergence from master because the branch is master. The request "review all changes since master" has no answer as a branch comparison.

Correct fallback:
1. Detect the empty diff during setup (`git log master..HEAD --oneline` returns nothing)
2. Fall back to the explicit commit(s) identified in the session config or user request
3. Write `reviewMode = 'single-commit'` (or equivalent) to the session config so downstream auditors know the scope

Do NOT silently use the empty diff as the review scope — that produces a review of nothing. Always surface the scope explicitly at the start of the review so the user can confirm.

---

### Toggle-ON test branch dead code: check ToggleBuilder state before trusting if/else test assertions
Category: Process/Model

When a test file declares `_toggles = ToggleBuilder.AllDisabled().Build()` and then branches with `if (_toggles.IsEnabled(SomeToggle)) { ... } else { ... }`, the `if` branch is permanently dead code. The assertions inside will never execute. This pattern appears when a developer updates existing tests for toggle-aware behavior but forgets that the toggle instance is hardcoded to AllDisabled. Before writing Requirements or Correctness findings about toggle-ON test coverage, always verify whether the toggle instance used in the test fixture is AllDisabled vs. explicitly enabled. If AllDisabled, every toggle-ON assertion in the file is dead and should be flagged as a Medium coverage gap.

---

### `disable-model-invocation: true` blocks subagent invocation from trusted callers — use `user-invocable: false` instead
Category: Process/Model

`disable-model-invocation: true` prevents ALL programmatic invocation of an agent, including by an Orchestrator that explicitly lists it in its `agents:` frontmatter array. If sequential pipeline stages are marked `disable-model-invocation: true`, no Orchestrator can ever run them as subagents — the only option left is manual handoff buttons.

The intended behavior in most cases is: hide from the user's agent picker, but still allow trusted caller invocation. That requires `user-invocable: false`, NOT `disable-model-invocation: true`.

Rule: any agent that is meant to be called programmatically by a parent Orchestrator or Coordinator must use `user-invocable: false`. Reserve `disable-model-invocation: true` only for agents that must never be called by any agent under any circumstances.

---

### Special-case load path guard: verify non-numeric load cases before calling MapToJedi2
Category: Process/Model

When reviewing a toggle-gated fix that calls a load-case mapper (e.g., `MapToJedi2`) inside a helper that receives an `AnalysisLoadCase` parameter, always trace which load cases can reach that helper from the outermost callers. In JEDI V2, `AvailableLoadCases` includes `AnalysisLoadCase.Kcs` for KCS-series joists, and those load cases are fed to `ToFactoredResults` via `GetMemberResultsPerLoadCase` — even though the KCS path branches away before consuming the result. Any helper called before that branch that invokes `MapToJedi2()` without guarding for `Kcs`/`Sw`/`TestHarness` will throw `ArgumentOutOfRangeException` when those special load cases arrive. The fix is a guard: `if (loadCase is Kcs or Sw or TestHarness) return false;` placed before the `MapToJedi2()` call. Flag this pattern whenever a new toggle-gated helper performs load-case mapping.

---

### Auto-start lessons learned after the final review report — do not prompt
Category: Process/Model

The `lessons-learned` SKILL.md previously said to "always output a prompt to the user." The `general-agent-behavior` instructions override this: after a named workflow delivers its terminal output, proceed with lessons learned automatically without asking permission. For the code-review pipeline specifically: once `final-review.md` is written and presented, start lessons learned immediately in the same turn rather than prompting the user to type a trigger phrase.

DO: Start the lessons learned session automatically after the final report is presented.
DON'T: Print "type 'lessons learned session'" and wait — the user must not have to ask for this step.

---

### Dead code verification on Windows: use `Get-ChildItem | Select-String` not `Select-String -Recurse`
Category: Process/Model

On Windows PowerShell, `Select-String -Recurse` does not accept a `-Recurse` parameter — it is not a valid flag. Use the pipeline pattern instead: `Get-ChildItem <path> -Recurse -Include "*.cs","*.razor" | Select-String -Pattern <symbol>`. This produces reliable cross-file symbol search results. The `Select-String -Path <file> -Pattern <symbol>` form works for single-file searches. Any auditor or synthesizer that needs to verify a dead-code claim on Windows should use the `Get-ChildItem | Select-String` pattern, not `Select-String -Recurse`.

---

### Static keyword array audits must check substring relationships, not just literal duplicates
Category: Process/Model

When any auditor reviews a classifier, scorer, or categorizer that uses a static string array for `text.Contains(keyword)` matching, both the following defect classes must be checked before reporting confidence:
1. **Literal duplicates** — same string appears at two indices (e.g., `"improve"` at index 5 and 24)
2. **Substring relationships** — keyword A is a proper substring of keyword B, both in the array (`"test"` ⊆ `"testing"`, `"automate"` ⊆ `"automation"`)

Class 2 is more insidious than class 1: the duplicate is visible to a careful reader, but the substring collision is only detectable by systematically testing `B.Contains(A)` for each pair. Both produce inflation in count-based importance scorers where the threshold is close to the inflation delta. The severity is High when the inflation causes misclassification of common task titles — verify against the scoring threshold before rating.


