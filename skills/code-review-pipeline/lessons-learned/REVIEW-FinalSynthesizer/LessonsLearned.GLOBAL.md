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

### Filter-removal findings always require a downstream null-guard check
Category: Process/Model

When a Correctness or Maintainability auditor flags a filter/guard removal (`.Where(...)`, `.Filter(...)`, or equivalent), the synthesizer must specifically check whether any downstream code was relying on that filter as an implicit safety net against unsafe operations — `.First()`, direct indexing, or similar calls that throw on empty/missing matches. This is a systematic oversight risk: the filter removal is visible, but its downstream consequences are usually in a different method or file and may appear in a separate auditor's report as a distinct finding. In synthesis: treat the filter-removal finding and any downstream null-guard exposure as a compound Medium finding (not two separate findings). The recommendation must address both the explanation comment (maintainability) AND the downstream guard (correctness).

---

### No-call-site factory method: frame as "confirm or wire," not as Critical
Category: Process/Model

When a new factory method or interface addition has no production call site, the correct synthesis severity depends on whether the omission is plausible as intentional phased delivery. If the method is fully implemented and tested but the dispatcher/caller is missing, and a named placeholder guard (e.g., a null-return for the new type) exists in the consuming code, the finding should be framed as **High with two resolution paths**: (a) confirm phased delivery and document explicitly, or (b) wire the dispatcher now. Do not automatically escalate to Critical just because there are no call sites — phased delivery is a legitimate pattern. Critical is reserved for cases where the absence would cause data loss or incorrect output that is reachable in production today.

---

### Three-auditor testing gap convergence: consolidate to HIGH with Coverage auditor's specific test recommendations
Category: Process/Model

When Requirements, Unit Test Coverage, and Testability all independently flag the same untested code location (typically a new method with per-type dispatch), consolidate into a single High finding. The Coverage auditor usually provides the most actionable recommendation (exact test names, assertions, and the assertion format). Lead with that auditor's recommendation and append the additional impact dimensions from Requirements (regression risk for derived acceptance criteria) and Testability (structural reason why the calculator is directly testable). Do not list this as three separate findings — it inflates the apparent complexity and makes the action item unclear.

---

### Stale "Known Limitations" row in a security-critical architecture doc is a High finding, not a documentation nit
Category: Process/Model

When a Ripple Effect auditor identifies that an architecture document's "Known Limitations" table claims a security-relevant feature is unimplemented — and the changeset being reviewed is exactly the delivery of that feature — the synthesizer must classify this as **High**, not Medium or Low. The framing matters: a stale "not yet implemented" row in a security-critical subsystem actively misleads future developers into concluding that a live, tested capability does not exist. The risk is not that the doc is outdated; the risk is that a future developer reads it, concludes denial via the new property is unimplemented, and produces a parallel or conflicting implementation. Severity criterion for this classification: the misleading row covers a feature that affects trust boundaries (authorization, access control) AND the confusion would lead to a security-relevant workaround. Doc accuracy nits about non-security features remain Low.

---

## When to Append an Entry

Only append if the session revealed something surprising about synthesis, a recurring conflict pattern between auditors, or a finding specific to the final-synthesis step. Findings that apply to the entire pipeline should be promoted to the pipeline-level LessonsLearned instead.

---

### Severity discrepancy between specialist and generalist auditors: defer to the specialist
Category: Process/Model

When two auditors assign different severity levels to the same finding — one High, one Low — and one auditor's entire domain is the dimension being measured, defer to the specialist auditor rather than averaging or defaulting to the lower severity. Concrete example: if the Unit Test Coverage auditor rates a coverage gap as High and the Testability auditor rates the same gap as Low, the Unit Test Coverage auditor's rating takes precedence because measuring coverage adequacy is the exact scope of that auditor role. The generalist auditor may be correctly assessing impact on testability architecture (a distinct question) while the specialist is assessing coverage completeness (the severity-relevant question). In synthesis, note the discrepancy and explain which rating was adopted and why, rather than silently picking one.

