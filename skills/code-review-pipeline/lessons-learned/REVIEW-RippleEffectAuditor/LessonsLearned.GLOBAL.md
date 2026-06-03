# Lessons Learned: REVIEW-RippleEffectAuditor

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
> **Write ONLY:** abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
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

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future ripple-effect reviews. If the review ran smoothly using existing knowledge, skip the update.

## 2026-05-30 — New UI Column Without a Paired Seeder Helper: The Covered-Column Gap

**Pattern**: When a new column is added to a table component (e.g., a "Denied" column alongside an existing "Permissions" column), the existing E2E seeder helper typically creates entities without populating the new column's data source. Because the column always renders its empty-state fallback ("none"), the `data-testid` on the new column's primary content is never exercised by any existing or new test. The column is visible but untested.

**Heuristic**: When a diff adds a new table column with a new `data-testid` on its primary content (non-empty state), verify that at least one test seeds an entity with non-empty data for that column and asserts the content testid is visible. If the seeder helper has no way to populate the new column, the testid is dead from day one. Classify as High: the new UI surface was built but its only automated signal — the testid — is permanently untested.

---

## 2026-05-30 — INCOMPLETE Remarks With Unregistered Follow-Up Slugs: The Dead Cross-Reference

**Pattern**: A developer adds an `INCOMPLETE` remark or `// TODO:` in a source file that references a planned follow-up feature by name or slug (e.g., "see feature-name for full implementation"). The remark is accurate at the time of writing, but the referenced feature slug is never registered in the delivery tracking system (follow-up index, backlog, etc.). The code comment is correct, but its tracking reference is a dead link.

**Heuristic**: When an `INCOMPLETE`, `TODO`, or `DEFERRED` remark in a source file or interface comment references a named feature or slug, search the delivery index (follow-up index, backlog file, or equivalent) for that slug. If not found, flag as Medium — the implied work is undiscoverable via the standard delivery workflow. Also check companion architecture docs: the same INCOMPLETE note pattern frequently appears in architecture documentation alongside the code comment, and neither document cites a tracking entry.

---

## 2026-05-31 — Partial Guard Coverage on Interface Write Paths: The Symmetric Sibling Gap

**Pattern**: A security guard (e.g., ownership verification) is added to a subset of write methods on an interface — typically the most visible ones triggered by a known vulnerability. A sibling write method that creates the same category of security-sensitive association is left unguarded, because the fix was scoped to the methods explicitly named in the vulnerability report. The unguarded sibling is currently unreachable from the UI, so no test fails. The gap is only discoverable by enumerating ALL write paths on the interface and comparing them against the guarded set.

**Heuristic**: When a change adds an ownership/authorization guard to some methods on an interface, enumerate every other method on the same interface that writes or associates security-sensitive resources. For each unguarded write path, ask: "Could a caller supply a foreign resource ID here and produce a cross-resource binding?" If yes, flag as Medium even if no current UI surface exists — future callers will inherit the gap. The test for completeness: every method that accepts both a resource-identifier and an entity-identifier should verify the entity belongs to the resource.

---

## 2026-05-31 — Moq Mock Signature Change Is Silent: The Auto-Implement False Negative

**Pattern**: When an interface method signature changes (e.g., a parameter is added), any `Mock<IFoo>` that does not have an explicit `Setup()` for that method will silently auto-implement the new signature. The mock compiles, the test runs, and there is no indication that the mock is not set up for the changed method. If a test exercises a code path that calls the changed method, Moq returns the default value (null, 0, false, completed Task) rather than the test author's intended value — but only if the test path is reachable.

**Heuristic**: When reviewing a test file that uses a mocked interface whose signature changed, enumerate all methods on the interface that changed. For each changed method: (1) search the test file for explicit `Setup()` calls for that method — if found, verify they compile; (2) search for any code path in the tests that would trigger the changed method through the system under test. If a code path is reachable but no `Setup()` exists for the changed method, the mock will silently return a default, which may not be what the test author intended. Flag as Low (auto-default may be acceptable) or Medium (if a non-default return value is needed for the test to be meaningful).

---

## 2026-05-30 — "Known Limitations" Tables as Delivery Tracking: The Stale Limitation Entry Pattern

**Pattern**: Architecture and reference documents often contain a "Known Limitations and Deferred Work" table where each row names an unimplemented capability and cites the follow-up work item by its short ID (e.g., `110-feature-name`). When a developer delivers that follow-up feature, they update the delivery index and the feature's own status document, but they do not remove the corresponding row from the "Known Limitations" table in the architecture document. The result is a documentation state where the architecture doc explicitly says a capability is missing — using specific language like "always returns X — no Y path" — when in fact the capability was just delivered.

