# LessonsLearned Audit — Remediation Plan

**Audit date:** June 2, 2026  
**Files audited:** 9 `REVIEW-*/LessonsLearned.GLOBAL.md` files in this directory  
**Status:** Contamination sanitization committed. Structural and escalation work pending.

---

## Health Dashboard

| Auditor | Entries | Health | Contaminated | Escalate | Wrong-Skill | Bloat | Dup |
|---|---|---|---|---|---|---|---|
| ExtensibilityAuditor | 24 | **Critical** | 2 ✅ fixed | 4 | 4 | 0 | 2 |
| FinalSynthesizer | 36 | **High debt** | 6 ✅ fixed | 2 | 0 | 3 | 1 |
| MaintainabilityAuditor | 27 | **Moderate debt** | 0 | 9 | 6 | 2 | 1 |
| PerformanceAuditor | 15 | **High debt** | 3 ✅ fixed | 6 | 2 | 1 | 2 |
| RippleEffectAuditor | 38 | **Critical** | 2 ✅ fixed | 2 | 2 | 6 | 2 |
| SecurityAuditor | 44 | **Moderate debt** | 0 | 10 | 1 | 4 | 4 |
| StructuralPatternsAuditor | 34 | **High debt** | 2 ✅ fixed | 13 | 2 | 6 | 1 |
| TestabilityAuditor | 55 | **Good** | 5 ✅ fixed | 1 | 6 | 2 | 2 |
| UnitTestCoverageAuditor | 17 | **Moderate debt** | 3 ✅ fixed | 16 | 1 | 4 | 0 |

---

## Definition of Done

All checkboxes below must be ticked before this remediation is considered complete.

- [x] Zero contaminated entries survive in any GLOBAL.md (spot-check each ✅-marked file post-fix)
- [x] Zero phantom/empty-body entries in FinalSynthesizer (entries 20, 27, 28)
- [x] Zero orphaned content appended to wrong entry bodies (RippleEffectAuditor entry 9, UnitTestCoverageAuditor Inner-Loop entry, PerformanceAuditor entry N)
- [x] PerformanceAuditor numbering is unambiguous — no duplicate lesson numbers
- [x] MaintainabilityAuditor orphaned seeded-instruction block is removed
- [x] "When to Append" sections that appear mid-file are repositioned (UnitTestCoverageAuditor, ExtensibilityAuditor)
- [x] Every agent that has ≥5 ESCALATE candidates has received at least its top 3 escalations applied to the corresponding `agents/REVIEW-*.agent.md`
- [x] UnitTestCoverageAuditor receives the 5 highest-priority escalations (entries 9, 10, 12, 16, 17) — this file has been doing the agent's job
- [x] All duplicate pairs resolved (one entry removed or merged per pair)
- [x] All confirmed WRONG-SKILL entries moved or copied to the correct destination file

---

## Phase 1 — Structural Integrity

*These are pure correctness fixes. No judgment calls. Do these first.*

### FinalSynthesizer — Phantom entries

The audit found 3 entries (20, 27, 28) that have empty bodies because their content was accidentally appended to the wrong entries (25, 31, 30 respectively). The symptom is a heading with no text beneath it before the next `---` divider.

- [x] Restore or remove phantom entry 20 (content accidentally merged into entry 25)
- [x] Restore or remove phantom entry 27 (content accidentally merged into entry 31)
- [x] Restore or remove phantom entry 28 (content accidentally merged into entry 30)

### RippleEffectAuditor — Orphaned body fragment

Entry 9 has a ViewModel heuristic from entry 26 appended to its body, making entry 9 incoherent as a standalone lesson.

- [x] Remove the orphaned ViewModel paragraph from entry 9's body

### UnitTestCoverageAuditor — Orphaned sentence fragment

The Inner-Loop Strategy entry has a 2-sentence orphaned fragment from a deleted Guard entry appended after its concluding paragraph.

- [x] Remove the orphaned fragment from the Inner-Loop Strategy entry

### PerformanceAuditor — Orphaned JSONB rule

Entry N has an unrelated JSONB filtering rule pasted at the end of a permission-projection entry. The JSONB rule belongs in Lesson 008.

