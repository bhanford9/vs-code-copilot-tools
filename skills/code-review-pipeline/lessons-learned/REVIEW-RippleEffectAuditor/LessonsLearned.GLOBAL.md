# Lessons Learned: REVIEW-RippleEffectAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future ripple-effect reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-08 — ViewModel-Mirror Anti-Pattern

**Pattern**: When a ViewModel is a full property-for-property mirror of a domain entity, there are typically TWO separate "copy entity fields" paths: a factory/constructor for initial load and an `UpdateXxx()` method for in-place refresh. These are parallel implementations of the same projection logic. **Both must be found and enumerated** as ripple targets when the entity gains a new field. Searching only for the factory and missing the update method is a common false-completeness error.

**Heuristic**: For any entity-to-ViewModel class pair, always search for both (a) a `FromX()` or `CreateFromX()` factory and (b) an `UpdateX()` or `SyncFrom()` method. If both exist without shared code, flag them as co-evolution risk.

## 2026-05-08 — Flat-Parameter Interface as Blast-Radius Amplifier

**Pattern**: When a service interface method enumerates an entity's mutable fields as individual parameters (e.g., `Add(string title, string desc, Enum horizon, Enum effort, bool flag, int score, Enum? override)`), every entity field addition requires: interface signature change + implementation change + every caller change. The interface acts as a blast-radius multiplier, not an abstraction. **Always check** whether callers use named arguments; positional-only calls are an additional silent-failure risk when parameters are reordered or inserted.

**Heuristic**: Count the parameters on service interface methods. More than 4–5 parameters that map directly to entity properties is a signal to recommend a request/command object.

## 2026-05-08 — Hardcoded Enum Enumeration in UI Components

**Pattern**: When UI components declare `private static readonly SomeEnum[] ValidValues = [A, B, C]` or equivalent dictionaries keyed by an enum, they silently become stale when a new enum value is added. These arrays never fail to compile — they simply omit the new value from the rendered output. This is one of the highest-risk silent failure patterns for enum extension.

**Heuristic**: When analyzing ripple effects of adding an enum value, search for static arrays and dictionaries whose keys are the enum type — these are the most likely silent-omission sites, more dangerous than switch statements (which at least can be made exhaustive with warnings).

## 2026-05-12 — "Non-Actionable Status" Filter Pattern

**Pattern**: When a codebase adds a "terminal-adjacent" or "non-actionable" status (e.g., `Blocked`, `OnHold`, `Skipped`), recommendation/filter views that already exclude `Completed` status typically need to be updated to exclude the new status too. These views almost always use `Status != Completed` as the only exclusion filter. The new status satisfies `!= Completed`, so it silently appears as actionable in the output.

**Heuristic**: When auditing a new status value, search for views that filter by `!= Completed` or `== Active` — these are the most likely sites where the new status needs to be added to the exclusion list. Pay particular attention to "priority recommendation" or "what to do next" views where unactionable items degrade trust.

## 2026-05-12 — Edit Draft / Form Model as a Silent Data-Loss Site

**Pattern**: When an entity has fields that exist in both the persistence (request records) and the UI (a form model / draft object), any field added to the entity must be added to the form model or the save path will silently overwrite it with the field's default. This is the "edit draft" companion pattern. It differs from the ViewModel-Mirror pattern because: the ViewModel omission makes the field *invisible*, while the draft omission makes the field *destructively cleared on save*.

**Heuristic**: When analyzing ripple effects of an entity field addition, always check: (1) request record ✅, (2) service implementation ✅, (3) ViewModel ⚠️, and (4) edit draft / form model ⚠️. Steps 3 and 4 are the most commonly missed and have different impact profiles — step 3 is visibility loss, step 4 is data loss.

## 2026-05-08 — "Critical" Severity for Blast-Radius Findings Gets Resolved Down to High in Synthesis

**Pattern**: The Ripple Effect Auditor appropriately uses "Critical" to signal "the blast radius of this common change scenario is dangerously wide with silent failure modes." However, the Final Synthesizer uses "Critical" to mean "current data corruption or confirmed runtime bug." These scales do not align, and the mismatch causes final-report inflation.

**Heuristic**: When assigning severity in the Ripple Effect audit, annotate findings that are future-change concerns (no current bug) vs. findings where the silent failure mode is already triggered by the current codebase. This annotation helps the synthesizer apply the correct resolution: pure blast-radius findings → resolve to High; currently-triggered silent failure → keep as Critical.

## 2026-05-12 — DI Pass-Through Pattern: Interface Member Additions Propagate Automatically

**Pattern**: When all production-code consumers of an interface simply *pass the instance through* to another constructor (e.g., a flow, a builder, a sub-component), they do NOT need to be updated when the interface gains a new member. The DI container resolves the concrete type, which already has the new member. The only call sites that truly need updating are: (a) direct mocks of the interface in unit tests, and (b) any location that calls the new property explicitly. Pass-through sites are transparent to the contract change.

**Heuristic**: During call site analysis, distinguish *pass-through* sites from *direct consumers* early. Pass-through sites — those that store the interface reference and hand it to another constructor — require no action. Only direct consumers (tests that mock it, code that calls `.NewProperty`) need verification. This quickly reduces the surface area to audit.

