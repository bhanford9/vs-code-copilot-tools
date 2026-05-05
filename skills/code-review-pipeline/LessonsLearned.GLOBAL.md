# Lessons Learned (Global): code-review-pipeline

> This file contains process/model observations applicable to any user of the code-review-pipeline skill.
> Read it before starting a review session. Update it only for `Category: Process/Model` findings.
>
> For codebase-specific discoveries (recurring false positives in this codebase, project-specific patterns),
> write to `LessonsLearned.md` (gitignored, local to your workspace).

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

### Auto-start lessons learned after the final review report — do not prompt
Category: Process/Model

The `lessons-learned` SKILL.md previously said to "always output a prompt to the user." The `general-agent-behavior` instructions override this: after a named workflow delivers its terminal output, proceed with lessons learned automatically without asking permission. For the code-review pipeline specifically: once `final-review.md` is written and presented, start lessons learned immediately in the same turn rather than prompting the user to type a trigger phrase.

DO: Start the lessons learned session automatically after the final report is presented.
DON'T: Print "type 'lessons learned session'" and wait — the user must not have to ask for this step.