**Heuristic**: For any change that delivers a capability explicitly named in a "Known Limitations" or "Deferred Work" section of an architecture document, the corresponding row in that table is a High companion documentation finding. Check by searching the docs directory for the follow-up work item ID or the exact capability description. The row will often use the word "always" or "never" (e.g., "always emits X," "no Y path") — these absolute-language entries are the highest-confidence stale rows because they contradict the delivered feature most directly.

---

## 2026-05-28 — Process Documents Have Companion Reference Documents: Gate Catalogs and Similar Lists

**Pattern**: When a SKILL.md or process document maintains a numbered/lettered catalog (gates, phases, rules, checklist items), a companion human-readable reference document often mirrors that catalog. Commits that extend the catalog in the source SKILL.md frequently miss the companion document, because the change author writes to the authoritative source and forgets that a separate, human-facing mirror exists.

**Heuristic**: For any change to a numbered or lettered catalog in a SKILL.md or process file, search for all other documents in the workspace that contain the same gate/phase labels (e.g., `Gate A`, `Gate B`, `Phase 1`). Each document that lists a subset or full copy of the catalog is a companion that must be updated. Pay particular attention to newly-added overview documents that were introduced in the same PR batch — they may have been written before the final catalog additions and are easy to miss. The check is: does every companion document list ALL entries present in the authoritative source?

---

## 2026-05-28 — Bug Fix Without Companion Test: Status Notes vs. Test Files

**Pattern**: When a commit message or delivery status note explicitly names a bug that was fixed as a side-effect during feature delivery (e.g., "Also fixed X"), this is a reliable signal that the fix was not planned and therefore likely has no companion regression test. The status note is not the test — it is the absence indicator.

**Heuristic**: For every "Also fixed..." or "Fixed as part of..." item in a commit message, status doc, or delivery notes, locate the affected file and search for a corresponding test file. If the test file was not modified in the same commit (zero diff), flag as High. The commit message is honest about what was done; the test files confirm whether coverage followed. Do not accept "it was an obvious fix" as coverage — obvious fixes regress.

---
## 2026-05-31 — Deferred Scenario Notes as Forward Delivery Contracts: The Dropped Deferral Pattern

**Pattern**: A feature's status document or delivery notes record "Scenario X deferred to feature-Y (not yet delivered)." When feature-Y is subsequently delivered, the deferred scenario is at high risk of never being implemented. The developer delivering feature-Y did not write the deferral note and may not search prior feature status docs for follow-up obligations. The scenario silently disappears from the active delivery queue.

**Heuristic**: When reviewing commits that deliver a feature identified by a named slug, search all prior feature status docs in the same epic area for the pattern `"deferred to <slug>"`. Each match is a companion scenario that should have been implemented in the reviewed commits. If no test was added for the deferred scenario, flag as High — the scenario was formally acknowledged as an obligation of this feature and was not discharged.

---

## 2026-05-26 — Deleted Test Requires a Mirror Replacement

**Pattern**: When a behavior is intentionally changed (e.g., a filter is removed, a guard is dropped, a rule is inverted), the test that described the OLD behavior is correctly deleted. But the complement test — the one that verifies the NEW behavior is actually in effect — is the expected companion that is frequently not added. The deletion of the old test removes the only signal that a behavior existed, without producing a signal that the new behavior is covered.

**Heuristic**: When the diff shows a test file with net-negative line count (lines deleted), search for the test names that were removed. For each deleted test that described a behavioral rule, ask: "Did a mirror test verifying the inverted rule get added?" If not, flag as High. The gap is particularly serious when: (a) the deleted test was the only test for that behavior, (b) the change is a filter removal (inclusion now vs. exclusion before), or (c) the downstream path that the filter was guarding is now newly reachable.

## 2026-05-26 — Factory Method Without Dispatcher Update: Infrastructure Ahead of Wiring

**Pattern**: A factory interface gains a new method for a new case (e.g., a new enum value, a new subtype). The method is correctly implemented and tested at the unit level. But the dispatcher — the switch/router that maps the new enum value to the new factory call — is not updated. The new factory method is unreachable through the established routing path. An early-exit guard (often already present before the new method was added) masks the runtime crash that would otherwise be immediate.

**Heuristic**: For every new method added to a factory interface, search for all switch/case/lookup expressions that dispatch to other methods on that same factory interface. If a switch on the governing enum (or type discriminant) does not include an arm for the new method's use case, flag as High. The risk is not currently visible if a guard elsewhere short-circuits before the dispatcher — but that guard is precisely the signal: its presence says "this case is not yet routed." Check whether the guard and the dispatcher are a known co-evolution pair, and flag accordingly. The recommendation should name both: removing the guard AND adding the dispatcher arm at the same time.

---

## 2026-05-16 — Event Log / Status Enum Split: History Types Outgrow Entity Status