---

### Auditor field-name errors are a synthesis verification gate, not a pass-through
Category: Process/Model

When two auditors independently recommend the same fix for the same defect but specify different field names (e.g., one says `IsPermitted`, another says `IsAllowed`), treat this as a factual conflict requiring ground-truth verification before writing the final recommendation. The correct approach: verify the actual field name in source before including either auditor's code snippet. Do not average the two recommendations or present both as alternatives — present only the verified-correct field name in the final report, and note explicitly which auditor made the error. This is a concrete case of the general "resolve factual conflicts before writing" principle from the workflow.

---

### Deferred-per-spec Security Highs require a separate verdict framing in the executive summary
Category: Process/Model

When a Security auditor issues a FAIL verdict with High-severity findings that the Requirements auditor explicitly confirms are documented out-of-scope deferrals, the synthesis executive summary must clearly partition these two positions without dismissing either. The correct framing: acknowledge the Security auditor's High verdict is accurate — the risks are real — while also stating that the deferrals are documented and that the merge can proceed if (and only if) formal follow-up tasks are created before the branch is closed. Do not collapse the Security auditor's FAIL into a simple "pass" or bury the security findings in "Consider." The overall verdict should be "MERGE WITH CONDITIONS" not "PASS" or "FAIL." The partition criterion for this case: deferred-per-spec ≠ accidental omission; both require tracking but only accidental omissions block merge.

---

### SaveChanges-override immutability gaps: always check for ORM bulk-operation bypasses
Category: Process/Model

When a Security or Structural auditor flags that an ORM `SaveChanges` override-based immutability guard (or soft-delete filter, or audit enforcement) can be bypassed by the ORM's bulk-update/bulk-delete APIs — and no other auditor flags this — always include it as a separate **Medium** finding in the final report rather than folding it into the same finding that describes the guard itself. The guard and the bypass are structurally different: the guard is a correctness control; the bypass is a latent architectural gap that only manifests when a developer adds a bulk operation to a future slice. They require different remediation (one is a doc note, one is a defensive check). Synthesize them as two distinct action items even if they share a root cause.

---

### Interface-doc + architecture-doc log-level triangle: fix all three atomically or not at all
Category: Process/Model

When a code review discovers that an implementation uses a different log level (or any other behavioral constant) than what its interface XML documentation specifies — and the architecture doc also documents the wrong level — treat the three-way inconsistency as a single Required Change with a single commit instruction: "fix the implementation AND the XML doc AND the architecture doc in the same commit." Do not accept a fix that corrects only the implementation or only the doc. The failure mode is well-established: if implementation is fixed but docs are not, the next developer who calls the interface reads the wrong spec and re-introduces the original defect. In synthesis, list this as one finding (not three) with explicit "all three must change together" language in the recommendation.

---

### Three-auditor convergence on a ValueComparer defect: consolidate as one blocker, cite all three
Category: Process/Model

When a value comparer defect (equality logic that under-detects changes, causing silent data loss on SaveChangesAsync) is independently flagged by Correctness (as a data-persistence correctness failure), Performance (as an algorithm defect masquerading as an optimization), and Ripple Effect (as a symmetric-path inconsistency with sibling properties), consolidate into one blocker. Lead with the Correctness auditor's framing (the mechanism of data loss and the affected scenario), add the Performance auditor's root-cause analysis (the premature O(1) optimization), and note the Ripple Effect auditor's pattern observation (the comparer is inconsistent with sibling properties on the same entity). Do not list three separate findings — the root cause and fix are identical. Cite all three auditors in the "Flagged by" line to establish the convergence weight.

---

### Security-critical method extraction: consolidate structural + correctness + coverage into one CRIT finding
Category: Process/Model

