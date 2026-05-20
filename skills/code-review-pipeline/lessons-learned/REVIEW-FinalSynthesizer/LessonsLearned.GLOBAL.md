# Lessons Learned: REVIEW-FinalSynthesizer

> # ⚠️ GLOBAL FILE — CODEBASE-SPECIFIC CONTENT IS STRICTLY FORBIDDEN
>
> **This file is committed to a public shared repository and read across all projects and codebases.**
>
> **BANNED — do NOT write any of the following:**
> - Class names, interface names, method names, type names, field names
> - File paths, namespace names, project names, solution names
> - Work item IDs, ticket numbers, branch names, version identifiers
> - Domain-specific abbreviations or industry jargon unique to one team or product
> - Any identifier specific to one repository, team, or system
>
> **Write ONLY:** abstract synthesis patterns, conflict-resolution heuristics, and model-behavior observations that apply to any codebase.
>
> **Proper-noun test:** Remove all proper nouns from your proposed entry. If it still makes sense as general engineering advice, it belongs here. If understanding it requires knowing the project, move it to `LessonsLearned.md` (gitignored, local only).
>
> **MANDATORY SANITIZATION GATE — run before every append:**
> 1. List every capitalized identifier and domain abbreviation in the proposed text.
> 2. Classify each: standard framework/language type (safe) OR project-specific (banned).
> 3. Replace all project-specific items with generic placeholders before writing.
> 4. Re-read. If the entry still requires knowing the project to understand it, move it to `LessonsLearned.md`.
>
> ⚠️ **Most common violation: an abstract lesson body with a concrete project-specific example. Generalizing the headline is not enough — generalize or remove the example too.**

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

When the Correctness audit derives a requirement by reading the new code (e.g., inferring "new path handles only category A") rather than verifying it against the original work item and the pre-existing code path's behavior, it can miss behavioral differences between old and new mechanisms that coexist during a toggle-transition period. Always cross-check: if an old path handles categories {A, B} and the new path handles only {A}, ask whether the omission of {B} was intentional. This type of divergence is invisible inside any single audit but surfaces when the Extensibility auditor's claim about the old path is verified against source. Add this cross-check to synthesis: when a Correctness finding says "✅ Pass" on a category restriction, verify the old code path's category coverage matches.

---

### Guard-pattern commits have a characteristic finding signature across auditors
Category: Process/Model

Commits that add a "guard" to prevent an existing throw from being reached have a predictable finding profile:
- **Maintainability**: stale "impossible condition" comment in the guarded method (the one with the throw) — the comment was written when the condition was believed impossible, but the guard was added *because* it was observed. Always Medium.
- **Unit Test Coverage**: `Assert.DoesNotThrow` with a non-throwing mock (hollow assertion); `Times.AtLeastOnce` where `Times.Once` is verifiable. Always Medium.
- **Extensibility**: if the guard uses a type-check (`is ISomeSubtype`) rather than a polymorphic dispatch, OCP concern. Medium.
These three appear together on guard-pattern commits. Expect them and verify each one — do not synthesize them away even if they are "obvious."

---

### Multi-auditor clock-injection findings: treat as one synthesized finding, not four separate ones
Category: Process/Model

When Maintainability, Testability, Extensibility, and Correctness all independently flag the same pattern (e.g., `DateTime.UtcNow` bypassing an injected `TimeProvider`), do NOT list them as four separate findings in the final report. Synthesize into one finding that cites all source auditors. Include the full impact from all auditor perspectives (inconsistency, test-flakiness, cross-clock comparison bugs, non-deterministic test assertions). This is a high-signal pattern: 4-auditor convergence on a naming/plumbing issue means it is the single highest-leverage mechanical fix available in the codebase.

---

### Symmetric-path ripple-effect findings form their own cluster: collect before the synthesis step
Category: Process/Model

When the Ripple Effect audit flags asymmetric paths (e.g., "every mutation method calls X except DeleteAsync"), enumerate ALL asymmetric mutations in the synthesis — don't just report the one the auditor found. Check the Ripple Effect audit's own "Symmetric Path Analysis" table if one is present: it often lists additional missing cases beyond the auditor's primary High finding — enumerate all of them, not just the one the auditor named. These are Medium findings in the synthesis; the auditor's primary finding is High. Failing to include the table entries makes the synthesis incomplete.