## 2026-05-12 — Sub-Flow Test Architecture Insulates Lower-Level Interface Mocks

**Pattern**: In codebases where tests mock a "logic provider" interface that contains both step actions and sub-flows, tests at the outer flow level mock the outer interface (e.g., `IReinforcedSeatSelectionLogicProvider`) and return `MockSubFlow(...)` for any inner sub-flows. This means the inner flow's own logic provider interface (e.g., `IBottomChordDesignEngineLogicProvider`) is never directly mocked in those outer tests. Consequently, adding a member to the inner interface creates no new mock gap in outer tests — only the direct mock of the inner interface (the inner flow's own test file) needs updating.

**Heuristic**: When an interface change affects an interface that is consumed exclusively inside a named sub-flow class, check: (1) does the sub-flow's own test file mock the interface directly? (2) do any outer tests mock it directly? The answers narrow the mock gap to only the sub-flow's test file, not every test that transitively uses the flow.

## 2026-05-13 — Reverted Code Is Still Valid Review Scope

**Pattern**: When reviewing commits by hash, check `git log` to see if the change was subsequently reverted before beginning codebase-state searches. If it was reverted, searching HEAD will return no matches for new classes, methods, or file changes — leading to false "no call sites" conclusions. The correct approach is to do all ripple searches directly against the commit content (`git show <hash>:path/to/file`) rather than the live workspace.

**Heuristic**: At the start of any hash-specific review, run `git log --oneline -20` and check for a revert commit targeting the PR under review. If found, note it in the report preamble, source all companion searches from the commit objects rather than HEAD, and avoid grep_search (which scans the working tree) for finding call sites of code that has been reverted.

## 2026-05-13 — Optional DI Parameter as Zero-Blast-Radius Companion Pattern

**Pattern**: When a constructor adds an optional parameter with `= null` as its last argument (especially with a `?` nullable type), the blast radius is exactly zero for DI-managed consumers — the DI container simply omits the argument when the type is not registered. Direct instantiation sites would be affected, but framework-layer classes with internal sealed access modifiers typically have no direct `new ClassName(...)` call sites. In these cases, the ripple analysis for "DesignEngineFlowRunner constructor change" correctly resolves to a single finding: confirm no direct instantiation exists.

**Heuristic**: When a constructor gains an optional nullable parameter, search for `new ClassName(` before analyzing DI call sites. If no direct instantiation exists (internal/sealed class), the finding is trivially closed. If direct instantiation exists, those are the only call sites to verify.

## 2026-05-13 — `protected virtual` Template Hook Without Enforcement Is a Future Fragility, Not a Current Bug

**Pattern**: When a base class introduces a `protected virtual` method that contains critical wiring logic (e.g., registering a service), and no current subclass overrides it, the ripple finding is "future fragility" not "current bug." The correct severity is Medium or Low depending on whether the method name clearly communicates its override expectations. If the method is named like a hook that developers would naturally override (e.g., `ConfigureAdditionalServices`), the risk is real but future-facing. Severity should be Medium and the recommendation should be a naming/documentation fix, not a structural refactor.

**Heuristic**: For `protected virtual` companion methods introduced alongside a feature: (1) verify no existing subclass overrides it — if none, it's future-facing only; (2) assess whether the method name invites override without communicating the base-call requirement; (3) recommend a doc comment or template method pattern over a full refactor.

## 2026-05-14 — Factory Extraction Creates a Parallel Construction Path in Integration Tests

**Pattern**: When a private `BuildXxxFlow()` method is extracted into a standalone factory class, integration tests that previously tested inner sub-flows of that flow may be left behind. These tests need the raw `LogicProvider` instance (not the factory's `ISubFlow` output) to construct inner providers, so they cannot be trivially converted to use the factory. The result is a **parallel construction path**: the factory holds one source of truth for how `XxxLogicProvider` is constructed; the integration tests hold another. This is a silent co-evolution risk because both paths compile, both pass, and neither alerts when they diverge.

**Heuristic**: When auditing a factory extraction commit, search for `new XxxLogicProvider(` in the test directories (not just in production code). Every match that was not updated in the commit represents a parallel construction path. Flag the most impactful matches as High — especially when the factory's constructor has 10+ parameters (any divergence would require manual enumeration). Recommend either a targeted integration test for the factory itself via DI, or a shared helper that both production and tests delegate to for construction.

## 2026-05-14 — Work Item Plural Titles Signal Scope Incompleteness

**Pattern**: A work item titled "Create Flow Action Factories" (plural) where only one factory is delivered in the commit is a reliable signal that the commit is the first of several expected in the series. The remaining inline constructions that were not refactored are not bugs — they are the next expected deliverables. Flag the largest remaining candidates (by parameter count) as Low-priority scope gaps.

**Heuristic**: When a work item title uses a plural noun for the thing being created (e.g., "Factories," "Adapters," "Handlers"), count how many were created in the commit. If the count is 1, flag the remaining candidates as Low. Sort candidates by constructor parameter count to identify the highest-value targets for future commits.
