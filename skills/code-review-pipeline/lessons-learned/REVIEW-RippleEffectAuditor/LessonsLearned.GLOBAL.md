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

## 2026-05-16 — Event Log / Status Enum Split: History Types Outgrow Entity Status

**Pattern**: When a domain layer has both a `TaskHistoryChangeType`-style event log enum and a `TaskItemStatus`-style entity status enum, these two often diverge incrementally. Developers add new history events (e.g., `QueuedForDispatch`, `ApprovedForDispatch`, `ClaimedForDispatch`) to the event log first — because that requires only a new enum value — and defer the corresponding `TaskItemStatus` addition because it requires migration, service changes, and notification propagation. Over time the history log describes states the entity cannot represent.

**Heuristic**: When auditing a domain layer that has both a "what happened" enum (change type / event type) and a "current state" enum (status), always cross-reference them exhaustively. For every event-log value that implies a discrete entity state (e.g., `QueuedForDispatch` = the task is in a queue), check whether that state is representable by the status enum. Any gap is a Critical finding: the entity's current state is invisible to the query and notification layer.

## 2026-05-16 — Service Method Without Backing Entity Field: The Orphaned Setter

**Pattern**: When a service interface has a method like `SetXxxAsync(Guid id, bool value)` — a named toggle on an entity — the expected companion is a `bool Xxx` field on the entity class. If that field is absent, the method's implementation either cannot exist, writes to a wrong field, or relies on an undocumented convention. This is one of the cleanest Critical ripple signals because the contract literally cannot be honored without the field.

**Heuristic**: For every `SetXxxAsync` or `UpdateXxxAsync` single-field setter on a service interface, verify the target entity has a `Xxx` field. If not, flag as Critical. The method is an orphaned setter. Correlate with event-log types: if there is a matching history event (e.g., `XxxChanged`, `ApprovedForDispatch`), the orphaned setter pattern is confirmed.

## 2026-05-16 — Orphaned Enum: Types Declared Without Any Entity Reference

**Pattern**: In growing domain layers, enums are sometimes added speculatively or in anticipation of a feature, but the corresponding entity property and request record never follow. The enum compiles silently and appears complete. No tests break. The domain looks rich but the enum is never referenced.

**Heuristic**: For every enum in the domain layer, verify at least one entity field, request record field, or service parameter references it. If no reference exists outside the enum's own file, flag it as Critical (orphaned type — dead code with misleading documentation value). The specific check: `grep -r "EnumTypeName" --include="*.cs"` should return more than the declaring file itself.

## 2026-05-16 — Agent Output With No Storage Destination

**Pattern**: In agentic dispatch systems, the "complete dispatch" request type often includes a field for agent output (summary, log, generated content). If no entity field, document table, or history field is specified as the receiver of this output, the data is accepted at the API boundary and silently discarded. This is a High finding rather than Critical because it represents a data loss gap rather than incorrect behavior, but it is commonly overlooked because the field "works" (the API accepts it) without the storage layer ever materializing.

**Heuristic**: For any "complete" or "finish" request type in a dispatch system, trace the `Output`, `Result`, or `Log` field to a storage destination. If the destination is not in the domain contract (no entity field, no document attachment contract), flag as High with the recommendation to either add a history field or define a document-attachment contract.

---

## 2026-05-16 — Dual Authority Schema Pattern: Two Files Claiming the Same Relationship

**Pattern**: When two JSON schema files both claim to represent the same relationship (e.g., "which marks are assigned to which tester"), one is often the real authority and the other is a historical or decorative copy. The decisive signal is which file the data-loading code actually reads. If the assignment check only reads one field of the "authority" file (e.g., username presence) without reading the relationship array stored in it, the array in that file is silently dead weight.

**Heuristic**: For any schema file whose name implies ownership of a relationship (e.g., "assignments", "mapping", "ownership"), search for all read sites and verify each field is actually read — not just the file. The file being loaded (deserialization succeeds) does NOT mean all its fields are consumed. Enumerate field-level read sites explicitly when two files both model the same domain relationship.

## 2026-05-16 — Component-Level State That Layout Shells Cache at Mount

**Pattern**: In Blazor (and similar SPA frameworks), the top-level layout shell component (`AppShell`, `MainLayout`, etc.) typically has a single `OnInitialized` lifecycle call. Any state it loads there — roles, usernames, feature flags — stays frozen for the session. Page-level components re-initialize on every navigation and can observe settings changes, but the shell cannot. This creates a split: page behavior is correct after a settings change; shell header/nav reflects old state.

**Heuristic**: When a "settings change takes effect after navigating away" contract exists, always check whether the layout shell re-reads those settings on navigation events (`LocationChanged`). If not, flag it as a stale-state gap: the pages will behave correctly but the header will be self-contradictory.

## 2026-05-16 — Write-Only Fields: Timestamp Stored But Never Rendered

**Pattern**: In event-log-style models (status records, review entries), it is common to add a "started at" timestamp alongside a "completed at" timestamp. If the "completed at" is rendered in the UI but the "started at" is only set and never displayed, the start timestamp becomes write-only — data collected and then silently unused. This is particularly easy to miss because the write-guard logic (set only once on first transition) is correctly implemented and passes code review.

**Heuristic**: For any timestamp field on a status/event model, verify both: (a) a write site exists AND (b) a read/render site exists. If only (a) is present, flag as a write-only field. Pair this with the question: "Is this data meant for a future duration/cycle-time feature?" If yes, document the intent on the field; if no, remove the write path.