When a security-critical guard method is (a) private on a component/controller class, (b) confirmed exploitable by the Correctness or Security auditor, and (c) has zero unit tests because the structural home prevents direct access — these three auditor findings (Structural: SP-009 misplacement, Correctness/Security: confirmed bug, Coverage/Testability: untestable gap) should all be consolidated into a single Critical finding with a three-part fix prescription: (1) extract to an internal static utility class, (2) add `InternalsVisibleTo`, (3) write failing unit tests before applying the logic fix (TDD order). Do not list the structural finding and the correctness finding as separate Critical issues — they are the same root cause with a unified remedy. The structural misplacement is the reason the bug survived, not an independent problem.

---

### Ten-auditor deduplication: use the user-provided deduplication map as the authoritative consolidation plan
Category: Process/Model

When the review brief includes an explicit cross-auditor deduplication map (a table mapping auditor finding IDs to a consolidated finding ID and root cause), use that map as the authoritative consolidation plan rather than re-deriving the groupings from scratch. The user's map was constructed with knowledge of all auditor outputs and domain context that the synthesizer may not replicate exactly. Deviating from the map (e.g., splitting a group the map says to consolidate, or merging groups the map keeps separate) introduces inconsistency without adding value. Treat the deduplication map as a constraint, not a suggestion.

---

### Security + Performance co-flag on same endpoint: consolidate, Security framing leads
Category: Process/Model

When Security and Performance auditors independently flag the same missing control (e.g., rate limiting on a CPU-intensive endpoint), consolidate into a single High finding in the final report. Lead with the Security auditor's framing (attack vector, OWASP reference, exploitability), then append the Performance auditor's analysis as the impact quantification (CPU saturation math, thread-pool degradation model). Do not list them as two separate findings — the recommendations are identical and the dual listing creates the false impression that two fixes are needed when only one is. The combined finding carries more weight than either in isolation: it is simultaneously an authentication failure risk and a DoS risk.

---

### Partition High-severity findings into "blocks merge" vs. "recommended before next slice"
Category: Process/Model

When a review produces 7+ High-severity findings, the executive summary and Must-Fix section must explicitly partition them into two tiers: (1) findings that block merge (correctness failures, exploitable security vulnerabilities, or test infrastructure time-bombs that silently corrupt future test results), and (2) findings that are High severity but do not block this merge (design debt, testability gaps, extensibility concerns). Without this partition, a report with 9 High findings reads as "do not merge anything" even when only 4 are true blockers. The partition should be made in the roll-up table (a "Blocks Merge?" column) and reflected in the Recommendation section. The criterion for a merge blocker: the issue causes an active exploit, silently corrupts production data, or will make all future E2E tests silently wrong.

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

### Deduplication for multi-report issues: consolidate on the strongest statement, not the union
Category: Process/Model

When multiple auditors flag the same issue (e.g., a non-atomic side effect appears in Correctness, Ripple Effect, and Coverage), the final synthesis should consolidate into one finding with a single root cause and a single recommendation — not a union of all three auditors' wording. The correct approach: identify the auditor whose framing captures the full impact (Ripple Effect for propagation consequences, Correctness for the state-machine violation, Coverage for the regression guard gap), lead with that framing, then append the additional impact dimensions parenthetically. Do not list all three auditor citations in parallel — it inflates the finding's apparent complexity.

---

### A zero-test codebase is always a HIGH finding, regardless of code quality
Category: Process/Model

When a codebase has no test project at all, this must be listed as a High finding in the final report regardless of how well-written the production code is. The absence of tests means: (1) every correctness bug found in the review has no regression guard, (2) future refactoring is unguarded, and (3) there is no mechanism to detect introduced regressions before production. Do not soften this finding by framing it as "technical debt" or "future work." It blocks safe refactoring and makes every other finding in the report higher-risk than it would otherwise be.

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

### When a finding appears in both Critical and High tiers of the orchestrator's pre-dedup summary, trust the individual auditor's classification
Category: Process/Model

