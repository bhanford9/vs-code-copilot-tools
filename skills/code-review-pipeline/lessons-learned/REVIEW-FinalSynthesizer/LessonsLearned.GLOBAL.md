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

### Correctness audit may miss behavioral divergence when requirements are inferred from code
Category: Process/Model

When the Correctness audit derives a requirement by reading the new code ("SW goes to DL only") rather than verifying it against the original work item and the pre-existing code path's behavior, it can miss behavioral differences between old and new mechanisms that coexist during a toggle-transition period. Always cross-check: if an old path handles categories {A, B} and the new path handles only {A}, ask whether the omission of {B} was intentional. This type of divergence is invisible inside any single audit but surfaces when the Extensibility auditor's claim about the old path is verified against source. Add this cross-check to synthesis: when a Correctness finding says "✅ Pass" on a category restriction, verify the old code path's category coverage matches.

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

### Predicate duplication and double-evaluation are distinct findings — do not merge them
Category: Process/Model

When the same code element (e.g., a repeated filter predicate) is flagged by Maintainability for DRY violation and by Performance for causing double computation, these are distinct findings even though they share the same root cause. List them as two findings with different severities and recommendations. The Maintainability finding concerns future divergence risk; the Performance finding concerns current overhead. Merging them obscures the independent priority of each concern — a reviewer might fix the predicate duplication (solving Maintainability) without eliminating the double evaluation (solving Performance), or vice versa.

---

### Bool-flag on same class flagged by 3 auditors independently converges to Medium regardless of individual ratings
Category: Process/Model

When Maintainability, Testability, and Extensibility each independently flag a bool constructor parameter on the same new class, the finding should appear in the final report at the highest individual severity (Medium in this case), with a note that 3 auditors converged. The per-auditor severity may be Low for each individually (because the interface already abstracts the flag away), but the triple convergence confirms the finding belongs in the report. Per-auditor Low + 3-auditor convergence → synthesized Medium. Do not drop this finding even though each auditor qualified it with "mitigated by interface."

---

### Floor/ceiling omissions in arithmetic fixes are hard to detect from the diff alone

---

### Single-auditor High findings from Extensibility require a "forward-looking vs. current-blocking" decision at synthesis
Category: Process/Model

When only the Extensibility auditor rates a finding High and no other auditor independently corroborates it, the synthesizer must make an explicit call: is this a current merge blocker, or design guidance for the next feature? The resolution depends on whether the described limitation (e.g., a hardcoded dependency path) would require modifying the same code in the near-term. If the next anticipated requirement is explicitly in the domain roadmap, keep as High. If it is speculative, downgrade to Medium. In either case, mark clearly in the final report that it is "forward-looking" so the developer understands it does not block the current PR's correctness. Never silently omit a single-auditor High — include it with context.

---

### Four-auditor independent convergence on a test gap is the strongest signal in any review
Category: Process/Model

When 4 of 7 auditors independently flag the same missing test file without cross-pollination, treat this as the single most actionable finding in the report — regardless of severity. It should appear first among the Medium issues, with a note that it reflects independent convergence. Even if the correctness audit found no bug, the 4-auditor signal means: a regression in that class would propagate silently. The recommended fix for this signal is always a dedicated test file, not test cases appended to existing files.
Category: Process/Model

When a fix involves replacing one calculation with another (e.g., different distance formula, different denominator), check whether the corrected formula requires a floor or ceiling that the old one did not. These omissions are only discoverable from the acceptance criteria, not from reading the diff. The code looks superficially correct without knowing the original design intent. Flag when the AC describes a minimum/maximum constraint and the code uses a raw expression that could underflow it.