**Pattern**: When a domain layer has both a change-event log enum and an entity status enum, these two often diverge incrementally. Developers add new history events (e.g., `Queued`, `Approved`, `Claimed`) to the event log first — because that requires only a new enum value — and defer the corresponding entity status addition because it requires migration, service changes, and notification propagation. Over time the history log describes states the entity cannot represent.

**Heuristic**: When auditing a domain layer that has both a "what happened" enum (change type / event type) and a "current state" enum (status), always cross-reference them exhaustively. For every event-log value that implies a discrete entity state (e.g., `Queued` = the item is in a queue), check whether that state is representable by the status enum. Any gap is a Critical finding: the entity's current state is invisible to the query and notification layer.

## 2026-05-16 — Service Method Without Backing Entity Field: The Orphaned Setter

**Pattern**: When a service interface has a method like `SetXxxAsync(Guid id, bool value)` — a named toggle on an entity — the expected companion is a `bool Xxx` field on the entity class. If that field is absent, the method's implementation either cannot exist, writes to a wrong field, or relies on an undocumented convention. This is one of the cleanest Critical ripple signals because the contract literally cannot be honored without the field.

**Heuristic**: For every `SetXxxAsync` or `UpdateXxxAsync` single-field setter on a service interface, verify the target entity has a `Xxx` field. If not, flag as Critical. The method is an orphaned setter. Correlate with event-log types: if there is a matching history event (e.g., `XxxChanged`, `StatusTransitioned`), the orphaned setter pattern is confirmed.

## 2026-05-16 — Orphaned Enum: Types Declared Without Any Entity Reference

**Pattern**: In growing domain layers, enums are sometimes added speculatively or in anticipation of a feature, but the corresponding entity property and request record never follow. The enum compiles silently and appears complete. No tests break. The domain looks rich but the enum is never referenced.

**Heuristic**: For every enum in the domain layer, verify at least one entity field, request record field, or service parameter references it. If no reference exists outside the enum's own file, flag it as Critical (orphaned type — dead code with misleading documentation value). The specific check: `grep -r "EnumTypeName" --include="*.cs"` should return more than the declaring file itself.

## 2026-05-16 — Agent Output With No Storage Destination

**Pattern**: In agentic dispatch systems, the "complete dispatch" request type often includes a field for agent output (summary, log, generated content). If no entity field, document table, or history field is specified as the receiver of this output, the data is accepted at the API boundary and silently discarded. This is a High finding rather than Critical because it represents a data loss gap rather than incorrect behavior, but it is commonly overlooked because the field "works" (the API accepts it) without the storage layer ever materializing.

**Heuristic**: For any "complete" or "finish" request type in a dispatch system, trace the `Output`, `Result`, or `Log` field to a storage destination. If the destination is not in the domain contract (no entity field, no document attachment contract), flag as High with the recommendation to either add a history field or define a document-attachment contract.

---

## 2026-05-16 — Dual Authority Schema Pattern: Two Files Claiming the Same Relationship

**Pattern**: When two JSON schema files both claim to represent the same relationship (e.g., "which items are assigned to which owner"), one is often the real authority and the other is a historical or decorative copy. The decisive signal is which file the data-loading code actually reads. If the assignment check only reads one field of the "authority" file (e.g., username presence) without reading the relationship array stored in it, the array in that file is silently dead weight.

**Heuristic**: For any schema file whose name implies ownership of a relationship (e.g., "assignments", "mapping", "ownership"), search for all read sites and verify each field is actually read — not just the file. The file being loaded (deserialization succeeds) does NOT mean all its fields are consumed. Enumerate field-level read sites explicitly when two files both model the same domain relationship.

## 2026-05-16 — Component-Level State That Layout Shells Cache at Mount

**Pattern**: In Blazor (and similar SPA frameworks), the top-level layout shell component (`MainLayout` or equivalent) typically has a single `OnInitialized` lifecycle call. Any state it loads there — roles, usernames, feature flags — stays frozen for the session. Page-level components re-initialize on every navigation and can observe settings changes, but the shell cannot. This creates a split: page behavior is correct after a settings change; shell header/nav reflects old state.

**Heuristic**: When a "settings change takes effect after navigating away" contract exists, always check whether the layout shell re-reads those settings on navigation events (`LocationChanged`). If not, flag it as a stale-state gap: the pages will behave correctly but the header will be self-contradictory.

## 2026-05-16 — Write-Only Fields: Timestamp Stored But Never Rendered

**Pattern**: In event-log-style models (status records, review entries), it is common to add a "started at" timestamp alongside a "completed at" timestamp. If the "completed at" is rendered in the UI but the "started at" is only set and never displayed, the start timestamp becomes write-only — data collected and then silently unused. This is particularly easy to miss because the write-guard logic (set only once on first transition) is correctly implemented and passes code review.

**Heuristic**: For any timestamp field on a status/event model, verify both: (a) a write site exists AND (b) a read/render site exists. If only (a) is present, flag as a write-only field. Pair this with the question: "Is this data meant for a future duration/cycle-time feature?" If yes, document the intent on the field; if no, remove the write path.

