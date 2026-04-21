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