- [x] Move the orphaned JSONB rule from entry N into Lesson 008 (or remove it if it's already covered there)

### PerformanceAuditor — Collapsed numbering

Three entries are labeled "009" and three entries are labeled "010". Lesson references are ambiguous.

- [x] Renumber all entries sequentially (001–015), preserving date order

### MaintainabilityAuditor — Orphaned instruction block

A seeded instruction block from the original file template was never removed; it sits between entries 5 and 6 and is not a lesson.

- [x] Remove the orphaned instruction block between entries 5 and 6

### UnitTestCoverageAuditor — Mid-file meta-section

The "When to Append an Entry" guidance section is embedded mid-file rather than at the top or bottom.

- [x] Move "When to Append" to immediately after the header block (before the first `---` divider)

### ExtensibilityAuditor — Mid-file meta-section

Same issue — "When to Append" appears between content entries.

- [x] Move "When to Append" to immediately after the header block

---

## Phase 2 — Escalations to Agent Definitions

*Add mature patterns to `agents/REVIEW-*.agent.md`. These reduce future false-positive audits and expand agent coverage without adding fragile LL entries.*

### UnitTestCoverageAuditor → `agents/REVIEW-UnitTestCoverageAuditor.agent.md` (16/17 entries are candidates)

The LL file has been doing the agent's job. These 5 are highest-priority:

- [x] Entry 9: `"Met" ≠ "Tested"` — passing scenario coverage with no assertable outcome
- [x] Entry 10: Filter-before-assert trap — test asserts the result of a filter, not the method output
- [x] Entry 12: Deleted Guard = Required Replacement Test (High by default)
- [x] Entry 16: Zero-test infrastructure protocol — the full sequence for bootstrapping a new test project
- [x] Entry 17: Security-critical private static = Critical untestable gap

Remaining 11 UnitTestCoverageAuditor escalations:
- [x] Entries 1, 2, 3, 4, 5, 6, 7, 8, 11, 13, 14 — escalate to agent.md and remove from LL

### SecurityAuditor → `agents/REVIEW-SecurityAuditor.agent.md` (10 candidates)

- [x] Entry 1: EF Core raw SQL injection shortcut — check `ExecuteSqlRaw` / `FromSqlRaw` with interpolated strings
- [x] Entry 2: Create/update validation asymmetry — DTO validation often stricter on create than update
- [x] Entry 17: Login endpoint CSRF — `[IgnoreAntiforgeryToken]` on login is a known gap pattern
- [x] Entry 21: `[Authorize]` vs. authorization policies — attribute presence ≠ authorization intent verified
- [x] Entry 23: Rate limiting on auth endpoints — absence = High regardless of codebase size
- [x] Entry 28: Timing attacks — constant-time comparison requirement for secret/token comparison
- [x] Entry 30: Open redirect via protocol-relative URLs (`//evil.com`)
- [x] Entry 35: Pre-existing gap escalation — when Ripple Effect finds a pre-existing gap newly reachable, Security must re-rate
- [x] Entry 38: Deny-grant service-layer validation — grant-side check without deny-side mirror
- [x] Entry 43: Dual-nature finding re-characterization (correctness + security co-flag)

### StructuralPatternsAuditor → `agents/REVIEW-StructuralPatternsAuditor.agent.md` (13 candidates)

- [x] Entry 5: False-positive gate for SP-003 when DI is deliberate (documented reason)
- [x] Entry 6: Feature envy on state transition (state machine lives in caller, not model)
- [x] Entry 9: God-file detection at file-scope accumulation level (not just class level)
- [x] Entry 11: Side-channel state sharing via keyed string store
- [x] Entry 12: CLI entrypoint as highest-probability god-file site
- [x] Entry 17: SP calibration — when injection is intentional architectural choice (not smell)
- [x] Entry 18: Two-responsibility class with symmetrical sub-concerns (Medium, not High)
- [x] Entries 23, 25, 27, 29, 32 — remaining pattern-catalog additions

### MaintainabilityAuditor → `agents/REVIEW-MaintainabilityAuditor.agent.md` (9 candidates)

- [x] Entry 1: Toggle-duplication carve-out — the one-toggle-per-feature exception to the duplication rule
- [x] Entry 8: DIM identity instability pattern — principle of least surprise violation
- [x] Entries 11 + 24 (merged): prior audit chain severity elevation — LL finding rated higher than original audit
- [x] Entry 16: Factory-consolidation SRP exception — when merging factories is the right call
- [x] Entry 19: Encapsulation of validation logic — where validation should live on a model
- [x] Entry 22: Caller-owned state machine — structural root cause of correctness findings
- [x] Entry 23: Sparse documentation of non-obvious invariants — when "no comment" is the smell
- [x] Entry 27: Behavioral symmetry requirement on paired methods (create/delete, open/close)

### ExtensibilityAuditor → `agents/REVIEW-ExtensibilityAuditor.agent.md` (4 candidates)

- [x] Entry 11: Positive extensibility features callout gap — when to credit intentional open/closed design
- [x] Entries 13 + 14 (merged): security-intentional closed patterns (closed-by-design is not an extensibility failure)
- [x] Entry 15: Convergent findings grouping — three auditors flag same element; synthesize extensibility angle

### RippleEffectAuditor → `agents/REVIEW-RippleEffectAuditor.agent.md` (2 candidates)

- [x] Entry 36: Critical→High synthesis annotation gap — when to note a severity downgrade in the output
- [x] Entry 37: DI pass-through vs. direct consumer — dependency flows through an intermediary that doesn't use it

### FinalSynthesizer → `agents/REVIEW-FinalSynthesizer.agent.md` (2 candidates)

- [x] Entry 14: "Blocks merge?" partition concept — split High findings into merge-blockers vs. recommended-before-next-slice
- [x] Entry 7: "MERGE WITH CONDITIONS" verdict framing — deferred-per-spec security findings do not collapse to PASS

### TestabilityAuditor → `agents/REVIEW-TestabilityAuditor.agent.md` (1 candidate)

- [x] Entry 2: Non-disclosure / output-equivalence wildcard assertion gap — add to "Observable Outcomes" section

---

## Phase 3 — Wrong-Skill Migrations

*Move entries to the correct file. Copy the full entry text, then delete from source.*

### → UnitTestCoverageAuditor

| Source | Entries | Description |
|---|---|---|
| TestabilityAuditor | 7, 9, 11 | Test naming convention; guard paths coverage; inverted assertion |
| TestabilityAuditor | 8 | Tests naming private methods (naming convention) — also consider MaintainabilityAuditor |
| RippleEffectAuditor | 23, 24 | Test infrastructure and coverage-gap patterns |
| MaintainabilityAuditor | 9 | Coverage gap on a maintainability finding |
| SecurityAuditor | 42 | Unawaited `ThrowAsync` — test coverage gap |

- [x] Move TestabilityAuditor entries 7, 9, 11 → UnitTestCoverageAuditor
- [x] Move/copy TestabilityAuditor entry 8 → MaintainabilityAuditor (naming) or UnitTestCoverageAuditor (convention)
- [x] Move RippleEffectAuditor entries 23, 24 → UnitTestCoverageAuditor
- [x] Move MaintainabilityAuditor entry 9 → UnitTestCoverageAuditor
- [x] Move SecurityAuditor entry 42 → UnitTestCoverageAuditor

### → SecurityAuditor

| Source | Entries | Description |
|---|---|---|
| MaintainabilityAuditor | 13, 14, 15 | Authentication, authorization, and secrets-handling observations |
| PerformanceAuditor | E | Rate limiting — belongs in SecurityAuditor (performance angle is secondary) |

- [x] Move MaintainabilityAuditor entries 13, 14, 15 → SecurityAuditor
- [x] Move PerformanceAuditor entry E → SecurityAuditor

### → TestabilityAuditor

| Source | Entries | Description |
|---|---|---|
| MaintainabilityAuditor | 21 | Test fixture design pattern |
| ExtensibilityAuditor | 16, 17 | `data-testid` convention; private seeding helper |
| ExtensibilityAuditor | 24 | `IsActive=true` in MVVM constructor (testability seam) |

- [x] Move MaintainabilityAuditor entry 21 → TestabilityAuditor
- [x] Move ExtensibilityAuditor entries 16, 17, 24 → TestabilityAuditor

### → `writing-e2e-tests` skill LL

| Source | Entries | Description |
|---|---|---|
| TestabilityAuditor | 15, 16 | Circuit-open signals / Blazor E2E; `data-testid` without entity identity attribute |

- [x] Move TestabilityAuditor entries 15, 16 → `skills/writing-e2e-tests/LessonsLearned.GLOBAL.md`

### → CodeCorrectnessAuditor

| Source | Entries | Description |
|---|---|---|
| PerformanceAuditor | G | EF Core count-only `ValueComparer` — it's a correctness bug, not a perf win |
| MaintainabilityAuditor | 6 | Correctness/ripple concern misfiled under maintainability |

- [x] Move PerformanceAuditor entry G → CodeCorrectnessAuditor LL
- [x] Move MaintainabilityAuditor entry 6 → CodeCorrectnessAuditor or RippleEffectAuditor LL

---

## Phase 4 — Deduplication

*One entry removed or merged per pair. Keep the entry with the stronger wording.*

| File | Pair | Keep | Remove |
|---|---|---|---|
| ExtensibilityAuditor | #13 + #14 | Merged single entry | Both originals |
| FinalSynthesizer | entry 16 | entries 3/13/17 (covered by all three) | Remove entry 16 |
| FinalSynthesizer | entry 21 | Review: may be stale model-behavior entry | Remove if stale |
| MaintainabilityAuditor | entries 11 + 24 | Merged: 11 body + 24 severity insight | Both originals |
| PerformanceAuditor | C + E (BCrypt entries) | Merge BCrypt calibration into one entry | Remove one |
| PerformanceAuditor | L + M (`IReadOnlyList<T>`) | Keep stronger framing | Remove weaker |
| RippleEffectAuditor | entries 9 + 27 | Keep entry 27 (stronger, no orphaned content) | Remove entry 9 |
| SecurityAuditor | entries 3 + 29 | Keep the more recent / complete one | Remove other |
| SecurityAuditor | entries 13 + 24 | Keep the more complete one | Remove other |
| TestabilityAuditor | entries 20 + 49 | Merged: entry 20 body + `= default` recommendation from 49 | Remove entry 49 |

- [x] Resolve all duplicate pairs listed above (one action per row)

---

## Phase 5 — Bloat Reduction

*Condense long entries to the essential signal. Target: each entry fits in 10–15 lines.*

- [x] RippleEffectAuditor: condense entries 1, 3, 8 (6 bloated entries total — do all 6)
- [x] SecurityAuditor: condense entries 6, 16, 39, 42
- [x] StructuralPatternsAuditor: condense 6 bloated entries (the file is ~690 lines — prioritize)
- [x] MaintainabilityAuditor: condense entries 7, 20
- [x] TestabilityAuditor: condense entries 4, 29
- [x] UnitTestCoverageAuditor: condense 4 oversized entries

---

## Phase 6 — Process Hardening

*Structural improvements that prevent new debt from accumulating.*

### Hooks

~~- [ ] Formalize RippleEffectAuditor entry 14 (orphaned enum detection) as a hook in `hooks/`~~
~~- [ ] Formalize RippleEffectAuditor entry 30 (hardcoded enum arrays) as a hook~~
~~- [ ] Formalize TestabilityAuditor entry 13 (`ExecuteUpdateAsync|ExecuteDeleteAsync`) as a hook~~
~~- [ ] Formalize TestabilityAuditor entry 34 (`Environment.Exit()`) as a hook~~
~~- [ ] Formalize StructuralPatternsAuditor entry 22 (`Task.FromResult`) as a hook~~

> ~~Cancelled — hook stubs were deleted; hooks not deemed useful enough to implement.~~

### StructuralPatternsAuditor — Stale SP numbers

Seven entries propose SP catalog numbers that are now wrong (the catalog has grown since they were written).

- [x] Audit the current SP catalog in `agents/REVIEW-StructuralPatternsAuditor.agent.md`
- [x] Update all stale "SP-00N" proposals in the LL file to use the correct current numbers (or "TBD" if not yet added)
- [x] Renumber the StructuralPatternsAuditor entries 1–34 (collapsed numbering, numbers 4–15 appear 2–3× each)

### Category tags

- [x] PerformanceAuditor: add `Category:` tag to all entries (none have one)
- [x] ExtensibilityAuditor: add `Category:` tag to all entries (none have one)

---

## Work Order Recommendation

Work sequentially through phases 1–6. Phases 1 and 2 deliver the highest risk reduction per hour:

1. **Phase 1** first — structural defects cause corruption of downstream reads; they block everything else
2. **Phase 2 (UnitTestCoverageAuditor escalations)** second — 16 entries need to move; the agent.md is the most under-specified
3. **Phase 2 (SecurityAuditor escalations)** third — 10 high-value patterns not yet in the agent definition
4. **Phase 3 (wrong-skill migrations)** — can be done in parallel with Phase 2 work
5. **Phase 4 (deduplication)** — quick wins after wrong-skill moves are done
6. **Phase 5 (bloat)** + **Phase 6 (process hardening)** — last, as they have lower urgency

**Largest single investment:** StructuralPatternsAuditor. At ~690 lines with 13 escalation candidates, collapsed numbering, and stale SP numbers, it will need its own focused session spanning Phases 2, 4, 5, and 6.