## 2026-05-23 — Partial Enum Exclusion: When a Fix Excludes One Member of a Semantic Group

**Pattern**: A predicate that filters a collection often excludes enum values by semantic category (e.g., "non-actionable states," "terminal states," "in-flight states"). When a bug fix adds one exclusion to such a predicate, it often implies the rest of the group should also be excluded — but the fix touches only the value that caused the reported symptom. The remaining members of the group silently stay included.

**Heuristic**: For any predicate that receives a new `status != SomeValue` or `status != AnotherValue` exclusion, enumerate all enum values that share the same semantic category as the excluded value (e.g., all "pipeline-managed" statuses, all "in-flight" statuses). For each, ask: "Should this also be excluded under the same rule?" If yes and it is not in the predicate, flag as a medium companion-logic gap. The finding is stronger when the predicate already excludes multiple members of the group, making the gap asymmetric rather than merely potential.

## 2026-05-22 — DI Module Extraction Creates Stale "Where to Register" Documentation

**Pattern**: When inline service registrations are extracted from an entry-point file (e.g., `Program.cs`) into a dedicated module method (e.g., `AddXxxNoOpNotifiers()`), the code change is clean — but any developer documentation or coding-agent notes that say "register the companion in `Program.cs`" are silently wrong. The old placement instruction remains in the docs, and the new module method is the correct location.

**Heuristic**: When auditing a DI consolidation (registrations moved from entry-points into extension methods), always search for documentation, architecture notes, and operational skills that contain the old placement instruction. Specifically: grep for the old file name (e.g., `Program.cs`) and the interface names being consolidated. Any documentation that says "add X to `Program.cs`" is a High finding because future agents will follow it and produce an inconsistent DI graph that compiles but silently bypasses the new module.

## 2026-05-24 — NUnit SetUpFixture Is Namespace-Scoped When Placed Inside a Namespace

**Pattern**: `[SetUpFixture]` in NUnit is often described as "assembly-scoped" — meaning it runs once for all tests in the assembly. But if the class is placed inside a namespace (rather than at the root), NUnit scopes it to that namespace only. Planning documents frequently describe the assembly-wide behavior as the warning to avoid, while the implementation silently uses namespace scoping as the isolation mechanism. The result: docs say "use a filter or it will start Docker for all tests," but the namespace scoping already provides the isolation.

**Heuristic**: When reviewing test infrastructure for a `[SetUpFixture]`, check the namespace declaration of the setup class. If it is in a sub-namespace (e.g., `YourProject.Tests.Contract`), Docker or other heavy setup only runs for tests in that sub-namespace — unit tests in sibling namespaces are unaffected even without `--filter`. Flag any planning or README documentation that incorrectly describes this as assembly-wide as a Medium documentation accuracy gap.

## 2026-05-24 — Symmetric Commands With Asymmetric Test Pyramid Coverage

**Pattern**: In CLIs with symmetric command pairs (e.g., enable/disable, approve/revoke, block/unblock), each layer of the test pyramid tends to be written independently. When Phase N adds command surface tests for one side of a pair, and Phase N+1 adds contract tests for both sides, the Phase N gap in the "other side" becomes visible only when Phase N+1 arrives. The symptom: one side has tests at all pyramid layers; the other only has contract-level coverage.

**Heuristic**: When a new test phase adds a contract test for the "second side" of a symmetric pair, immediately check whether the companion Phase N test layer also covers that side. If the first side has a surface test and the second does not, flag as High (asymmetric coverage gap). The Phase N commit did not add it; the Phase N+1 commit surfaced the absence.

---

## 2026-06-02 — Two-Site Status-Word Fix: Index Correction Without Companion Per-Record Update

**Pattern**: When a status-word defect is corrected in an aggregated index or board document (e.g., "complete" corrected to "completed"), there is typically a parallel per-record document for the same entity that stores the same status value. The fix commit targets the index because that is where the error was noticed or surfaced. The per-record document — a separate file, same field — carries the original defect untouched. The commit message names the index, and no reviewer checks for the second write site.

**Heuristic**: When reviewing a commit that corrects a status word, completion flag, or canonical string in an index or aggregated view, always ask: "Does each entity also have a per-record document that stores this same value?" If yes, verify the correction was applied there too. A fix commit that corrects one write site in a symmetric pair is only half-done. The missing companion is a High finding: the index and the per-record file are now inconsistent, and any consumer that reads the per-record file directly will observe the pre-fix value.

---

## 2026-06-02 — Same-PR Late Gate Definition: Artifacts Without a Recorded Gate Evaluation

