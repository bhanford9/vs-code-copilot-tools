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

### Save/restore pattern commits produce a predictable four-auditor finding cluster
Category: Process/Model

Commits that add a "save last valid state → restore on fallback" pattern have a characteristic cross-auditor profile:
- **Correctness**: Flags the defensive `index < 0` skip path as untested (Medium) and resolves equality semantics (key correctness question that must be answered before the audit can pass).
- **Coverage**: Flags the same `index < 0` path and separately flags the `Reset()` null-clear behavior as untested (second Medium, distinct location).
- **Testability**: Flags any round-trip test that verifies state but omits verification of the side effect (fit call) triggered by that state change (Medium).
- **Extensibility**: Flags the unenforced co-required step pairing — the "always call StepB after StepA" invariant with no structural enforcement (Medium).

When a save/restore commit arrives, expect all four of these findings to appear independently. Synthesize them as four distinct Medium issues rather than collapsing them — they have different locations, different recommended fixes, and different regression risks.

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

### Dead-code-with-active-duplicate requires caller-layer verification before rating High
Category: Process/Model

When Maintainability flags "dead code that duplicates an existing active implementation," verify the claim across the full solution (not just the changed layer) before accepting the High severity. The active callers may exist in sibling layers (DomainModel, DevTools, ServiceLayer) using the existing implementation — not the new one. The finding is still valid (dead code + latent ambiguity), but the verification step surfaces whether the "ambiguity" is theoretical (no current import overlap) vs. immediate (same file already imports both). This matters for severity: theoretical latent ambiguity = Medium; immediate compile error = High. Do not accept the Maintainability auditor's severity without the cross-layer caller check.

---

### Predicate duplication and double-evaluation are distinct findings — do not merge them
Category: Process/Model

When the same code element (e.g., a repeated filter predicate) is flagged by Maintainability for DRY violation and by Performance for causing double computation, these are distinct findings even though they share the same root cause. List them as two findings with different severities and recommendations. The Maintainability finding concerns future divergence risk; the Performance finding concerns current overhead. Merging them obscures the independent priority of each concern — a reviewer might fix the predicate duplication (solving Maintainability) without eliminating the double evaluation (solving Performance), or vice versa.

---

### Dev-tool-plus-Framework-hook PRs: Framework API convergence dominates; DevTools findings stay at per-auditor ratings
Category: Process/Model

When a PR introduces BOTH a Framework-layer extension hook (e.g., a new public method on a generic infrastructure class) AND a concrete DevTools implementation that uses it, expect an asymmetric convergence pattern:
- The Framework API's test gap will collect the highest independent-auditor count (3+) because Coverage, Testability, and Ripple Effect all identify the same behavioral contract gap from different angles
- The DevTools layer findings each appear in only 1 auditor's report — even when multiple auditors look at them — because DevTool isolation, real-disk I/O, and non-testability arguments naturally dampen cross-auditor escalation

Synthesis implication: Apply the 3+ independent flag rule to escalate the Framework finding to High; keep DevTools findings at their per-auditor ratings (do not attempt to escalate them via analogy with the Framework finding). The two layers have genuinely different severity thresholds.

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

---

### Floor/ceiling omissions in arithmetic fixes are hard to detect from the diff alone
Category: Process/Model

When a fix involves replacing one calculation with another (e.g., different distance formula, different denominator), check whether the corrected formula requires a floor or ceiling that the old one did not. These omissions are only discoverable from the acceptance criteria, not from reading the diff. The code looks superficially correct without knowing the original design intent. Flag when the AC describes a minimum/maximum constraint and the code uses a raw expression that could underflow it.

---

### Ripple Effect "Critical" means blast-radius severity, not runtime bug — resolve to High in synthesis
Category: Process/Model

The Ripple Effect Auditor uses "Critical" to mean "this change scenario has a severe blast radius and includes silent failure modes." This is NOT equivalent to "current bug" or "current data corruption." When synthesizing, Ripple Effect Critical findings that have NO current runtime bug (only a future-change concern) should be resolved to **High** in the final report. The reasoning: the failure does not exist today, but the structural gap makes the failure inevitable when the scenario occurs. High is the correct severity — it communicates urgency without falsely implying the system is currently broken.

Exception: if the Ripple Effect auditor identifies a silent failure mode that IS triggered by the current codebase state (not a future-change scenario), treat it as correctness-equivalent and keep as Critical.

---

### "No test project" is categorically different from "coverage gap on a method"
Category: Process/Model

When the Unit Test Coverage auditor reports 0 test projects / 0 test files, this is a different category from a coverage gap on a specific method or class. It means the entire test harness is absent. In synthesis:
- List it as a standalone High issue (not merged with any individual coverage gap)
- Include concrete starter test targets with the highest ROI (pure stateless classes first — zero setup, zero mocking)
- Recommend a specific test framework matching workspace conventions (not a generic recommendation)
- Do NOT list individual method-level coverage gaps as separate Critical issues when the root cause is a missing test project — they all trace to the same root. Consolidate them under the single "no test project" finding.

---

### Full-codebase reviews: root-cause synthesis is the primary deliverable, not a finding list
Category: Process/Model

When reviewing a complete codebase (no PR diff — `reviewMode: full-codebase`), the highest-value synthesis is not a flat list of issues but a set of 2–3 root causes that drive most individual findings. The recommended approach:
1. After de-duplicating, identify which structural decisions generate the most downstream issues
2. Promote those to a "Top N Root Causes" section that appears before the fix-order table
3. Frame the fix order around root causes (e.g., "fix this first because it unblocks steps 2 and 3") rather than severity-first ordering

