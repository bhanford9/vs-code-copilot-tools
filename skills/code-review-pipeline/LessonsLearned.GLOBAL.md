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

### Empirical test output supersedes code-tracing for Critical findings
Category: Process/Model

When the developer provides a same-day validation or characterization test run, scan its output (e.g., Differences.xlsx files, test logs) **before** writing any Critical finding into a report. Empirical evidence resolves ambiguities faster than code tracing and can demote a Critical to a Non-Issue before it is published. Requirements and Correctness auditors are prone to flagging a missing code change as Critical when the behavior is already delivered via an emergent side-effect of a different fix. Rule: if validation data is available, analyze it first; rate a finding Critical only when the data confirms the gap, or when no validation data is available.
