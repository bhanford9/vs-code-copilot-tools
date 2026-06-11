# Lessons Learned: REVIEW-FinalSynthesizer

> GLOBAL FILE. Abstract synthesis process rules only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed a non-obvious conflict-resolution rule, a recurring auditor disagreement pattern, or a finding about the synthesis step itself.

---

### Filter-removal findings require a downstream null-guard companion check
When any auditor flags a filter/guard removal, check whether downstream code relied on that filter as an implicit safety net (`.First()`, `.Single()`, direct indexing). Treat the filter removal and its downstream consequence as one compound Medium finding, not two.

---

### No-call-site factory method: frame as "confirm or wire," not automatic Critical
When a fully-implemented method has no production call site, rate it **High with two resolution paths**: (a) confirm phased delivery and document, or (b) wire the caller now. Critical requires a reachable production failure today.

---

### Three-auditor testing gap convergence: consolidate to HIGH with Coverage auditor's test recommendations
When Requirements, Coverage, and Testability all independently flag the same untested code location, consolidate to one High finding. Lead with Coverage's recommendation (specific test names and assertions), append the Requirements and Testability impact angles.

---

### Stale "Known Limitations" row in a security-critical architecture doc is High, not a doc nit
A stale "not yet implemented" security row actively misleads future developers into believing a live capability does not exist. If the changeset delivers the feature, the stale doc is High. Flag as Medium for non-security features.

---

### Severity discrepancy between specialist and generalist: defer to the specialist
When Coverage auditor rates a coverage gap High and Testability auditor rates it Low, the Coverage auditor's rating applies — measuring coverage adequacy is exactly that auditor's scope. Note the discrepancy and explain the choice.

---

### Auditor field-name errors: verify ground truth before writing the recommendation
When two auditors recommend the same fix but specify different field names, verify the actual name in source before writing either auditor's code snippet. Present only the verified-correct name.

---

### Deferred-per-spec Security Highs: verdict is "MERGE WITH CONDITIONS," not PASS or FAIL
When Security issues a FAIL for documented out-of-scope deferrals, clearly partition: Security risks are real, deferrals are documented, merge only if formal tracking tasks are created. Do not collapse to PASS or bury the findings.

---

### ORM SaveChanges override: always check for bulk-operation bypass as a separate finding
An ORM-level immutability guard and the bulk-API that bypasses it require two distinct recommendations. The guard is a correctness control; the bypass is a latent architectural gap. They have different fixes.

---

### Interface-doc + architecture-doc log-level triangle: fix all three atomically
When implementation uses a different behavioral constant than its interface XML doc AND architecture doc, the single recommendation is: "fix the implementation AND both docs in the same commit." Partial fixes recreate the defect in the next cycle.

---

### Multi-auditor transient-retention findings: consolidate at the highest single-auditor severity, not escalated

When 4 auditors independently note the same retained-Transient registration, the correct synthesis rating is the highest single-auditor severity (🟡 Medium, from the auditor whose scope is most directly about lifecycle correctness — Maintainability or Correctness). Do not escalate to High unless the retained Transient is also a confirmed captive dependency of a Singleton. "Four auditors noticed it" signals breadth of concern, not increased severity when no defect path exists.

---

### Captive-dep machine scan: rate the commit-introduced subset as High; pre-existing violations as Medium context