Occasionally the orchestrator's pre-deduplication summary will list a finding in two severity tiers (e.g., once under Critical and once under High). This is a formatting error in the summary — the finding was listed in both places. Resolution: check the individual auditor's own severity label and use that. A broken test safety net (the test always passes) warrants High, not Critical, when the underlying production code is correct. The Critical tier is reserved for issues that block functionality or cause data loss — a broken test does not meet that bar even if it covers security-sensitive behavior.

---

### When an auditor's output file contains content from a prior review, derive its findings from the orchestrator's dedup map
Category: Process/Model

If a correctness (or any) audit file appears to contain content from a prior review phase rather than the current phase (e.g., it references FR-01 through FR-18 from an E2E phase when the current review is about unit tests), do not retry the same read or search for a replacement file. Instead, trust the orchestrator's provided deduplication map and pre-dedup finding summary, which were assembled from the live audit run. The CC- (or equivalent) prefixed findings in the dedup map are the authoritative source for that auditor's output. Do not flag the stale file as a blocker — proceed with synthesis.

---

### M-severity findings that overlap with RE/TB/EX Medium findings: consolidate to the Medium tier
Category: Process/Model

When a Maintainability auditor rates a finding as Low (e.g., M-07: "FakeTimeProvider is file-scoped") but Ripple Effect, Testability, and Extensibility auditors all rate the same root issue as Medium, the consolidated finding should be Medium. The stronger cross-auditor severity always wins when the root cause is identical. The Maintainability perspective may only see the intra-file impact (low), while the other auditors see the cross-project impact (medium). Synthesize at the highest observed severity when the root issue is the same object.

---

### High auditor-convergence count does not escalate severity for CI/timing smells
Category: Process/Model

When four or more auditors independently flag the same test-infrastructure timing smell (e.g., a fixed-duration sleep used for a negative-wait assertion in an E2E test), do not escalate the consolidated finding to High just because convergence count is high. The convergence count signals importance — it warrants a prominent call-out and a named cross-cutting label (e.g., CROSS-01) — but severity is still determined by the root issue's actual impact: CI fragility and copy-prone magic number are Medium-tier concerns by any individual auditor's measure. Escalation to High requires: active exploit, correctness failure in production, or an issue that makes all future tests in the affected file silently wrong. A fixable timing pattern does not meet any of those criteria.

Distinguish from the three-auditor coverage convergence rule (see above), which does escalate to High when Requirements, Coverage, and Testability all flag the same untested production code location. That rule applies to production correctness gaps; this rule applies to test infrastructure quality smells. The two convergence categories have different escalation thresholds.

---

### Correction commit fixing only one of two symmetric write sites: the Ripple Effect auditor is authoritative
Category: Process/Model

When a "fix" commit corrects a compliance defect that appears in two locations (e.g., a status string in an aggregated index file AND in the per-item status document), and the commit only touches one of the two, the Ripple Effect auditor is the specialist who will catch the asymmetric update. In synthesis: if the Ripple Effect auditor rates this as High and another auditor rates the same omission as Medium (e.g., Correctness rates the root defect Critical but the fix-omission as a lower-severity companion), defer to the Ripple Effect auditor's High for the "fix not applied everywhere" dimension. The correction commit finding is distinct from the original defect — it should be named separately in the final report with explicit "both write sites must be updated together" language.

---

### Formally-deferred item not re-checked when the target feature ships: always close the deferred loop in synthesis
Category: Process/Model

When multiple auditors independently identify that an item was formally deferred from feature A to feature B, and feature B is now delivered, this is a synthesis gate: confirm whether the deferred item was actually implemented in feature B. This is distinct from a standard missing-feature finding — the deferred item was documented, tracked, and attributed to a specific future slice. When the target slice ships without implementing the deferred item, the gap becomes invisible: the doc still shows "deferred to feature B" (now past), and there is no error or warning in the code. In synthesis: if the Requirements auditor and the Ripple Effect auditor both flag the same deferred scenario as unimplemented, treat the gap as **High** (not Medium) because: (1) the formal attribution means the gap was expected to close at this review boundary, (2) the item typically covers a security or compliance surface (otherwise it would not have been formally tracked), and (3) the arch doc's forward reference is now factually false rather than merely aspirational.