**Pattern**: A PR contains two logical changes: (a) a deliverable artifact — a prepared document, a packet, a spec — declared "ready" and promoted, and (b) later in the same commit sequence, a new gate or checklist item is added to the governing process skill. The artifact was prepared before the gate existed; it was never evaluated against the new gate; and no evaluation result is recorded. The absence of a recorded evaluation is ambiguous: it could mean "evaluated and N/A" or "gate did not exist when this was written." Neither is safe to assume for future consumers.

**Heuristic**: When reviewing a PR that introduces a new gate, mandatory check, or pre-entry requirement in a process document, search for documents in the same PR that were promoted to a "ready" or "complete" state in earlier commits. For each, verify whether a gate evaluation result is recorded. If not, flag as Medium and recommend adding an explicit evaluation annotation — even "Gate X — N/A: [reason]" — so future agents reading the artifact do not need to re-derive the determination. The annotation closes ambiguity cheaply; re-deriving it costs a full audit pass.

## 2026-05-22 — Default Environment Change Creates Cascading Skill and Doc Inversions

**Pattern**: When a CLI tool's default environment changes (e.g., from `Development` to `Production`), the code change itself is small (one string). But every operational skill, reference document, and "how to invoke" table that states "bare invocation = dev database" is now inverted. The old docs describe the new behavior as requiring explicit env setup, and vice versa. This creates a high-risk documentation inversion rather than a gap — the old text is not merely absent, it actively tells agents the wrong thing.

**Heuristic**: For any change to a CLI's default environment or default configuration: (1) grep all skills, SKILL.md files, and developer docs for phrases like "the default is", "(default)", and any table column that uses the bare invocation example. (2) Verify each one describes the NEW default, not the old one. The most dangerous form is a decision table where an agent chooses between safe and unsafe environments — if the table is inverted, the agent will confidently pick the wrong one. Flag these as High, not Medium.

## 2026-05-08 — ViewModel-Mirror Anti-Pattern

**Pattern**: When a ViewModel is a full property-for-property mirror of a domain entity, there are typically TWO separate "copy entity fields" paths: a factory/constructor for initial load and an `UpdateXxx()` method for in-place refresh. These are parallel implementations of the same projection logic. **Both must be found and enumerated** as ripple targets when the entity gains a new field. Searching only for the factory and missing the update method is a common false-completeness error.

---

## 2026-05-08 — Flat-Parameter Interface as Blast-Radius Amplifier

**Pattern**: When a service interface method enumerates an entity's mutable fields as individual parameters (e.g., `Add(string name, string description, Enum category, Enum priority, bool isActive, int score, Enum? assignment)`), every entity field addition requires: interface signature change + implementation change + every caller change. The interface acts as a blast-radius multiplier, not an abstraction. **Always check** whether callers use named arguments; positional-only calls are an additional silent-failure risk when parameters are reordered or inserted.

**Heuristic**: Count the parameters on service interface methods. More than 4–5 parameters that map directly to entity properties is a signal to recommend a request/command object.

**Pattern**: When a `UpdateCard()` or `SyncFrom()` method is called by multiple callers (factory-refresh, status-advance, save, approve, message-receive), the `OnPropertyChanged` notifications for computed properties depending on the updated fields are often added only to the first caller that needed them. Subsequent callers silently omit the notification. The root fix is to push all `OnPropertyChanged` calls for computed dependencies into `UpdateCard()` itself rather than leaving them as caller responsibilities.

**Heuristic**: When auditing an entity-to-ViewModel sync method that is called from more than two places, enumerate ALL callers and verify each caller either (a) does not depend on the computed property or (b) fires the notification. If any caller misses a notification that another caller correctly fires, the fix belongs in the sync method, not in the callers.

## 2026-05-18 — Message Payload API vs. Handler Consumption Mismatch

**Pattern**: When a strongly-typed message payload carries N fields but the handler only reads 1, the remaining N-1 fields form a misleading API contract. The fields were added for a reason (scoping, optimization, future use), but if the handler never reads them, that intent is silently abandoned. This is particularly common in MVVM messenger patterns where payloads are defined in one project and handlers in another — the structural coupling is low, so the mismatch is easy to miss.

**Heuristic**: For every message type defined in a ViewModel project, enumerate all its payload fields and verify at least one handler reads each field. A field that is set by the sender and never read by any receiver is a dead payload field. Cross-check: if the field was clearly added for scoping (e.g., `ScopeId` or `OwnerId`), verify the handler actually uses it to filter.

## 2026-05-08 — Hardcoded Enum Enumeration in UI Components

**Pattern**: When UI components declare `private static readonly SomeEnum[] ValidValues = [A, B, C]` or equivalent dictionaries keyed by an enum, they silently become stale when a new enum value is added. These arrays never fail to compile — they simply omit the new value from the rendered output. This is one of the highest-risk silent failure patterns for enum extension.

**Heuristic**: When analyzing ripple effects of adding an enum value, search for static arrays and dictionaries whose keys are the enum type — these are the most likely silent-omission sites, more dangerous than switch statements (which at least can be made exhaustive with warnings).

