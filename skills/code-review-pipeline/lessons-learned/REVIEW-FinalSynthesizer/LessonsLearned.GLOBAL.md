# Lessons Learned: REVIEW-FinalSynthesizer

> Findings specific to synthesis — conflict resolution patterns, cross-auditor themes, false positives in the synthesis step.
> Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract synthesis patterns, conflict-resolution heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising about synthesis, a recurring conflict pattern between auditors, or a finding specific to the final-synthesis step. Findings that apply to the entire pipeline should be promoted to the pipeline-level LessonsLearned instead.

---

### Guard-pattern commits have a characteristic finding signature across auditors
Category: Process/Model

Commits that add a "guard" to prevent an existing throw from being reached have a predictable finding profile:
- **Maintainability**: stale "impossible condition" comment in the guarded method (the one with the throw) — the comment was written when the condition was believed impossible, but the guard was added *because* it was observed. Always Medium.
- **Unit Test Coverage**: `Assert.DoesNotThrow` with a non-throwing mock (hollow assertion); `Times.AtLeastOnce` where `Times.Once` is verifiable. Always Medium.
- **Extensibility**: if the guard uses a type-check (`is ISomeSubtype`) rather than a polymorphic dispatch, OCP concern. Medium.
These three appear together on guard-pattern commits. Expect them and verify each one — do not synthesize them away even if they are "obvious."

---

### Severity disagreement on "dead toggle-ON test branches": Coverage says Critical, others say Medium — resolve to High
Category: Process/Model

When the Unit Test Coverage auditor rates a gap Critical (toggle-ON paths completely untested) but the Code Correctness and Requirements auditors rate the same finding Medium (logic is correct, gap is test-only), the right synthesis resolution is **High**. The rationale: the primary behavioral change of the PR has zero unit test coverage (more severe than Medium), but no runtime bug was found and characterization tests provide empirical coverage (less severe than Critical). Don't let one auditor's severity anchor the final rating — read the cross-auditor evidence and make the judgment call.

---

### DIM factory pattern rated Medium by Maintainability, Low by Extensibility — not a conflict
Category: Process/Model

When Maintainability rates the DIM factory pattern Medium (identity instability, principle of least surprise) and Extensibility rates the same pattern Low (discoverability concern), these are different quality dimensions on the same code element, not contradictory findings. Include both angles in the final report under the single Medium issue — the Extensibility angle is a supporting observation, not a competing rating. Merging them into one finding avoids repeating the same code location twice at different severities.

---

### All-Medium/Low landscape: synthesis job shifts to de-duplication, not conflict resolution
Category: Process/Model

When no auditor returns Critical or High findings, the synthesizer's primary task shifts from resolving factual conflicts to collapsing redundant entries. The same code element will often be flagged by 2–4 auditors at different severities. Merge all flags on the same element into a single entry at the highest reported severity. De-duplicate first, then sort. Do not list the same code location multiple times at different severities.

---

### Same-element multi-severity spread on newly-introduced code resolves to the highest rating
Category: Process/Model

The pre-existing downgrade rule ("downgrade severity when the issue is pre-existing") does not apply to code introduced in the commit itself. When two auditors independently rate a gap in newly-written code as Medium, carry it as Medium — do not downgrade because a third auditor rated the same element Low. The pre-existing distinction only applies when the code existed before the PR.

---

### Severity discrepancies between auditors are usually a pre-existing vs. introduced distinction, not a factual conflict
Category: Process/Model

When two auditors give the same finding different severities, check whether one is judging it as code introduced by the PR and the other is judging absolute severity. Downgrade to the lower rating when the issue is pre-existing. Factual conflicts (two auditors assert opposite facts) require verification; severity disagreements require the pre-existing/introduced distinction check.

---

### The "three or more auditors flagged this independently" signal is the most reliable escalation indicator
Category: Process/Model

When 3+ auditors independently identify the same issue without cross-pollination, include it in the final report regardless of each individual severity rating. Independent convergence is stronger evidence than any single auditor's rating. This applies even when the per-auditor severity is Low — if all of them see it, it belongs in the report.

---

### Floor/ceiling omissions in arithmetic fixes are hard to detect from the diff alone
Category: Process/Model

When a fix involves replacing one calculation with another (e.g., different distance formula, different denominator), check whether the corrected formula requires a floor or ceiling that the old one did not. These omissions are only discoverable from the acceptance criteria, not from reading the diff. The code looks superficially correct without knowing the original design intent. Flag when the AC describes a minimum/maximum constraint and the code uses a raw expression that could underflow it.