The recommendation must include both the implementation fix and an arch-doc update (the "deferred to X" row must be replaced with the correct current state, not left pointing at a now-delivered feature). Do not list these as separate findings — the implementation gap and the stale doc are one root cause with two surfaces.

---

### Binary ternary on a growing enum: four-auditor convergence elevates to High when a scope-confusion security risk exists
Category: Process/Model

When a binary ternary (`x == A ? resultA : resultB`) operates on an enum that has three or more values, and Correctness, Maintainability, Extensibility, and Structural auditors all flag the same ternary at four different severity levels (typically Low/Medium/High each), the synthesis severity is driven by the Security auditor's framing — not by the average or the mode. If the security auditor identifies a concrete scope-confusion attack vector (e.g., an unrecognized third scope value silently evaluates against the wrong permission string, potentially granting unauthorized access), elevate to **High** regardless of how the other auditors classified it.

The reason: a binary ternary on a growing enum is simultaneously a maintainability smell (won't fail loudly on extension), an extensibility trap (future values are silently mishandled), a testability gap (no independent unit test can pin the third-scope behavior), and — crucially — a potential wrong-permission authorization check. The correctness auditor may classify it as Medium (current operational risk is low); the security auditor's framing of the future risk should dominate.

In synthesis, write one consolidated finding citing all four auditors (not four separate findings), lead with the security impact, and include the recommended switch-with-explicit-throw pattern. This consolidation is appropriate precisely because the fix is identical across all four concerns — a single switch expression replaces all four concerns simultaneously.

When one auditor classifies a finding as Low and a second independent auditor flags the same root cause at Medium — even with a different framing (e.g., Correctness frames it as a UX question, Ripple Effect frames it as an asymmetric predicate) — the correct synthesis is to surface the finding as Medium in the final report, not as two separate findings at their respective severities. The second auditor's framing often captures the stronger impact statement; lead with that, then append the complementary dimension parenthetically. The combined signal from two independent auditors is the right escalation trigger.

---

### Infrastructure-scale test additions have a predictable auditor coverage gap: edit/modify workflows go untested
Category: Process/Model

When a change set adds a large batch of new tests primarily covering read/view/navigation workflows, the synthesis step should specifically check whether any write/edit/save workflow is covered. A common gap pattern: a rich set of new "create", "activate", "complete", "delete" tests with zero tests for "edit via modal and save". The components that expose save/commit interactions — modal save buttons, toggle checkboxes — are the first place to look for untested `data-testid` values after an infrastructure build sprint. Synthesize this as a High finding even when the components are structurally correct and the test IDs are present, because the coverage gap means any regression in the save path is invisible.

---

### Full-project reviews: enumerate COMPOUND findings — a single root cause producing N gap surfaces belongs in one High entry
Category: Process/Model

When a full-project (no PR diff) review reveals that a single structural gap (e.g., a closed enum registry not updated for new values) produces multiple separate gap surfaces across views, ViewModels, and interfaces, synthesize these into one High finding with clearly numbered impact dimensions rather than listing each gap surface as a separate finding. The individual surfaces belong as bullet points under the compound root-cause finding, not as separate High items. Reserve separate High items for gaps that have distinct root causes. This reduces the cognitive load on the reader and makes remediation more actionable — fixing the root cause resolves all impact dimensions at once.

Exception: when gap surfaces span different files AND have materially different fix efforts (e.g., one requires a backend API change and one requires a frontend template change), split them. The rule applies when all gap surfaces are fixed by the same code change.

---

### Contract test suite reviews: "verified by contract tests" documentation claims require explicit cross-audit verification
Category: Process/Model

When a contract document (e.g., a CLI output spec, an API contract reference) contains a table or section labeled "verified by contract tests" or "verified error patterns," this claim must be treated as a verification checkpoint — not a fact. The Coverage auditor and Requirements auditor may independently discover that the documented patterns have no corresponding test. In synthesis: scan all "verified by" claims in any companion document and cross-reference them against the test file contents. A contract document that claims verification but has no supporting test is a higher-severity finding than a simple untested path, because it actively misleads future developers and agents into believing a regression guard exists.

---

### Exit code precision in contract test suites is a HIGH finding: `.NotBe(0)` vs `.Be(1)` undermines the contract's core value
Category: Process/Model

In a test suite explicitly written to verify a CLI or API contract's exit code behavior, using `.NotBe(0)` on error-case assertions instead of `.Be(1)` is a HIGH finding — not Medium. The distinction matters because: (a) an unhandled exception produces a non-zero exit code that is NOT 1, so `.NotBe(0)` passes silently when a real contract violation has occurred; (b) the entire value proposition of a contract test suite is to precisely verify the contract. Imprecise assertions on the contract's own terms defeat the purpose. Elevate to HIGH whenever the contract explicitly specifies the exact error exit code value and the test suite does not verify that exact value.

---

### Cross-auditor conflict resolution: performance vs. maintainability severity disagreements are expected — use impact to adjudicate
Category: Process/Model

When a Performance auditor rates a finding High and a Maintainability auditor rates the same issue Medium, keep the higher severity in the final report and note the corroboration. Performance auditors elevate severity based on runtime failure risk (e.g., async void exceptions are unobservable in production); Maintainability auditors lower severity based on code quality alone. When the higher-severity justification is a production failure mode (silent exception suppression, circuit termination, irrecoverable state), the performance rating takes precedence in the final report.

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

### Multi-host DI consolidation reviews: check every composition root, not just the obvious ones
Category: Process/Model

When a DI consolidation changeset touches multiple composition roots (web, CLI, test), the synthesizer should explicitly cross-check whether any additional host-context startup file was omitted from the changeset. Platform-specific startup files (mobile app, desktop app, background service host) use different entry-point patterns and are systematically overlooked because they do not share the primary `Program.cs`. The Extensibility auditor is the most likely to surface this omission; the synthesizer should add a cross-check question: "Does any other composition root exist that is not represented in this changeset?" A missed host can have two distinct failure modes: (1) duplicate/stale registrations that drift from the consolidated modules, and (2) missing registrations (e.g., gate chain is empty) that produce silent behavioral divergence in that host context. Both failure modes are invisible when only reviewing the consolidated modules.

---

### Environment-default changes produce a predictable three-artifact documentation ripple
Category: Process/Model

When a CLI tool or script changes its environment fallback default (e.g., Development → Production), the change ripples to three artifact types simultaneously: (1) operational skills or runbooks that encode the old default in example commands or environment tables, (2) reference documentation that describes the default behavior as static text, and (3) architecture documents with inline comments or prose describing the configuration loading sequence. All three must be updated in the same changeset or the documentation becomes more dangerous than no documentation at all — agents and developers following the old default will silently target the wrong environment. The Ripple Effect auditor is the primary detector; the synthesizer should verify all three artifact types are covered in the fix. Rating: two or more artifact types stale → High; one artifact type stale → Medium.

---

### Test infrastructure "ValidateScopes missing" elevates to High when the suite's purpose is DI correctness
Category: Process/Model

When a test infrastructure's stated design goal is "catch DI misconfiguration as a test failure rather than a production incident," and `BuildServiceProvider()` is called without `ValidateScopes = true`, the Performance auditor's Medium rating should be elevated to High in synthesis. The finding is not merely about catching future bugs — the test suite is actively failing to fulfill its own specification. The elevation criterion: if the test infrastructure's design documentation claims it detects captive dependency bugs, and the mechanism that enables that detection is absent, rate it High. The Performance auditor rates the gap as Medium because performance is not the primary concern; the synthesizer rates it High because the design guarantee is not met.

---

### Unreachable infrastructure clusters produce a dependency-chain merge block, not independent findings
Category: Process/Model

When a project contains a fully-implemented subsystem (many files) that is architecturally unreachable because no CLI/API entry point exists, the synthesis task is to identify the minimum dependency chain that must be resolved before the feature can be enabled — not to present each missing command or interface as an independent finding. In this pattern: (1) the unreachable infrastructure is ONE Critical finding, not N findings; (2) the secondary missing commands that the subsystem requires (approve, unblock, etc.) are each separate findings at a lower severity; (3) any architectural incompatibility that makes wiring harder than "just add a command" (e.g., DI container mismatch, IServiceScopeFactory required) elevates the entry-point fix from Small to Large effort and should be called out explicitly so prioritizers understand it is a batch, not a sequence.

---

### When auditors agree on a finding but differ on severity, the highest-severity rating is usually correct for full-project reviews
Category: Process/Model

In a full-project snapshot review (not a PR diff), auditors do not apply the "pre-existing downgrade" heuristic because all code is current. When three auditors independently flag the same element at High/Medium/Medium, synthesize at High — the pre-existing downgrade rule does not apply, and multiple independent detections reinforce the finding rather than averaging it.

---

### Structural patterns auditor disambiguation notes belong in the executive summary
**Date:** 2026-05-28
**Category:** Process/Model

When a structural patterns auditor provides an explicit disambiguation note — explaining why a code element resembles one pattern superficially but is categorically distinct from it — that note is worth including in the synthesis executive summary even when the finding count from that audit is low. The note protects future reviewers from false positives and communicates design intent that might otherwise be invisible.

**Concrete trigger**: structural patterns auditor produces 0 Critical / 0 High / 1 Medium and says "this element looks like Pattern X but is actually Pattern Y — do not co-report these two patterns for this code." Include a sentence in the executive summary summarizing: (1) how many patterns were cleanly vetted, (2) what the medium finding was, and (3) what the key disambiguation was. This sentence costs very little but prevents a future reviewer from filing a spurious Pattern X finding on the same code.

**When NOT to include it**: if the auditor's report contains no disambiguation note — only a clean verdict — a short "all N patterns clean" summary line in the per-dimension table is sufficient. The full executive summary mention is triggered by an explicit disambiguation claim, not by a clean verdict alone.

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

### Two auditors recommend the same fix but use different method names: resolve by framework convention, not averaging
**Date:** 2026-05-31
**Category:** Process/Model

When two auditors independently recommend adding the same new method to an interface but name it differently (e.g., one calls it `BatchWrite`, another calls it `WriteRange`), this is a naming conflict, not a factual conflict. It does not require ground-truth verification in the source code (the method does not yet exist). Resolution rule: select the name that is most consistent with the naming convention of the platform, framework, or library that the implementation depends on. Presenting both names as alternatives inflates the finding and delays the action; picking arbitrarily is not repeatable. Documenting which name was chosen and why gives future auditors a stable reference.

Concrete check: for a method whose implementation wraps a framework bulk-write operation (e.g., `AddRange` in Entity Framework, `BulkInsert` in another ORM), the method name should use the verb that matches the underlying framework method. Callers build on the method name they see in the interface, so alignment with the framework reduces cognitive friction.

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

### Four-auditor compile-blocker confirmation warrants explicit "extractable clean subset" reviewer note
Category: Process/Model

When 4 auditors independently confirm a compile blocker (missing class definition, missing interface implementation), and the blocker is isolated to one new feature added within a PR that is otherwise a large, clean refactoring, the synthesis report should include an explicit Reviewer Note suggesting the PR could be split: the clean refactoring extracted and merged independently while the incomplete feature is finished. This provides the team an escape hatch that avoids holding a validated, complete refactoring hostage to an in-progress feature. The note should be framed constructively ("if the team prefers") not prescriptively. Include it under Reviewer Notes, not as a Developer Action Item.

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

---

### Algorithm-addition commits behind feature toggles produce a characteristic "clean core + schema + scope" Medium cluster
Category: Process/Model

When a commit adds a new computational algorithm (not a refactoring) behind a feature toggle, and the change also removes a pre-existing derived-value field from a serialization record, the expected Medium cluster across all 9 auditors is:
- **Requirements + Correctness + Ripple Effect**: independently flag the serialization schema removal as a Medium (backward-compatibility / round-trip-test gap). This 3-auditor convergence is the dominant finding of the review; synthesize it as one consolidated finding citing all three.
- **Requirements + Correctness**: independently flag any "work item says type X only, code applies broadly" scope restriction as a Medium requiring team confirmation.
- **Unit Test Coverage**: flags the work-item-specified non-standard geometry or edge case as a Medium test gap — the algorithm handles the general case but no test validates the specific production scenario named in the work item.
- **Testability**: typically all-pass for this commit type when the new class is a stateless pure function with a narrow interface.
- **Security, Performance, Extensibility, Maintainability**: all Low or pass.

The synthesizer's task for this profile is: (1) collapse the 3-auditor schema finding into one Medium, (2) carry the scope ambiguity as a separate Medium with a team-confirmation action, (3) carry the edge-case test gap as a third Medium, then clean up the Lows.

---

### Serialization `Key(N)` removals trigger 3-auditor convergence regardless of auditor role
Category: Process/Model

When a positional-key binary schema field (e.g., MessagePack `Key(N)`) is removed, expect independent flags from: (1) **Requirements** — backward-compatibility concern about durable storage blobs; (2) **Correctness** — no round-trip validation in tests; (3) **Ripple Effect** — regenerated test asset confirms the author handled the known asset but no explicit schema test exists. All three raise the same concern from different angles. Synthesize as one Medium citing all three. The resolution action is always a binary question: "Are blobs ever read from durable storage?" — if no, a PR comment confirming this closes the finding without any code change; if yes, a round-trip test and schema-evolution verification are required.

---

### "Work item says scope X only, code has no guard" — Medium with team-confirmation action, not a defect
Category: Process/Model

When a work item states a domain restriction ("this only applies to type X and Y") but the implementation applies the behavior to all instances of the parent type with no guard, this is a Medium finding with a "team-confirmation" disposition — not a confirmed bug. The restriction may be architecturally enforced by the caller (so the callee never receives non-X/Y inputs), or it may need an explicit guard in the callee. The synthesizer should:
1. State the discrepancy clearly: work item says X/Y, code has no guard
2. Ask the binary question in the PR: "Is this already architecturally gated, or does a code guard need to be added?"
3. If architecturally gated: confirm in a comment, downgrade to Low, add an inline comment explaining the invariant
4. If not gated: add the guard before merge

Do NOT classify this as High or assume it is a bug. The presence of a feature toggle that limits the entire code path to intentional activation reduces the urgency further.

---

### Low × 3 auditor convergence on a trivially-cheap fix → include in Required Actions Before Merge
Category: Process/Model

When Correctness, Maintainability, and Coverage each independently rate the same finding Low but all recommend the same trivial fix (e.g., a single-line explicit guard replacing an implicit assumption), include it in the "Required Actions Before Merge" list in the final report — even though each individual severity is Low. The combination of (1) 3-auditor independent convergence and (2) fix cost of one line creates a risk/reward ratio that favors doing it now rather than deferring. Use the phrasing "Three-auditor convergence; trivial fix" in the Required Actions entry to signal why a Low is elevated to a required action.

This is distinct from the rule about three Medium findings: here the convergence is the justification for escalating the *action priority*, not the *severity rating*. The finding remains Low in the inventory table.