## 2026-05-12 — "Non-Actionable Status" Filter Pattern

**Pattern**: When a codebase adds a "terminal-adjacent" or "non-actionable" status (e.g., `Blocked`, `OnHold`, `Skipped`), recommendation/filter views that already exclude `Completed` status typically need to be updated to exclude the new status too. These views almost always use `Status != Completed` as the only exclusion filter. The new status satisfies `!= Completed`, so it silently appears as actionable in the output.

**Heuristic**: When auditing a new status value, search for views that filter by `!= Completed` or `== Active` — these are the most likely sites where the new status needs to be added to the exclusion list. Pay particular attention to "priority recommendation" or "what to do next" views where unactionable items degrade trust.

## 2026-05-12 — Edit Draft / Form Model as a Silent Data-Loss Site

**Pattern**: When an entity has fields that exist in both the persistence (request records) and the UI (a form model / draft object), any field added to the entity must be added to the form model or the save path will silently overwrite it with the field's default. This is the "edit draft" companion pattern. It differs from the ViewModel-Mirror pattern because: the ViewModel omission makes the field *invisible*, while the draft omission makes the field *destructively cleared on save*.

**Heuristic**: When analyzing ripple effects of an entity field addition, always check: (1) request record ✅, (2) service implementation ✅, (3) ViewModel ⚠️, and (4) edit draft / form model ⚠️. Steps 3 and 4 are the most commonly missed and have different impact profiles — step 3 is visibility loss, step 4 is data loss.

## 2026-05-20 — Two-Way Status Transition: Backward Path Often Misses All Companion Calls

**Pattern**: When a method implements a two-directional status transition (forward: A → B, backward: B → A), companion calls (history record, UI notification, domain event publish) are typically added to the forward path when the feature is first built. The backward path (revert or de-queue) is often added later and developers focus on the state machine correctness — forgetting that the forward path's companions also need backward counterparts.

**Heuristic**: For any conditional branch that says `if eligible → transition to X` with a sibling `else if not-eligible + currently-X → revert to Y`, treat the revert branch as a symmetric companion check. Enumerate every companion call in the forward branch and verify each has a counterpart in the revert branch. History record and UI notification are the most commonly missed. A forward transition that notifies but a backward that doesn't is a stale-UI source.

## 2026-05-20 — Enable/Disable Flag With No Dispatch Enforcement

**Pattern**: In systems where entities (agents, workers, machines) have a boolean `IsEnabled` or `IsActive` flag that drives a derived status enum (Online/Offline/Disabled), it is common to display the derived status prominently in the UI. However, the dispatch or work-claim path often validates only the credential (token, key) and not the enabled flag — because the token validation was implemented first and the disable feature was added later without auditing all claim sites.

**Heuristic**: For any `enabled/disabled` flag on a worker entity, enumerate all paths where that entity is a participant in work claiming or execution. Verify each path reads the flag before allowing work to proceed. The critical check is the claim/assignment boundary — not the heartbeat or authentication boundary, which are typically checked earlier and separately.

## 2026-05-19 — Global DI Registration Is Not an Implicit Migration Claim

**Pattern**: When a new cross-cutting service (e.g., a notification service, a logging sink, an error reporter) is introduced and registered in the application's root DI container, developers often intend it to replace an existing per-component pattern (e.g., inline message fields). The global registration makes the service *available* to all components, but it does not enforce that all components *use* it. The result: one or two pages are migrated; the rest retain the old pattern. The compiler does not flag the gap.

**Heuristic**: When a service is registered globally and its stated purpose is to *replace* an existing pattern, treat it as a symmetric-path trigger. Search for all sites where the old pattern is still used. For each unmigrated site, evaluate whether the omission is intentional (scope decision, documented exception) or a silent gap. Rate intentional deferrals as Medium (symmetric path gap) to capture the future migration debt; do not escalate to High unless the inconsistency causes correctness issues.

**Signal to look for**: The old pattern (e.g., `string? ErrorMessage` observable property + inline alert div) coexists with the new one on peer pages that share the same structural form (wizard → async operation → feedback). The pages are structurally identical except for the feedback mechanism.

## 2026-05-12 — Sub-Flow Test Architecture Insulates Lower-Level Interface Mocks

**Pattern**: In codebases where tests mock a "logic provider" interface that contains both step actions and sub-flows, tests at the outer flow level mock the outer interface (e.g., `IOuterFlowLogicProvider`) and return `MockSubFlow(...)` for any inner sub-flows. This means the inner flow's own logic provider interface (e.g., `IInnerFlowLogicProvider`) is never directly mocked in those outer tests. Consequently, adding a member to the inner interface creates no new mock gap in outer tests — only the direct mock of the inner interface (the inner flow's own test file) needs updating.