---

### Divergent parallel dispatch paths: always cross-reference with planning/design documents
Category: Process/Model

When a Ripple Effect audit finds a second write path that bypasses the canonical state machine, check whether a planning document (work-planning/*.md, implementation guides) also documents the illegal pattern as the intended approach. If yes, the planning document itself is a companion finding — developers following the plan will reproduce the bug. Flag the planning doc correction as a distinct finding in the synthesis (separate from the code fix). Upgrading the plan is not optional when the plan contradicts the canonical contract.

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

### MVVM Singleton Coupling Cluster has a predictable multi-auditor signature
Category: Process/Model

In MVVM projects using CommunityToolkit.Mvvm, a "singleton coupling cluster" — where `WeakReferenceMessenger.Default` is used directly in two places, `DateTime.UtcNow` is called without injection, and `IsActive = true` is set in the constructor — produces a highly predictable cross-auditor finding profile:
- **Testability**: flags all three as High (no injection seam → cross-test contamination + clock instability)
- **Extensibility**: flags `IsActive` in constructor as High (side-effect at construction) and `WeakReferenceMessenger.Default` as Medium (no scoped messenger)
- **Performance**: may flag the fire-and-forget message handler as High (constructor-registered listener on global messenger receives messages from any thread)

---

### Pre-existing zero-test gap does not block merge — but the merge verdict must say so explicitly
Category: Process/Model

When a subsystem has zero test coverage as a pre-existing condition (i.e., no test project existed before this PR) and the changeset does not worsen it, the "Critical — no test project" finding should NOT be classified as a merge blocker in the final report. The verdict should be "Approved with Suggestions," not "Changes Required." The synthesis MUST state explicitly:
1. The gap is pre-existing (not introduced by this changeset)
2. The changeset's new logic is the highest-value test target (name the specific methods)
3. The merge verdict is clear and not ambiguously blocked

Failure mode to avoid: letting the "Critical" severity label from one auditor cause the synthesizer to block a merge when the code is correct, the gap is structural-and-pre-existing, and the team is aware of it. Critical severity = critical priority to address, not necessarily critical blocker to merge.

---

### Three-auditor convergence on the same Medium finding: consolidate, not escalate
Category: Process/Model

When three different auditors (e.g., Performance, Maintainability, and Correctness) independently flag the same code element at Medium severity from different angles, the correct synthesis action is to consolidate them into one finding that cites all source auditors — NOT to escalate to High on the basis of convergence. Convergence signals importance, not increased severity. Each auditor's angle (performance cost, maintenance trap, correctness concern) should be included as supporting evidence in the consolidated finding.

The escalation rule applies only when multiple auditors disagree on severity (e.g., one says High, one says Medium) — then resolve to the higher.

---

### Partial infrastructure migration is Medium (not Low) in synthesis even when each page is individually Low
Category: Process/Model

When a new service/pattern is introduced and applied to some sibling pages/components but not others, the Ripple Effect auditor correctly flags the asymmetry. In synthesis, this finding should be rated Medium (not Low) if:
1. The infrastructure is globally registered and immediately available to all consumers at zero additional cost
2. The unmigrated sibling pages share the identical structural pattern as the migrated page
3. The asymmetry creates a split user experience that is visible and persistent (not just an internal detail)

The "partially applied migration" finding rates higher in synthesis than in the Ripple Effect audit alone because the synthesis view includes the UX regression angle (users of the unmigrated pages see a different behavior) that the Ripple Effect audit may not emphasize.

---

### Zero-test subsystems: the three highest-value test targets form a predictable cluster
Category: Process/Model

When auditing a zero-test subsystem and prioritizing the first tests to write after infrastructure creation, the highest-value targets follow this sequence:
1. **Core behavioral fix methods with multiple edge-case branches** — these are pure computation, have clear expected outputs per branch, and are the most regression-prone (any future refactor can silently invert the fix). Flag as Critical in the coverage audit; minimum fix is access-modifier change.
2. **ViewModel toast/feedback trigger paths** — these are the primary user-visible signals. They require mocking service interfaces. Flag as High; effort is Small once the test project exists.
3. **Computed property invariants with non-obvious snapshot semantics** — these guard UX behaviors (dirty state, save button) that break in subtle ways. Flag as High; the test setup exposes whether the snapshot mechanism works for both model-relevant and UI-only mutations.

This cluster (behavioral fix → feedback triggers → computed invariants) is the recommended "phase 1 test backfill" sequence for any zero-test UI subsystem with a clean MVVM architecture.

These three appear together. Synthesize as a single root-cause finding (H-level) with a single coordinated fix recommendation: inject `IMessenger` and `TimeProvider`, forward messenger to base class, move `IsActive` to `Activate()` or `OnNavigatedTo`. Do not list them as six separate auditor findings — collapse them into one cluster finding with a list of sub-impacts.

---

### Fire-and-Forget quadruple-flagging is the highest-confidence finding signal in ViewModel reviews
Category: Process/Model

When `_ = SomeAsync(...)` appears in a `void Receive()` method and is flagged by four independent auditors (Maintainability, Performance, Security, Ripple Effect), this is the maximum-confidence signal in a ViewModel review — no factual conflict between auditors, all four are independently correct. In synthesis:
- Rate it High even if individual auditors rated it Medium
- List all four impact vectors (exception loss, UI-thread safety, stale state, test assertion racing) in the consolidated finding
- Recommend a single fix (try/catch + MainThread dispatch) that addresses all four

---

### Full-project ViewModel reviews: Unit Test Coverage audit produces 2-4× more findings than any other auditor
Category: Process/Model

In a full-project review (not a diff) where test coverage is zero, the Unit Test Coverage audit typically generates 20–25 findings vs. 6–10 for each structural auditor. Expect this distribution and do not treat the volume as meaning "the project is in terrible shape" — a single test file creation addresses the Critical and most High items simultaneously. When synthesizing, emphasize that the coverage findings resolve together (building the test project infrastructure unblocks all of them), rather than presenting them as 23 independent line items.

---

### Notification propagation bugs ("X never notified after UpdateCard") are user-visible correctness bugs, not design issues
Category: Process/Model

When a Ripple Effect auditor flags "computed property X is never notified after task mutations," this is a functional correctness bug (completed tasks remain visible in the view), not a design-level code smell. Synthesize at High priority with the explicit phrasing "user-visible bug" in the finding title. The fix is trivially small (one line inside the mutator), which makes the severity/effort ratio extremely favorable — call this out explicitly to help prioritizers pick it up first.

---

### Severity discrepancies between auditors are usually a pre-existing vs. introduced distinction, not a factual conflict
Category: Process/Model

When two auditors give the same finding different severities, check whether one is judging it as code introduced by the PR and the other is judging absolute severity. Downgrade to the lower rating when the issue is pre-existing. Factual conflicts (two auditors assert opposite facts) require verification; severity disagreements require the pre-existing/introduced distinction check.

---

### Unreachable infrastructure clusters produce a dependency-chain merge block, not independent findings
Category: Process/Model

When a project contains a fully-implemented subsystem (many files) that is architecturally unreachable because no CLI/API entry point exists, the synthesis task is to identify the minimum dependency chain that must be resolved before the feature can be enabled — not to present each missing command or interface as an independent finding. In this pattern: (1) the unreachable infrastructure is ONE Critical finding, not N findings; (2) the secondary missing commands that the subsystem requires (approve, unblock, etc.) are each separate findings at a lower severity; (3) any architectural incompatibility that makes wiring harder than "just add a command" (e.g., DI container mismatch, IServiceScopeFactory required) elevates the entry-point fix from Small to Large effort and should be called out explicitly so prioritizers understand it is a batch, not a sequence.

---

### When auditors agree on a finding but differ on severity, the highest-severity rating is usually correct for full-project reviews
Category: Process/Model

In a full-project snapshot review (not a PR diff), auditors do not apply the "pre-existing downgrade" heuristic because all code is current. When three auditors independently flag the same element at High/Medium/Medium, synthesize at High — the pre-existing downgrade rule does not apply, and multiple independent detections reinforce the finding rather than averaging it.

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

---

### Vocabulary-mismatch-with-external-integrator is always Critical — escalate regardless of per-auditor rating
Category: Process/Model

When the same string vocabulary is scattered as magic literals across 6+ files AND mismatches the documented external-integration vocabulary (e.g., a packaging agent, an API partner, a sibling system), the synthesis severity is always Critical — regardless of what any individual auditor rated it. The defining failure mode is: the external system writes value X, the internal system looks for value Y, no error is raised, views silently show wrong/empty data. Two compounding factors make this worse: (1) the scatter across many files means no single fix location, and (2) no compiler catches the divergence. The fix requires defining a constants class first and replacing all literals second. Always recommend these as a two-part fix in that order.

---

### "Stored but never read" cluster requires a deliberate decision, not individual findings
Category: Process/Model

Full-codebase reviews consistently surface a cluster of schema fields that are deserialized but have no read sites — `DisplayName`, `Email`, `PackageId`, `SchemaVersion`, `LastUpdated`, etc. In synthesis, do NOT list each dead field as a separate finding. Group them as a single "Dead Schema Fields" theme under Ripple Effect. The synthesis recommendation is always the same: require a deliberate per-field decision of "remove it or document when it will be used." The risk is false confidence — maintainers who see a field in the schema assume it is actively used and act on it, expecting behavior that never occurs.

---

### Full-codebase review Critical threshold = "any data written now is incompatible with the target design"
Category: Process/Model

In a PR review, Critical = "current runtime bug." In a full-codebase review of an in-progress project, Critical should be reserved for: "data written with the current schema cannot be used correctly by the planned system." This is a forward-compatibility blocker, not a backward-compatibility regression. The phrasing in the report should reflect this: use "must fix before any production data is written" not "blocks merge." The fix-order table becomes the actionable deliverable rather than a merge decision.


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

---

### Cross-auditor schema-mismatch cluster: consolidate into one Critical root cause before reporting
Category: Process/Model

When multiple Critical findings from 4+ independent auditors all trace to the same structural data-layer error — field type mismatch, incompatible representation, wrong storage format — a flat severity-sorted issue list obscures the root cause and inflates the Critical count. Each auditor identifies a symptom:
- **Correctness**: wrong values persisted or read back
- **Security**: data integrity or injection risk from malformed input
- **Extensibility**: schema as a hard coupling point for future changes
- **Ripple Effect**: cascade impact if schema is corrected post-data-write

Synthesis action: after de-duplicating, verify whether multiple Criticals share a schema root. If yes: (1) create a "Schema Integrity" theme at the top of the Critical Issues section, (2) list each specific mismatch as a sub-bullet under one root-cause entry rather than independent findings, (3) suppress per-auditor symptom listings as redundant. The result is fewer Critical line items, each clearly actionable.

Distinction from "Vocabulary-mismatch-with-external-integrator" (existing entry): that entry handles string literals scattered across files that mismatch a documented external partner's vocabulary. This entry handles structural type/field/representation mismatches at the data layer that may have no external partner at all — the bug is internal schema incoherence.

---

### Coverage auditor exclusion: lower the convergence threshold for test-related findings
Category: Process/Model

The "3+ auditors independently flagged this" escalation rule assumes all standard auditors are active. Unit Test Coverage is typically the third independent voice on any test gap — Correctness and Testability flag the same gap from different angles, and Coverage makes it three. When Coverage is explicitly excluded from the review:

- Lower the convergence threshold from 3+ to **2+** for findings that are inherently test-related (missing tests, untested paths, coverage gaps on newly-introduced logic)
- A Correctness + Testability co-flag on a test gap with Coverage absent is equivalent in signal strength to a three-auditor finding with Coverage present — the exclusion changed the denominator, not the strength of the signal
- Do not silently downgrade these findings to their per-auditor severity just because the convergence count is lower

This adjustment prevents systematic under-escalation on test-related findings any time Coverage is scoped out (e.g., dev-tool reviews, spike reviews, reviews of legacy code with no test harness).
