# Lessons Learned: REVIEW-FinalSynthesizer

> Findings specific to synthesis — conflict resolution patterns, cross-auditor themes, false positives in the synthesis step.
> Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

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

## Entry 1 — 2026-04-22

**Session**: AB#37571 — Reinforcement length calculation for sloped joists

**Pattern: Severity discrepancies between auditors are usually a pre-existing vs. introduced distinction, not a factual conflict.**
- Correctness rated `.First()` throw as High; Testability rated it Low. Root cause: the two auditors assessed different risks (correctness risk vs. test coverage risk). Resolution: carry at Medium in final, noting it's pre-existing.
- General rule: when two auditors give the same finding different severities, check whether one auditor is judging the code as introduced-by-this-PR and the other is judging absolute severity. Downgrade to the lower rating when the issue is pre-existing.

**Pattern: The "three auditors flagged this independently" signal is the most reliable escalation indicator.**
- `Is.GreaterThan(43)` weak assertion was flagged independently by Correctness, Unit Test Coverage, and Testability. Zero-length regression was flagged by Requirements, Correctness, Unit Test Coverage, and Maintainability. When 3+ auditors independently identify the same issue without cross-pollination, it belongs in the final report regardless of individual severity.

**Pattern: `Math.Max`-type floor omissions are hard to detect from the diff alone — they require knowing the original design intent.**
- The missing floor was only discoverable because the developer provided the acceptance criteria. Without that, the code looks superficially correct. For future reviews, when a developer says "use `Math.Max(a, b)`" and the code uses only `b`, flag it even if the rationale for the max is not immediately obvious.