**Heuristic**: When an interface change affects an interface that is consumed exclusively inside a named sub-flow class, check: (1) does the sub-flow's own test file mock the interface directly? (2) do any outer tests mock it directly? The answers narrow the mock gap to only the sub-flow's test file, not every test that transitively uses the flow.

## 2026-05-13 — Reverted Code Is Still Valid Review Scope

**Pattern**: When reviewing commits by hash, check `git log` to see if the change was subsequently reverted before beginning codebase-state searches. If it was reverted, searching HEAD will return no matches for new classes, methods, or file changes — leading to false "no call sites" conclusions. The correct approach is to do all ripple searches directly against the commit content (`git show <hash>:path/to/file`) rather than the live workspace.

**Heuristic**: At the start of any hash-specific review, run `git log --oneline -20` and check for a revert commit targeting the PR under review. If found, note it in the report preamble, source all companion searches from the commit objects rather than HEAD, and avoid grep_search (which scans the working tree) for finding call sites of code that has been reverted.

## 2026-05-13 — Optional DI Parameter as Zero-Blast-Radius Companion Pattern

**Pattern**: When a constructor adds an optional parameter with `= null` as its last argument (especially with a `?` nullable type), the blast radius is exactly zero for DI-managed consumers — the DI container simply omits the argument when the type is not registered. Direct instantiation sites would be affected, but framework-layer classes with internal sealed access modifiers typically have no direct `new ClassName(...)` call sites. In these cases, the ripple analysis for an optional-parameter constructor change correctly resolves to a single finding: confirm no direct instantiation exists.

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

**Pattern**: In domain layers where a state machine has a "canonical path" protected by validation (eligibility gates, guards, authorization), there is often a parallel path that arrives at the same terminal state but bypasses some or all of those protections. The parallel path is typically a CLI service, a background job, or a raw DB call introduced as a "simpler" implementation. Because both paths compile and produce the correct final state (entity arrives in the terminal status), the bypass is invisible at first.

**Heuristic**: For every state transition that is protected by multiple companions (eligibility check → history write → notification), search for ALL writers of that state, not just the canonical one. Explicitly ask: "Are there other classes that write `Status = X` directly?" and "Are there any `ExecuteUpdateAsync` or `ExecuteSqlAsync` calls that set this field?" These are the most reliable indicators of an uncontrolled parallel path.

## 2026-05-19 — "Stored But Never Consumed" Config Fields Should Be Flagged Explicitly

**Pattern**: Config/options entities (`*Config`, `*Options`, `*Settings`) often accumulate fields that are persisted by a write path but never read by any consumer. These are particularly easy to miss because the UI renders them as configurable and the persistence layer stores them successfully — the only failure mode is that the value has no effect. The mismatch between "user configured X" and "X has no effect" erodes trust.

**Heuristic**: For every field on a `*Config` or `*Options` entity, use grep to verify at least one READ site exists outside the persistence layer. If only write sites exist (the `UpsertAsync` method), flag as Low/Medium dead activation.

## 2026-05-19 — Dual-Maintenance of the Same Concept Across Entity + Config Is Always Suspicious

**Pattern**: When both a domain entity and a config entity have a field of the same name and type (e.g., `MaxRetries` on both a task entity and a category config entity), one of four situations holds: (1) the config is an initial value copied to the entity on create, (2) they are independent values with different semantics, (3) only one is used and the other is dead, or (4) the author intended synchronization that was never implemented. Situation (4) is the most common and produces a subtle, difficult-to-debug discrepancy.

**Heuristic**: Find all fields that appear on both a domain entity and a config entity with the same name. For each pair: (a) find the write site for the config field, (b) trace whether that write path updates the entity field, (c) find the read site and determine which source it reads. If the read site only reads the entity field and the config field is never propagated, flag as Medium (silent no-op configuration).

---

## 2026-05-20 — Label/Badge Helper Pairs Always Diverge at the Same Boundary