## 2026-05-08 — ViewModel-Mirror Anti-Pattern

**Pattern**: When a ViewModel is a full property-for-property mirror of a domain entity, there are typically TWO separate "copy entity fields" paths: a factory/constructor for initial load and an `UpdateXxx()` method for in-place refresh. These are parallel implementations of the same projection logic. **Both must be found and enumerated** as ripple targets when the entity gains a new field. Searching only for the factory and missing the update method is a common false-completeness error.

**Heuristic**: For any entity-to-ViewModel class pair, always search for both (a) a `FromX()` or `CreateFromX()` factory and (b) an `UpdateX()` or `SyncFrom()` method. If both exist without shared code, flag them as co-evolution risk.

## 2026-05-08 — Flat-Parameter Interface as Blast-Radius Amplifier

**Pattern**: When a service interface method enumerates an entity's mutable fields as individual parameters (e.g., `Add(string title, string desc, Enum horizon, Enum effort, bool flag, int score, Enum? override)`), every entity field addition requires: interface signature change + implementation change + every caller change. The interface acts as a blast-radius multiplier, not an abstraction. **Always check** whether callers use named arguments; positional-only calls are an additional silent-failure risk when parameters are reordered or inserted.

**Heuristic**: Count the parameters on service interface methods. More than 4–5 parameters that map directly to entity properties is a signal to recommend a request/command object.

## 2026-05-18 — UpdateCard() + Computed Property Notification: Four-Caller Asymmetry

**Pattern**: When a `UpdateCard()` or `SyncFrom()` method is called by multiple callers (factory-refresh, status-advance, save, approve, message-receive), the `OnPropertyChanged` notifications for computed properties depending on the updated fields are often added only to the first caller that needed them. Subsequent callers silently omit the notification. The root fix is to push all `OnPropertyChanged` calls for computed dependencies into `UpdateCard()` itself rather than leaving them as caller responsibilities.

**Heuristic**: When auditing an entity-to-ViewModel sync method that is called from more than two places, enumerate ALL callers and verify each caller either (a) does not depend on the computed property or (b) fires the notification. If any caller misses a notification that another caller correctly fires, the fix belongs in the sync method, not in the callers.

## 2026-05-18 — Message Payload API vs. Handler Consumption Mismatch

**Pattern**: When a strongly-typed message payload carries N fields but the handler only reads 1, the remaining N-1 fields form a misleading API contract. The fields were added for a reason (scoping, optimization, future use), but if the handler never reads them, that intent is silently abandoned. This is particularly common in MVVM messenger patterns where payloads are defined in one project and handlers in another — the structural coupling is low, so the mismatch is easy to miss.

**Heuristic**: For every message type defined in a ViewModel project, enumerate all its payload fields and verify at least one handler reads each field. A field that is set by the sender and never read by any receiver is a dead payload field. Cross-check: if the field was clearly added for scoping (e.g., `BoardId`), verify the handler actually uses it to filter.

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

## 2026-05-19 — Parallel Write Paths to Protected State Are the Highest-Risk Ripple Pattern

**Pattern**: In domain layers where a state machine has a "canonical path" protected by validation (eligibility gates, guards, authorization), there is often a parallel path that arrives at the same terminal state but bypasses some or all of those protections. The parallel path is typically a CLI service, a background job, or a raw DB call introduced as a "simpler" implementation. Because both paths compile and produce the correct final state (task ends up in `QueuedForDispatch`), the bypass is invisible at first.

**Heuristic**: For every state transition that is protected by multiple companions (eligibility check → history write → notification), search for ALL writers of that state, not just the canonical one. Explicitly ask: "Are there other classes that write `Status = X` directly?" and "Are there any `ExecuteUpdateAsync` or `ExecuteSqlAsync` calls that set this field?" These are the most reliable indicators of an uncontrolled parallel path.

## 2026-05-19 — "Stored But Never Consumed" Config Fields Should Be Flagged Explicitly

**Pattern**: Config/options entities (`*Config`, `*Options`, `*Settings`) often accumulate fields that are persisted by a write path but never read by any consumer. These are particularly easy to miss because the UI renders them as configurable and the persistence layer stores them successfully — the only failure mode is that the value has no effect. The mismatch between "user configured X" and "X has no effect" erodes trust.

**Heuristic**: For every field on a `*Config` or `*Options` entity, use grep to verify at least one READ site exists outside the persistence layer. If only write sites exist (the `UpsertAsync` method), flag as Low/Medium dead activation.

## 2026-05-19 — Dual-Maintenance of the Same Concept Across Entity + Config Is Always Suspicious

**Pattern**: When both a domain entity and a config entity have a field of the same name and type (e.g., `MaxRetries` on both `TaskItem` and `CategoryDispatchConfig`), one of four situations holds: (1) the config is an initial value copied to the entity on create, (2) they are independent values with different semantics, (3) only one is used and the other is dead, or (4) the author intended synchronization that was never implemented. Situation (4) is the most common and produces a subtle, difficult-to-debug discrepancy.

**Heuristic**: Find all fields that appear on both a domain entity and a config entity with the same name. For each pair: (a) find the write site for the config field, (b) trace whether that write path updates the entity field, (c) find the read site and determine which source it reads. If the read site only reads the entity field and the config field is never propagated, flag as Medium (silent no-op configuration).