When a pre-scan script produces a combined list of pre-existing + newly-introduced captive dependencies, only the newly-introduced subset (caused by this commit's batch Singleton promotion) should be rated at the commit's severity. Pre-existing violations provide context for the overall codebase health but should not be attributed to this commit's scope. The distinction should be called out explicitly in the synthesis report.

---

### Security-critical method extraction: structural + correctness + coverage = one Critical finding with three-part fix
A private security-critical method that is (a) structurally inaccessible to tests, (b) confirmed to have a correctness bug, and (c) has zero tests collapses to one Critical: (1) extract to internal static class, (2) `InternalsVisibleTo`, (3) write failing tests first (TDD order).

---

### `void → bool` promotion: scan ALL call sites across the entire source tree
When any method is promoted from `void` to returning `bool` (rejection signal), the Ripple Effect audit should scan all callers — not just the files touched in the changeset. Callers that don't route on the return value will silently discard the rejection. The highest-risk caller is one that reads entity state immediately after the call (trusting the entity was mutated when it was not). This is a distinct and complementary finding to the unit-test gap: fix the call site AND add the test.

---

### Use the user-provided deduplication map as the authoritative consolidation plan
When the review brief provides a cross-auditor deduplication map, use it as-is. Do not re-derive groupings. Deviating from the map introduces inconsistency without value.

---

### Security + Performance co-flag on same endpoint: one High, Security framing leads
When Security and Performance both flag the same missing control, lead with the Security framing (attack vector, OWASP reference), append the Performance impact as quantification. One finding, one fix.

---

### Transient→Singleton mass promotion: scan for "left-behind" Transient dependencies consumed by promoted Singletons
When a PR promotes many services from Transient to Singleton, the Ripple Effect auditor should also scan services that are _consumed by_ the promoted types. Any service that is still Transient but injected into a newly-promoted Singleton is a captive dependency — effectively application-lifetime without the intent. Flag as High when the omission directly contradicts the PR's stated goal (promote all stateless services). The fix is always trivial if the consumed service is confirmed stateless.

---

### Partition High findings into "blocks merge" vs. "recommended before next slice"
With 7+ High findings, add a "Blocks Merge?" column to the summary table. Criteria for a merge blocker: active exploit, silent data corruption, or permanently broken test suite that makes future tests silently wrong.

---

### Save/restore pattern produces a predictable four-auditor cluster
Expect these four findings independently: Correctness (defensive skip path untested), Coverage (Reset/null-clear untested), Testability (round-trip test verifies state but not triggered side effects), Extensibility (no structural enforcement of required step pairing). Synthesize as four distinct Mediums — they have different locations and fixes.

---

### Deduplication: consolidate on the strongest single statement, not the union
Choose the auditor whose framing captures full impact, lead with it, append other dimensions parenthetically. Do not list the same code location three times at three severity levels.

---

### Zero-test codebase is always a High finding regardless of code quality
The absence of tests means every correctness bug has no regression guard and every refactor is unguarded. Frame this clearly — do not soften as "technical debt."

---

### Correctness audit may miss behavioral divergence when requirements are inferred from new code
When the Correctness audit reads the new code to infer requirements, it may miss behavior differences vs. the old path. Cross-check: if old path handles categories {A, B} and new path handles only {A}, verify whether the omission of {B} was intentional.

---

### Guard-pattern commits have a characteristic finding signature
Expect from guard-adding commits: Maintainability (stale "impossible condition" comment), Coverage (`Assert.DoesNotThrow` with non-throwing mock, `Times.AtLeastOnce` instead of `Times.Once`), Extensibility (type-check instead of polymorphic dispatch). All three appear together.

---

### Trust the individual auditor's classification over the orchestrator summary
When the orchestrator's pre-deduplication summary lists a finding under two severity tiers (formatting error), check the individual auditor's own severity label and use that.

---

### Stale audit file: derive findings from the orchestrator's dedup map
If an auditor's output file contains content from a prior review phase, proceed with synthesis using the orchestrator's provided deduplication map rather than retrying the read.

---

### Severity overlap between RE/TB/EX and Maintainability: consolidate at the highest observed
When Maintainability rates a finding Low but Ripple Effect, Testability, and Extensibility all rate the same root issue Medium, synthesize at Medium. The cross-project impact dimension dominates.

---

### High auditor-convergence count does not escalate CI/timing smells
Convergence signals importance (use a CROSS-X label); it does not change severity. CI fragility and magic-number timing patterns remain Medium regardless of how many auditors flag them. Critical requires: active exploit, production correctness failure, or silently-broken future tests.

---

### Correction commit fixing only one of two symmetric write sites: Ripple Effect is authoritative
When a "fix" commit updates one write site but misses a symmetric second, defer to the Ripple Effect auditor's severity rating. Include "both write sites must be updated together" in the recommendation.

---

### Formally-deferred item not re-checked when its target feature ships: rate High, fix implementation + arch doc together
When Requirements and Ripple Effect both flag an unimplemented formally-deferred item in a feature that was supposed to deliver it, rate High (the gap was expected to close at this review). Fix the implementation and update the stale "deferred to X" doc in the same commit.

---

### Binary ternary on a growing enum: when Security auditor identifies a scope-confusion attack vector, elevate to High
When Correctness, Maintainability, Extensibility, and Structural all flag the same binary ternary at varying severities, and Security identifies a concrete misclassification attack path, elevate the consolidated finding to High. The security impact dominates the severity calculation.

---

### Infrastructure-scale test additions: check write/edit/save workflow coverage specifically
When a change adds many read/view/navigation tests, check whether any edit/save workflow is covered. Uncovered save paths are the most regression-prone target. Synthesize the gap as High even when components are structurally correct.

---

### Compound findings: one root cause producing N gap surfaces → one High with numbered bullet points
When a single structural gap produces gap surfaces across views, ViewModels, and interfaces, combine into one High finding with numbered sub-impacts. Reserve separate findings for gaps with distinct root causes or materially different fix efforts.

---

### "Verified by contract tests" claims require explicit cross-audit verification
Before treating "verified by contract tests" documentation as factual, cross-reference against the test file contents. An unverified documentation claim is more dangerous than a simple missing test — it suppresses further investigation.

---

### Exit code precision: `.NotBe(0)` vs `.Be(1)` is a High finding in contract test suites
In a suite whose purpose is to verify a CLI exit code contract, imprecise assertions (`.NotBe(0)`) allow unhandled exceptions to pass silently. Rate High — the test suite fails to fulfill its specification.

---

### Performance vs. Maintainability severity disagreement: use production failure risk to adjudicate
When Performance rates High (production failure mode: silent exception suppression, thread unsafety) and Maintainability rates Medium (code quality), take the higher rating when the justification is a production failure mode.

---

### Symmetric-path ripple findings: enumerate ALL asymmetric cases from the table, not just the auditor's primary one
When the Ripple Effect audit includes a symmetric path analysis table, list all findings from that table — not just the primary High finding the auditor called out.

---

### Divergent parallel dispatch paths: flag the planning document as a companion finding
When a Ripple Effect audit finds code that contradicts the canonical state machine, check whether a planning document also documents the illegal pattern. A planning doc that teaches developers to reproduce a bug is a separate finding from the code fix.

---

### Severity disagreement on dead toggle-ON test branches: resolve to High
Coverage says Critical (toggle paths untested), Correctness and Requirements say Medium (logic correct, test-only gap). Resolve to High: primary PR behavior has no unit test coverage, but no runtime bug found and characterization tests provide empirical coverage.

---

### DIM factory pattern Medium/Low disagreement is not a conflict: include both angles
Maintainability rates the factory pattern Medium (identity instability); Extensibility rates it Low (discoverability). Both are correct — different quality dimensions. Include both angles in one Medium finding.

---

### All-Medium/Low landscape: synthesizer's primary task is de-duplication, not conflict resolution
When no auditor returns Critical or High, collapse redundant entries first (same code element, different auditors), then sort. Do not list the same code location at multiple severities.

---

### Same element introduced in this PR: do not apply the pre-existing downgrade rule
The pre-existing downgrade rule ("lower severity for pre-existing issues") applies only to code that predates the PR. For code introduced in the changeset, take the highest auditor rating.

---

### MVVM Singleton Coupling Cluster has a predictable multi-auditor signature
A pattern where a global singleton messenger, direct clock access, and active flag in the constructor co-occur produces: Testability (High: injection seams missing), Extensibility (High: side-effect at construction; Medium: global messenger), Performance (High: fire-and-forget on global singleton). Synthesize as one cluster finding with a single three-part fix: inject `IMessenger` and `TimeProvider`, forward messenger to base, move activation to `OnNavigatedTo`.

---

### Pre-existing zero-test gap does not block merge — but say so explicitly
When a test gap is pre-existing and the changeset does not worsen it, the verdict is "Approved with Suggestions." State explicitly: (1) gap is pre-existing, (2) the changeset's highest-value test targets by name, (3) merge is not blocked. Do not let a "Critical" severity label from one auditor override a correct merge decision.

---

### Three-auditor convergence on the same Medium finding: consolidate, do not escalate
Convergence of three auditors on the same element at Medium from different angles merits one consolidated finding citing all three — NOT escalation to High. Escalation to High requires at least one auditor independently rating it High.

---

### Partial infrastructure migration rates Medium in synthesis even when individual audit rates Low
When a new pattern is globally available and unmigrated sibling components share an identical structure, rate the asymmetry Medium in synthesis. The split user experience dimension elevates it above the Ripple Effect auditor's per-item Low.

---

### Zero-test subsystems: highest-value test targets follow a predictable priority cluster
Priority: (1) core behavioral fix methods with multiple edge-case branches (Critical — pure computation, most regression-prone), (2) ViewModel feedback trigger paths (High — user-visible signals, small effort once infrastructure exists), (3) computed property invariants with non-obvious snapshot semantics (High — guard dirty-state and save-button UX behaviors).

---

### Fire-and-Forget quadruple-flagging: maximum-confidence signal, rate High regardless of individual ratings
When `_ = SomeAsync(...)` in a `void Receive()` is flagged by four independent auditors, escalate to High. List all impact vectors (exception loss, thread safety, stale state, test racing) in one finding. Single fix: try/catch + main-thread dispatch.

---

### Full-project zero-test review: Coverage audit generates 2–4× more findings than any other — emphasize batch resolution
Emphasize in synthesis that building the test project infrastructure resolves the Critical and most High coverage findings simultaneously. Present as "build the test project, then write tests in this priority order" — not as N independent line items.

---

### Notification propagation bugs are user-visible correctness bugs, not design issues
When a Ripple Effect auditor flags "computed property X not notified after mutation," label it "user-visible bug" in the finding title, rate High, and note the trivially small fix. This framing ensures it gets prioritized ahead of design-smell findings.

---

### Multi-host DI consolidation: synthesizer must ask "did any other composition root get missed?"
When a DI consolidation changeset touches multiple hosts, check explicitly whether platform-specific startup files (mobile, desktop, background service) are represented. Missing hosts have two failure modes: stale duplicate registrations and missing registrations producing silent behavioral divergence.

---

### Environment-default changes produce a three-artifact documentation ripple
A CLI/script default change ripples to: (1) operational runbooks with example commands, (2) reference docs with static descriptions, (3) architecture docs with inline configuration sequence prose. Two or more stale → High; one stale → Medium. All three must be updated in the same changeset.

---

### Test infrastructure `ValidateScopes` absence elevates to High when the suite's stated purpose is DI correctness
If the test infrastructure's design documentation claims it detects captive dependency bugs and `ValidateScopes = true` is absent, the failing-to-fulfill-its-specification criterion applies. Elevate from Performance auditor's Medium to synthesis High.

---

### Unreachable infrastructure cluster is ONE Critical finding, not N findings
When a fully-implemented subsystem has no entry point, the critical finding is the missing entry point. The secondary missing commands are separate Medium findings. Explicitly note whether DI complexity makes wiring Large vs. Small effort.

---

### Structural patterns disambiguation notes belong in the executive summary
When a structural patterns auditor explicitly explains why a code element resembles Pattern X but is categorically distinct from it, include the disambiguation in the executive summary. One sentence: "N patterns were cleanly vetted; the key disambiguation was [element] — this is Pattern Y, not Pattern X."

---

### Dead-code-with-active-duplicate: verify caller-layer before rating High
Before accepting "dead code that duplicates an existing active implementation" as High, verify whether callers exist in sibling layers. Theoretical ambiguity (no caller overlap today) = Medium. Immediate compile/runtime conflict = High.

---

### Predicate duplication and double-evaluation are distinct findings — do not merge them
The DRY violation (Maintainability) and the double computation (Performance) concern different future states. List them separately — a developer may fix one without the other.

---

### Dev-tool + Framework-hook PRs: Framework API findings escalate by convergence; DevTools findings stay at per-auditor ratings
The Framework API test gap will collect 3+ independent flags (Coverage, Testability, Ripple Effect) — escalate to High. DevTools layer findings appear in at most one auditor's report — keep at per-auditor severity. Do not cross-extrapolate.

---

### Bool-flag constructor parameter flagged by 3 auditors converges to Medium even when each rates it Low
Per-auditor Low + 3-auditor convergence → synthesized Medium. Do not drop the finding even when each auditor qualifies it as "mitigated by interface."

---

### Two auditors recommend the same method with different names: resolve by framework naming convention
When two auditors propose the same new method but name it differently, pick the name consistent with the underlying framework/library naming. Document the choice to prevent future naming churn.

---

### Three or more independent auditors on the same finding: include it regardless of individual severity
Three independent detections constitute stronger evidence than any single auditor's rating. Include in the report even at aggregated Low. The convergence line should be visible in the finding.

---

### Severity discrepancy is usually a pre-existing vs. introduced distinction — check that first
Before treating a two-auditor severity disagreement as a factual conflict, check whether one is judging absolute severity and the other applied the pre-existing downgrade. If so, defer to the lower rating for pre-existing code.

---