**Pattern**: When a codebase has two parallel switch methods — one mapping an enum value to a display string ("label") and one mapping it to a CSS class ("badge color") — they diverge whenever a new enum value is added. The developer adds the explicit label first (it's directly visible in the UI) and forgets the badge color (which only affects visual styling). The default arm silently absorbs the new value with no compile warning.

**Heuristic**: Whenever a `XxxLabel` or `XxxName` helper method is in scope, check for a paired `XxxBadge`, `XxxClass`, or `XxxColor` helper. If one has N explicit cases and the other has N-1, the most recently added label value is missing its badge. This pattern is especially common in history/event-log views where event types grow incrementally over time.

---

## 2026-05-20 — "Not Completed" Filter Is Not "Not Actionable-By-Human" Filter

**Pattern**: In agentic/dispatch-enabled systems, "actionable by the user" filters are often written as `status != Completed`. This is correct when only human-driven statuses exist, but becomes incorrect when machine-exclusive statuses are added (e.g., `QueuedForMachineProcessing`, `ClaimedByAgent`). The new machine status satisfies `!= Completed`, making tasks actively being processed by a machine appear in "next human action" recommendation views.

**Heuristic**: In any codebase with a "recommended next task" or "what to do now" view, check whether the filter explicitly excludes all in-flight machine/dispatch statuses — not just `Completed`. `status != Completed` is a two-value assumption that breaks silently when the status enum gains machine-exclusive values.

---

## 2026-05-29 — Sign-In Without Sign-Out: Login/Logout Symmetric Path Gap

**Pattern**: Authentication features are delivered incrementally. The sign-in flow (endpoint + page + session establishment) is always the first deliverable because it gates access to everything else. Logout is frequently omitted from the initial delivery because the feature "works" without it — existing tests pass, the app is accessible, and no acceptance criterion explicitly names logout. The navigation drawer or app shell also lacks a logout link because it was built before the auth feature landed. Both the server-side endpoint and the client-side UI element are independently absent.

**Heuristic**: When reviewing any auth feature that introduces sign-in, always search for a symmetric sign-out. Check three independent locations: (1) the endpoint file — is there a `SignOutAsync`/`Logout` handler? (2) the navigation component (sidebar, drawer, header) — is there a logout link? (3) the layout shell — does it display the authenticated user's identity? Any audit that finds sign-in without all three is missing at least one half of the session lifecycle. Rate the absent endpoint as High; the absent nav link as Medium (functional gap) or combine both as a single High finding under "SymmetricPath."

---

## 2026-05-29 — Test Auth Fixture Not Updated When Real Auth Claim Structure Changes

**Pattern**: In codebases where a test-only endpoint or fixture creates a synthetic authenticated session (e.g., `/test/sign-in`), this fixture is written once at the time auth infrastructure is established and then forgotten. When a subsequent feature introduces the real authentication implementation and defines what claims a session contains (e.g., `NameIdentifier = Guid`, `Email = string`), the test fixture is not updated because all existing tests still pass — the tests don't yet read the new claims. The structural divergence is invisible until downstream features read claims from the session.

**Heuristic**: When auditing an auth feature that defines the canonical session claim structure for the first time, locate all test-only sign-in endpoints, test auth helpers, and mock authentication handlers in the codebase. For each, compare the claims they issue against the canonical structure now defined by the real auth implementation. Any divergence — missing claims, wrong types (string vs. Guid), different claim type constants — is a High finding. The impact is not current test failures but future test failures that appear unrelated to auth when a downstream feature reads the identity.

---

## 2026-05-30 — Parallel Property-Name Lists Written From Template, Not From Code

**Pattern**: An architecture document contains parallel bullet lists for a set of sibling types (e.g., three nested classes, each with its own property roster). The author templates the second and third lists from the first, then updates only the entries the two types share — leaving the type-specific entries as carryover from the template source. The counts remain correct (the author knows there are N items), but the names for type-specific entries are wrong. The document appears complete: correct number of bullets for each type, correct entries for shared properties.

**Why it persists**: The author writes the doc from memory or a spec, not from the code. Shared properties are easy to spot; type-specific properties require reading each type's source independently, which is slower. If the doc is written in one pass without consulting the actual source for each sibling type, the contamination goes undetected.

**Heuristic**: When an architecture document contains parallel bullet lists for sibling types (class A has N members, class B has N members, each listed separately), verify each list against the actual source type — do **not** assume a list is correct because it has the right count. The highest risk entries are type-specific ones (properties that exist on one type but not its siblings), because these are most likely to be substituted with carryover from the template. Read each sibling's source file and cross-check every name. Flag wrong names as High: the doc actively misleads engineers toward non-existent identifiers.

---

## 2026-05-30 — Count-in-Prose and Exhaustive-Table Both Carry the Pre-Addition Count

**Pattern**: A compile-time class has both a count mentioned in prose ("it must contain only one of the **N** fixed constants") and an exhaustive table enumerating all members. A new constant is added. The author updates the table (the failing test forces attention there) but forgets to update the count integer in the adjacent prose sentence. Result: the table is accurate, the prose sentence describes a world with one fewer constant.

**Why it persists**: The count sentence and the table are often in visually distinct sections. When the author searches the doc for where to add the new row, they find the table and stop. The count sentence reads naturally ("eight") and does not trigger a change-needed signal because it does not visually resemble a list.

**Heuristic**: For any change that adds a member to an exhaustive class or enum, after updating the table or list in the companion doc, search the surrounding text (within a few hundred characters) for integer literals (`eight`, `nine`, `7`, `12`). If a sentence contains an exact count of members and a new member was added, that count is stale. This is a two-step verification: (1) is there a table or list? (2) is there also a count in nearby prose? Both must be updated atomically.