In a PR review, the immediate merger decides the order. In a full-codebase review, the developer is planning a multi-session effort — a root-cause-first framing is far more actionable than a severity-sorted issue list.

---

### Singleton-vs-scoped severity split: Performance/Testability say Low, Extensibility says Critical — split them
Category: Process/Model

When a singleton service is flagged by multiple auditors at different severities, the discrepancy usually reflects two distinct problems:
- **Concurrency/testability concern** (singleton with non-atomic state): Low to Medium — affects current code
- **Architectural extensibility blocker** (singleton forces all users to share one value when per-user scoping is needed): Critical — blocks an entire feature family

Do not collapse these into one finding. List them as two separate findings under different themes (Performance/Testability theme vs. Architecture Blocker theme) at their independently correct severities. Merging them causes the Critical extensibility concern to be hidden behind the Low concurrency concern.

---

### Full-codebase reviews with 6+ auditors produce many duplicates: group by root cause, not by auditor
Category: Process/Model

When 6 auditors review the same codebase, expect 15–25% of findings to be cross-auditor duplicates. The synthesis job is dominated by deduplication rather than conflict resolution. The most efficient approach:
1. Read all reports in parallel and build a mental (or scratch) map of: `{code location} → {auditors who flagged it} → {highest severity}`
2. Group the final report by root cause / theme (e.g., "all DateTime.UtcNow findings" as one theme), not by auditor
3. Within each theme, lead with the cross-cutting recommendation that fixes all findings in that theme in one change
4. This produces a report with 8–10 themes rather than 40+ individual findings — far more actionable for planning

A flat issue list sorted by severity is appropriate for PR reviews (reviewer has limited time). A themed, root-cause-grouped report is appropriate for full-codebase remediation planning sessions.

---

### Ripple Effect SymmetricPath finding vs. Extensibility scenario mention: carry Ripple Effect's severity as a clarification question
Category: Process/Model

When Ripple Effect raises a `SymmetricPath` concern as a rated finding (e.g., Medium) and Extensibility mentions the same gap only in a "future scenario" section without a rated finding, the correct synthesis treatment is:
- Carry the Ripple Effect Medium into the final report (it is an explicitly rated finding)
- Frame it as a **clarification question requiring author input**, not a "must fix" blocker
- Use the phrasing: "Author confirms whether X is affected — if yes, add equivalent; if no, add a comment explaining the intentional asymmetry"

This framing is appropriate because SymmetricPath findings are often valid questions about scope rather than confirmed defects. The author has the context to answer whether the omission was intentional. Do not escalate to High or frame as a bug until the author confirms the symmetric path is also broken.

---

### Threading-elimination refactors produce a predictable "parallel construction test debt" finding
Category: Process/Model

When a commit extracts a factory to consolidate construction logic that was previously threaded through intermediate layers, integration tests that previously accessed internal components directly cannot trivially be updated to route through the factory. The factory returns an opaque interface (e.g., `ISubFlow`), but the tests need the inner concrete object to pass as an argument deeper in the graph. This creates a permanent "parallel construction path": the factory is the production source of truth, but integration tests remain a second independent source.

Synthesis treatment:
- The Ripple Effect auditor will flag this as High (co-evolution risk), and the Unit Test Coverage auditor will flag the factory's zero test coverage independently.
- Do NOT recommend rewriting all parallel-path integration tests — they cannot call `factory.Build()` for structural reasons.
- The correct fix is: (a) add a dedicated factory-level test that exercises `Build()` via the DI container, confirming both toggle paths and serving as a canary, and (b) document the 12 (or N) existing parallel-path tests as a known co-evolution risk with a comment.
- Rate the overall gap as High — the failure mode is a silent test regression when the factory signature changes.

---

### First-of-pattern factory naming mismatches have elevated severity — they become templates
Category: Process/Model

When a commit introduces the first implementation of a planned multi-factory pattern, a naming mismatch (e.g., interface named "FlowActionFactory" when `Build()` returns `ISubFlow` not `IFlowAction`) is **Medium**, not Low. The reasoning: the first concrete example is the template that all subsequent factory authors will copy. A name that confuses the abstraction in the first factory will be replicated across N future factories.

This is distinct from a standalone naming issue (which is typically Low). Apply the "first-of-pattern" escalation when the work item description explicitly says "create factories" (plural) or otherwise signals that this is an establishing implementation. The severity should reflect the compounding cost of the mistake, not just the local cost.

---

### Three-auditor convergence on newly-introduced factory test gap: carry the highest rating (High)
Category: Process/Model

When Unit Test Coverage rates a factory's zero test coverage as High, and Testability and Ripple Effect independently identify the same gap at Medium, the correct synthesis resolution is **High** — not average or median. The pre-existing/introduced distinction is the deciding factor: the factory class is entirely new code (not pre-existing), so the highest auditor rating stands. The three-auditor convergence confirms the finding belongs in the report at full strength.

This pattern is predictable for "extract factory" commits: the factory is the single most important new artifact, its toggle-conditional method is the only meaningful logic, and it is the first victim of future regressions if untested. Expect this exact three-auditor cluster whenever a factory with a toggle branch is extracted from an existing method.
