# Lessons Learned: REVIEW-FinalSynthesizer

> Findings specific to synthesis — conflict resolution patterns, cross-auditor themes, false positives in the synthesis step.
> Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

---

## When to Append an Entry

Only append if the session revealed something surprising about synthesis, a recurring conflict pattern between auditors, or a finding specific to the final-synthesis step. Findings that apply to the entire pipeline should be promoted to the pipeline-level LessonsLearned instead.

---

### Severity disagreement on "dead toggle-ON test branches": Coverage says Critical, others say Medium — resolve to High
Category: Process/Model

When the Unit Test Coverage auditor rates a gap Critical (toggle-ON paths completely untested) but the Code Correctness and Requirements auditors rate the same finding Medium (logic is correct, gap is test-only), the right synthesis resolution is **High**. The rationale: the primary behavioral change of the PR has zero unit test coverage (more severe than Medium), but no runtime bug was found and characterization tests provide empirical coverage (less severe than Critical). Don't let one auditor's severity anchor the final rating — read the cross-auditor evidence and make the judgment call.

---

### DIM factory pattern rated Medium by Maintainability, Low by Extensibility — not a conflict
Category: Process/Model

When Maintainability rates the DIM factory pattern Medium (identity instability, principle of least surprise) and Extensibility rates the same pattern Low (discoverability concern), these are different quality dimensions on the same code element, not contradictory findings. Include both angles in the final report under the single Medium issue — the Extensibility angle is a supporting observation, not a competing rating. Merging them into one finding avoids repeating the same code location twice at different severities.
