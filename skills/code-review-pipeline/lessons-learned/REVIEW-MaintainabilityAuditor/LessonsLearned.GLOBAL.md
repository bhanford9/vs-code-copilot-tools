# Lessons Learned: REVIEW-MaintainabilityAuditor

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

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future maintainability reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## Bare `Task.Delay` for absence-of-X E2E assertions is Medium when no named constant or rationale comment exists

**Date**: 2026-06-02
**Category**: Process/Model

When an E2E test asserts that a navigation or state change does *not* occur by issuing a hard sleep (`Task.Delay(N)`) and then checking that the URL/state is unchanged, rate the finding as **Medium** (not Low) when all three of the following are true: (1) the wait duration is a bare integer literal with no named constant, (2) there is no inline comment explaining why the specific duration was chosen, and (3) the pattern appears in two or more test methods in the same class. The severity is Medium because E2E test suites treat visible patterns as conventions — the next author writing a similar "no redirect" assertion will copy the pattern including the magic number and the rationale vacuum. A named constant with a comment explaining the assertion strategy is the minimum viable fix; migrating to a declarative wait API is the recommended eventual fix but should not gate the Medium finding. Do NOT downgrade to Low just because the sleep duration appears to be "short" — the severity comes from the missing rationale and the pattern's propagation risk, not the duration itself.

---

## Parallel ordered-array + keyed-dictionary over same domain objects is High when a bug confirms the sync failure

**Date**: 2026-05-20
**Category**: Process/Model

When a class exposes two static data structures that represent the same ordered domain concept — e.g., an `ItemType[]` array for iteration order plus a `Dictionary<ItemType, ...>` for attribute lookup — and a known production bug exists whose direct cause is that one structure was updated without the other, rate the DRY violation as **High** (not Medium). The bug IS the DRY failure manifesting in production. The finding should include: (a) the crash mode (e.g., `KeyNotFoundException` when the array contains a key absent from the dictionary), (b) that any partial fix is dangerous (updating one but not both can crash), and (c) the recommended refactor (a single ordered array of tuples from which the dictionary is derived). Do NOT downgrade to Medium because the bug is already documented in a correctness audit — the maintainability severity is elevated BY the confirmed correctness failure.

---

## Documentation "Test-Verified" claims require type and property name spot-checks against source

**Date**: 2026-05-23
**Category**: Process/Model

When a documentation section is labelled as "test-verified" or claims to reflect what the test suite asserts, always spot-check at least one type name and one property name against the actual source files before accepting the doc as accurate. A type name used in documentation can silently diverge from the implementation type name — especially when the doc was written near (but not after) the tests. Without the spot-check, a naming discrepancy is a High-severity finding that would be silently skipped. **Rule:** For any "test-verified" doc section, grep the source for the primary domain type referenced. A name mismatch is High severity, not Low.

---

## `file`-scoped C# helpers in test files are a reuse-hazard flag

**Date**: 2026-05-23
**Category**: Process/Model

When a test file defines a `file`-scoped helper class that implements or extends a framework type (time provider, logger, random source, etc.), flag it for extraction to a shared test helpers folder — even if no other test in the project currently needs it. The `file` modifier optimizes for isolation at the cost of reuse. As the test project grows, each time-dependent test will either duplicate the helper or be blocked from using it. **Rule:** `file sealed class Fake*` that wraps a standard framework extension type = Low finding recommending extraction to `internal` in a shared location.

---

## Multi-class single-file test patterns against a project-wide one-class-per-file convention are Medium

**Date**: 2026-05-23
**Category**: Process/Model

When every test project in a codebase uses one `[TestFixture]` class per file, a single test file that packs multiple fixture classes is a Medium structural finding — regardless of whether each individual fixture is clean. The severity comes not from any single file being wrong, but from the pattern divergence: the file is the outlier and will grow linearly with the class count. **Check:** Compare the largest test file's class count against the project-wide norm. If it's the sole multi-class outlier, it's Medium.

---

## Document item-count claims should be verified against source arrays

**Date**: 2026-05-23
**Category**: Process/Model

When documentation states a count of items (keyword lists, enum values, configuration keys, feature flags), verify by counting the actual source structure. Off-by-one errors in count claims are systematically under-caught because readers accept the documented number at face value. When the documentation section cites test coverage as authority, a wrong count implies the tests may also be incomplete. **Rule:** For any doc line that says "(N items)" or "the following 8 rules", count the actual source array. If the count differs, it's at minimum a Low finding; if tests depend on the count, it may be Medium.

---

## Free-text descriptor fields on append-only entities require a documented naming convention before the second callsite

**Date**: 2026-05-31
**Category**: Process/Model

When an append-only audit or event entity has a free-form string descriptor field (e.g., `Outcome`, `Reason`, `Description`) and that field has no enumeration, no constants file, and documentation examples that do not match the actual values used at existing callsites, rate the finding as **Medium** (not Low) if two or more additional callsites are planned within the near-term roadmap. Rationale: the first callsite establishes the de facto convention by example; when the second and third callsites are implemented, their authors will either (a) grep the existing callsite and copy its style, or (b) read the documentation examples (which are wrong) and invent a different style. The longer the convention divergence persists before being documented or centralized, the more expensive the cleanup. **Rule:** For any new audit entity with a free-text descriptor, if the XML doc examples for that field do not match the actual string values written at existing callsites, flag the doc-reality mismatch AND recommend either (a) a constants class or (b) updated remarks with the actual naming convention, before the next planned callsite is implemented. The finding should explicitly name how many additional callsites are planned so the reviewer can judge urgency.

---

## When a unifying private helper is added, scan the same file for pre-existing inline occurrences and convert them

**Date**: 2026-05-31
**Category**: Process/Model

When a private helper is introduced to unify a repeated pattern, pre-existing inline occurrences not refactored to use it are the primary drift risk — the helper will receive future changes while the old inline copy will not. **Rule:** When unconverted inline occurrences remain, rate the DRY gap **Medium** (not Low). Note how many write paths in the same class use the helper vs. how many still use the inline form.

---

## An enum value whose documented semantics require a missing context field is Medium, not Low

**Date**: 2026-05-30
**Category**: Process/Model

When an enum value's XML documentation describes behavior that is physically unimplementable because the required context or field does not yet exist in the calling model, rate the finding as **Medium** even if the code itself is safe (i.e., the unimplemented value falls through to a safe default). The documentation IS the defect in two specific ways: (1) a caller who sets this value gets undocumented behavior silently (the doc says X, the runtime does Y); (2) a future implementor reading the doc will assume the feature already works and may skip the code changes required to actually implement it. This is distinct from a simple documentation error — the misleading doc actively obscures a coordination dependency between a future context change and a future service change. **Rule:** For any enum used as a configuration API (users select values that control runtime behavior), when a value's documented behavior requires a field or state that the current model does not carry, the finding is Medium with a mandatory "update to say 'reserved/not yet implemented'" recommendation. The safe-default behavior does NOT reduce severity — it only confirms no security gap; the documentation trap is the finding.

---

## A DRY violation that replicates an already-known bug upgrades from Low to Medium

**Date**: 2026-05-30
**Category**: Process/Model

When a new code block is a copy of an existing block that is already known to contain a documented bug (e.g., a correctness audit note or a comment in the same PR), the DRY violation should be rated **Medium**, not Low, even if the duplicated code is otherwise correct and the duplication is "just following the pattern." Rationale: (1) the known bug now lives in two places, requiring two coordinated fixes instead of one; (2) a partial fix that patches one copy but not the other introduces silent behavioral divergence; (3) the fix surface for both the bug AND the DRY issue expands with every additional copy. **Rule:** Before rating a copy-paste DRY finding, grep the existing (pre-copy) source block for any nearby TODO, bug note, or correctness-audit finding. If one exists, escalate the DRY severity by one level and include both the duplication and the bug-doubling in the finding description.

---

## Framework-required public property with private naming convention is a false-positive trap, not a naming violation

**Date**: 2026-05-29
**Category**: Process/Model

Some UI component frameworks require component parameters to have public setters so the framework's binding mechanism can inject values at runtime (e.g., query-parameter binding, cascading parameter binding). In these frameworks, a developer may name the public property using a private-field convention (underscore prefix) because the property feels internal to the component — the public modifier is a framework-imposed detail, not a design intent. When reviewing component code, before flagging a public property as a naming convention violation, check whether a framework-binding attribute on the property forces the public accessor. If it does, the correct finding is the asymmetry with the private-field naming convention (Medium), not the access level itself. Contrast with other components in the same file or project that achieve the same binding pattern without the naming mismatch — that contrast is the finding. **Rule:** For any `public` property on a component that is named like a private field, check for a binding attribute before concluding it is a naming error.

---

## Tripled copy-paste blocks require an active divergence scan as a separate step from the DRY finding

**Date**: 2026-05-29
**Category**: Process/Model

When the same ~10-20-line logic block is copy-pasted three or more times with only one or two string literals changing per copy, assume divergence has already occurred and perform an explicit diff inspection of each copy before writing the DRY finding. Look for: lines present in some copies but absent in others (usually a fallback or additional logic added to one copy after the initial paste), subtle expression differences, and comment drift. Report the DRY finding AND the specific divergence as a compound observation — the divergence is the strongest evidence that the duplication is not "harmless boilerplate" but a live source of behavioral inconsistency. **Rule:** For N identical blocks, compare N−1 pairs of consecutive blocks line by line. Any difference is a separate finding within the DRY entry.

---

## Sole `virtual` member in a namespace is a test-infrastructure-bleed diagnostic

**Date**: 2026-05-28
**Category**: Process/Model

When scanning a namespace where every type is `sealed` or non-`virtual` except for exactly one property on a plain data model class, treat that lone `virtual` as a test-infrastructure smell and investigate before rating it Low. The pattern arises when a test subclasses a domain model to inject failure behavior (e.g., throwing from a property to simulate an engine error), and the `virtual` modifier is the only structural concession made to that test. Severity is **Medium**, not Low, because:
- The `virtual` declaration opens the class to unintended extension in production contexts
- It creates asymmetry within the type that future maintainers must explain
- Each new property added to the class will face a "should this also be virtual?" question, and the precedent pulls toward yes
- **Resolution rule:** check whether the `virtual` exists solely for test subclassing; if so, it's Medium with a recommendation to use mocking or a factory instead

---

## Inline literal strings in an algorithm + test assertions = DRY violation rated by test coverage of that string

**Date**: 2026-05-28
**Category**: Process/Model

When an algorithm class produces string output (e.g., trace labels, status messages, resolution step names) as inline literals, and tests assert on those exact strings as inline literals in a separate file, the severity of the DRY violation scales with how many of the strings have no test coverage:
- If every string has a test asserting it exactly: **Low** — the test will fail on any unintended rename
- If some strings have no test coverage: **Medium** — a misspelling in production produces no test failure AND no compile error
- If the string count is projected to grow (e.g., placeholder steps exist that will add more strings): escalate one level, because the un-enforced pattern will compound
- **Recommendation:** extract to `const string` or a static constants class so production code and test assertions share the same reference. The escalation-on-growth rule is particularly important for state machine / pipeline / precedence-engine patterns where each step adds a new label.

---

## Aggregate-boolean service interface hiding per-item granularity is High when the consumer renders items conditionally

**Date**: 2026-05-28
**Category**: Process/Model

When a service interface exposes only an aggregate boolean (`IsAvailable`, `IsEnabled`, `HasAny`) but the backing options/config class has per-item availability flags, and the consumer renders a list of items *without* checking per-item availability, rate the interface-coverage gap as **High**. The severity comes from two compounding factors: (1) dead/broken items are shown to users in any partial configuration, and (2) the fix requires extending the interface — not just patching the template — which touches multiple call sites. **Rule:** For any service that wraps a collection-like config (N providers, N features, N strategies), check whether the interface exposes enough surface area for consumers to render conditionally. An interface that answers "are any available?" but not "which ones are available?" is High when conditional rendering is the consumer's job.

---

## Multi-view descriptor record redundancy (lists + dictionary of same items) is Medium unless constructors enforce sync

**Date**: 2026-05-26
**Category**: Process/Model

When a parameter record carries multiple structural views of the same domain objects — e.g., two `IReadOnlyList<T>` (by role) and one `IReadOnlyDictionary<K, T>` (by key) where the two lists are a partition of the dictionary — rate the DRY violation as **Medium** (not Low). The existing "parallel array + dictionary" lesson covers static class fields; this lesson covers *parameter types*. Key differences:
- Each new caller must populate all three structures in sync; there is no central enforcement point.
- The dictionary and lists often serve different downstream consumers (one for iteration, one for keyed lookup), so the redundancy isn't immediately obvious as removable.
- Callers tend to grow independently over time — each new section type or variant must get the sync right.

Recommended severity escalation: upgrade to **High** if any of the following apply:
- The record is mutable (callers can modify one view without updating the other)
- The redundancy is across a class hierarchy (base and subclass each hold one view)
- A concrete callsite already fails to sync them

Recommended finding: note the specific sync constraint, show that the two lists are a partition of the dictionary, and recommend either deriving one structure from the other or adding a factory method that enforces the invariant at construction time.

---

## Entry: Toggle-transitional step-list duplication is intentional, not a DRY violation

**Date**: 2026-04-22
**Category**: Process/Model

When reviewing toggle-gated `if/else` blocks in flow methods where both branches share many steps but differ in the middle, resist upgrading the severity beyond Low/Medium. Full step-list duplication inside a toggle branch is often *deliberately simpler* than extracting shared parts — because deleting the old branch at toggle promotion becomes a clean "delete the if block" operation. Over-DRY'd toggle code (e.g., shared helpers) is harder to cleanly remove and leaves orphaned abstractions. Flag it as Low with a "deferred to toggle cleanup" note.

---

## Entry: Default interface member factories are identity-unstable — flag as Medium

**Date**: 2026-04-22
**Category**: Process/Model

C# default interface members implemented as `=> new Foo()` factories create a new instance on every property access. This is identity-unstable: callers reading the same property twice get different references. In flow frameworks that cache steps by name, this is currently correctness-safe — but it violates the standard property contract and creates fragile coupling to the framework's caching. When you encounter DIM properties that `new` objects, flag this as Medium and recommend moving instantiation to the concrete class as initialized auto-properties (`{ get; } = new Foo()`). This removes the factory semantics and makes the contract explicit.

---

## Prior Audit Chain Informs Severity Scoring

**Category: Process/Model**
**Date**: 2026-04-22

The correctness audit's "known gaps" (e.g., a missing `Math.Max` floor) directly elevate the maintainability severity of a DRY violation in the same area: if the same logic exists in two places and a known fix must be applied there, the DRY violation becomes High (not Medium) because it doubles the chance the fix is applied in only one location. Always read both prior audits (requirements + correctness) before assigning severity scores — they provide evidence that changes what counts as a maintainability risk.

---

## Commutative Method Argument Swaps Are a KISS Finding, Not a Correctness Finding

**Category: Process/Model**
**Date**: 2026-04-22

When a method is confirmed commutative (e.g., `Compute(a, b) == Compute(b, a)`) and the code uses an inline ternary to swap arguments by side, flag it as a **Medium KISS violation** (unnecessary complexity) rather than a correctness risk. The finding should recommend simplifying the call site, not re-examining the method's commutativity.

---

## Toggle-conditional method name mismatch is a reliable Medium finding

**Date**: 2026-04-29
**Category**: Process/Model

When a method is renamed to include "IgnoringX" (e.g., `HasOutputIgnoringSomeChecks`), but the implementation only ignores X when a toggle is ON — and includes X when the toggle is OFF — the method name is actively misleading for the default (toggle-off) production state. Rate this as **Medium**: callers see only the method name and cannot know there is conditional behavior inside. The fix is either to name the method to reflect its conditional semantics, or to add an inline comment. This pattern occurs reliably on toggle-integration commits that backfit toggle awareness into pre-existing utility methods.

---

## Factory-consolidation constructors have high param counts by design — not an SRP violation

**Date**: 2026-05-14
**Category**: Process/Model

When a refactoring commit introduces a new factory class specifically to consolidate scattered DI pass-throughs (the "threading elimination" pattern), the resulting factory constructor will have a high parameter count (often 15–25+ params). This is the expected and correct outcome — the point of the refactoring is to gather all related dependencies into one place. Do NOT flag a high parameter count as an SRP violation on a factory whose sole responsibility is constructing a specific family of objects. The correct test is whether all the dependencies are cohesive (do they all serve the same construction purpose?), not whether the count is high. A 21-param factory is fine if all 21 are cohesive construction dependencies. An 8-param factory with mixed cross-domain services is an SRP concern.

---

## Apply existing lessons before assigning severity — re-read before rating

**Date**: 2026-04-29
**Category**: Process/Model

Step-list duplication within toggle branches (where both branches share surrounding steps but differ in the middle) is already documented as **Low** in this file. Re-read the full LessonsLearned file before assigning severity to each finding. A finding that matches a documented pattern should receive the documented severity level, not an independently reasoned one. Missing an existing lesson and assigning a higher severity is a false positive against the codebase's deliberate intent.

---

## Flow-framework step/class names that double as execution-log labels should not be flagged for length

**Date**: 2026-05-12
**Category**: Process/Model

In systems where `FlowDecision` or similar base classes accept a name string that appears verbatim in execution logs (e.g., `base(nameof(CheckIfShouldSkipSomePhaseForSomeCondition))`), long class names are diagnostic features, not style liabilities. A 56-character class name that produces a self-documenting log entry is preferable to a shortened name that requires source lookup during debugging. Do NOT flag these as a readability issue. Check whether the class name is used as a trace label before assigning any severity.

---

## Misleading "Use the service/API" comment on a direct-DB helper is a reliable Medium finding

**Date**: 2026-05-23
**Category**: Process/Model

In test code, when a private helper method carries a comment like "Use the API/service to advance state" but the implementation directly accesses the data store — bypassing the service layer entirely — the mismatch between the comment and the implementation is a reliable **Medium** finding (not Low). The comment misleads future test authors about which abstraction layer is being used and, more importantly, which side effects (e.g., audit log/history entries) occur. The fix is a comment correction that names the bypassed boundary and explains why it is bypassed. Do NOT require a code refactoring if the bypass is intentional (e.g., to suppress history events for unrelated tests); the comment is the defect, not the bypass itself.

---

## Inline polling expressions in E2E tests that duplicate a base-class method are Medium DRY, not High

**Date**: 2026-05-23
**Category**: Process/Model

When an E2E test base class encapsulates a polling/wait expression (e.g., waiting for a DOM attribute to reach a specific value) inside a navigation helper, and a single test class inlines the same expression because its navigation is triggered by a button click (not a direct URL load), rate this as **Medium** DRY — not High. The duplication is narrow (one call site), clearly understandable, and exists because the base method does not expose a standalone "wait only" variant. The recommended fix is a one-liner extracted helper on the base class. Do not escalate to High unless the expression is duplicated in three or more places, or unless the expression contains a magic string/timeout that is likely to change.

---

## Guard-added Commits Leave Throw-Path Comments Stale — Check "Unchanged" Methods

**Category: Process/Model**
**Date**: 2026-04-23

When a commit adds a guard (e.g., `CanReach`) to prevent a throw from being reached, the guarded method (e.g., `DistanceToClear`) is typically left "unchanged." But unchanged methods may carry comments like "impossible condition" that are now demonstrably false — the guard was added *because* the condition was observed. Always check throw-path comments in guarded methods for staleness, even when the guarded method is listed as unmodified. This is a reliable source of Medium maintainability findings on guard-adding commits.

---

## Blazor PropertyChanged Subscription Must Be Verified at the Root Page Level

**Date**: 2026-05-12
**Category**: Process/Model

In Blazor Server MVVM patterns, child components that subscribe to `PropertyChanged` (via a base class like `ViewModelComponentBase`) re-render themselves, but do NOT trigger re-rendering of their parent or sibling components. This means:

- Any component rendered as a direct child of a PAGE (not of a `ViewModelComponentBase` subcomponent) that reads from a ViewModel must ALSO subscribe to `PropertyChanged`, OR the parent page must subscribe and call `StateHasChanged`.
- Concrete finding type: "Component X is a direct child of PAGE Y; PAGE Y does not subscribe to PropertyChanged; Component X reads ViewModel property Z; property Z changes but Component X never re-renders." This is a **High** reactivity bug.
- Always check whether the root page component (`@page "/..."`) inherits `ViewModelComponentBase` or manually subscribes. If not, audit all non-ViewModelComponentBase children rendered at the page level for stale data risk.

---

## Full-Codebase Reviews Should Treat Missing ViewModel Interfaces as High — Not Convention Nitpick

**Date**: 2026-05-12
**Category**: Process/Model

When a codebase has an explicit convention that all injectable classes must have interfaces, discovering a ViewModel that lacks an interface is not a Low/style finding. Rate it **High** because:
1. The ViewModel is likely injected as a concrete type everywhere it's used (testability cost).
2. The DI registration leaks the concrete type into the composition root.
3. The test surface is permanently narrowed without compiler enforcement to detect this.

If the explicit convention exists in a written instructions file, cite it in the finding.

---

## Static factory + mutator duplication is a reliable High finding in MVVM ViewModels

**Date**: 2026-05-18
**Category**: Process/Model

In CommunityToolkit.Mvvm codebases (and MVVM in general), ViewModel classes often have two separate field-mapping operations over the same source entity:
- A static `FromEntity(entity)` factory used at initial load time
- An `UpdateFromEntity(entity)` (or inline update block) used after edits/refreshes

When both exist as separate, non-sharing code blocks, they are a **High** DRY violation — not just Medium — because:
1. The mappings will silently drift as the entity grows
2. Drift produces stale UI state (edits appear to not save) — a user-visible bug with no compile-time signal
3. The fix is cheap: move all mapping into the ViewModel as `UpdateFrom(entity)`, call it from the factory

The correct pattern is `static FromEntity` delegating to `UpdateFrom` on a fresh instance. When you see both a factory and a separate update-by-field block over the same entity type, rate it **High**.

---

## `IsLoading` not in try/finally is a reliable High finding in any async load ViewModel

**Date**: 2026-05-18
**Category**: Process/Model

Any async ViewModel method that sets a loading flag at the start (`IsLoading = true`) and resets it inline at the end (not in `finally`) is a **High** finding — not Medium. The failure mode:
- Service throws on a transient error
- `IsLoading` stays `true` permanently for the ViewModel's lifetime
- User sees infinite spinner with no recovery path

This finding recurs reliably in async load commands. The fix is always `try/finally { IsLoading = false; }`. Rate it High because the user-facing impact is a fully broken screen on any service fault.

---

## Scan All Services in a Persistence Layer for TimeProvider Adoption Consistency

**Date**: 2026-05-19
**Category**: Process/Model

When reviewing a .NET service layer (e.g., EF Core data services), do a cross-cutting scan: does every service that writes timestamps inject and use `TimeProvider`, or are some using `DateTime.UtcNow` directly? Partial adoption is a reliable **High** finding because:
1. Services without `TimeProvider` cannot be unit-tested for timestamp-sensitive behavior.
2. Invite token expiry, `CompletedAt` correctness, and audit trail accuracy depend on a controlled clock in tests.
3. The pattern gap is invisible to consumers — nothing in the type system signals "this service ignores the injected clock."

Look especially at services that write fields like `CreatedAt`, `UpdatedAt`, or expiry timestamps. If they take a `TimeProvider` constructor parameter in other services but not in these ones, it is a High gap, not Low style.

---

## Dual-Constructor Pattern for DI vs. Non-DI Context Is a Medium Coupling Finding

**Date**: 2026-05-19
**Category**: Process/Model

When a class has two public constructors — one minimal (e.g., only the DB context, for CLI or design-time use) and one full (e.g., DB context + config + logger, for web DI) — this is a **Medium** maintainability finding. The consequence:
1. Optional fields must be nullable throughout the class, adding null-check noise to every method that uses them.
2. A developer adding a new dependency must decide which constructor to extend, and may add it to only one.
3. Every new log statement must remember the `?.` form for the CLI path.

The correct fix is a single constructor with nullable optional parameters (C# supports default `= null`). This preserves CLI usability while making the optional nature explicit at declaration rather than scattered across 20+ null-checks in the body.

---

## Dead ViewModel Classes Indicate an Abandoned SRP Split — Flag as High

**Date**: 2026-05-08
**Category**: Process/Model

When a codebase has a ViewModel class that was clearly intended for a specific page/form, but the page instead injects the broader host ViewModel and binds to state added there, flag this as **High SRP** — not merely a dead code Low. The dead ViewModel is evidence that a separation was planned but abandoned, and the host ViewModel has been inflated with page-specific state as a result. The maintainability risk is the **pattern it establishes**: every future page will continue to add state to the host ViewModel rather than creating a proper scoped ViewModel. The fix is completing the original separation intent, not simply deleting the dead class.

---

## Repeated `PropertyChanged` + `Dispose` Boilerplate Across Sibling Components Is a Base Class Signal

**Date**: 2026-05-08
**Category**: Process/Model

When three or more sibling components in a component library all implement identical event-subscription / `OnInitialized` / `Dispose` patterns, this is a reliable **Medium** finding — not Low — because the subscription unsubscription has a safety-critical element (missing `Dispose` leaks event handler references). The correct recommendation is a base class that makes the pattern impossible to forget, not just a comment noting the duplication. The base class also serves as a contract that future components can inherit, preventing recurrence.

---

## Dead Component Parameters with String Types — Remove Rather Than Fix the Type

**Date**: 2026-05-08
**Category**: Process/Model

When a component has a parameter of type `string` that receives enum-like values but is never read in the template or code-behind, resist recommending "fix the type to the enum type." The parameter is dead code and should be removed. Recommending a type fix implies the parameter has a future use. If it does not, YAGNI says remove it. Flag as **Medium YAGNI**, recommend deletion, and note that if the functionality is ever needed it should be added with the correct type at that time.

---

## `IfSome` Callback Null Checks Can Be Unreachable When Preceded by a None-Setting Guard

**Category: Process/Model**
**Date**: 2026-05-06

In LanguageExt codebases that use the `InitializeX(param) / Option.IfSome(...)` pattern, the `IfSome` callback may contain null checks on `param` that are provably unreachable. The reason: the `InitializeX(null)` path typically sets the Option to `None`, preventing `IfSome` from ever firing — so any `if (param is not null)` guard inside the `IfSome` callback is dead code. When reviewing a mutation method that calls an initializer then `IfSome`, check whether the initializer's None-setting path makes inner null checks unreachable. This is a reliable Low-severity KISS finding on commits that add derived properties to mutation methods.

---

## Paired Complementary Tests Parameterized on Side Predictably Produce Setup Duplication

**Date**: 2026-04-23
**Category**: Process/Model

When a toggle-addition commit adds two complementary test methods — one asserting the "data present" path and one the "data absent" path — and both are parameterized on `[Values] bool isLeftSide`, their setup code is structurally forced to be near-identical: same domain object factory call, same context configuration, differing only in the `designInputs`. This is a reliable Medium-finding pattern on toggle-feature commits. Look for this specifically: two new tests in the same fixture, both `[Values] bool isLeftSide`, same toggle setup, diverging only at the thing under test. Extract-to-helper is the correct recommendation; not `[SetUp]` (only two of N tests in the fixture use it).

---

## Optional Parameter with Null Default on Toggle-Gated Extension Methods Is a Medium Maintainability Risk

**Date**: 2026-04-24
**Category**: Process/Model

When a toggle-gated feature is threaded into an extension method via `IFeatureFlags? toggles = null` (or an equivalent nullable feature-flag parameter), the null default creates a silent failure mode: any call site that omits the parameter gets toggle-off behavior regardless of the system-level toggle state — no compiler error, no runtime warning. Current callers may be correct, but the risk compounds over the toggle's lifetime in the codebase.

Rate this as **Medium** and recommend one of:
1. A documentation comment on the parameter explaining that production paths must pass it explicitly.
2. Removing the null default once all callers are confirmed wired (makes the contract compiler-enforced).

---

## In Single-Commit Mode, Current HEAD May Have Already Resolved Commit-Era Findings

**Date**: 2026-05-07
**Category**: Process/Model

When reviewing a specific commit (`single-commit` mode) in a repo that has continued to evolve, the current HEAD may differ from the commit under review. Expression-body property factories, stored field names, or parameter lists visible in the `git diff` may no longer appear in the current file — because a subsequent commit cleaned them up.

Concretely: if a grep search for a symbol added by the commit under review returns no matches in the current file, do NOT assume a false negative or search error. First confirm whether the symbol appears in the diff output. If it does appear in the diff but not in the current file, the most likely explanation is a subsequent commit removed or renamed it.

Handling:
- Report the finding against the commit's diff (the commit DID introduce it)
- Add a parenthetical note: "already resolved in current HEAD"
- Do not escalate severity based on a problem the team has already fixed

This avoids both false negatives (missing real issues) and false alarms (reporting issues already resolved).

---

## Mapster-Removal Commits May Add "Spec-Completeness" Methods That Are Dead Code

**Date**: 2026-05-06
**Category**: Process/Model

When a commit removes Mapster and replaces it with explicit switch expressions, the author may also add new switch-based extension methods for enum types that were never in the file before — to "complete the picture" of the mapping class. These additions are likely dead code: the enum type already has mapping extensions elsewhere (e.g., in its own file in a sub-namespace), and no production callers in the target layer actually use the new version.

Identify these by:
1. Searching the enclosing layer for production call sites of the new method
2. Checking whether a method with the same name and parameter type already exists in a sibling or sub-namespace

When this pattern is found:
- The new methods are a YAGNI violation
- If the existing methods are in the same namespace hierarchy, the duplicate creates a **potential extension method ambiguity** for any caller that imports both namespaces
- When implementations diverge (switch throws vs Mapster maps silently), the conflict is a behavioral correctness risk on future enum additions

Rate as **High** and recommend removing the dead methods. Do NOT let "it's tested" shield them from removal — a test for a dead code path is not the same as a production caller.

---

## Graceful-Skip Replaced by Throw — Always Look for a Removal Comment

**Date**: 2026-05-06
**Category**: Process/Model

When a refactor converts a `switch { _ => null }` + `if (x is null) continue;` graceful-skip pattern to a method call that throws on unknown enum values, the old code was communicating something: "unknown cases should be silently ignored here." The new code is asserting: "unknown cases should never reach here." These are different behavioral contracts, both of which can be correct in context. But the intent of the change is rarely documented.

When you see this pattern in a diff:
- Rate it as **Medium** (readability/documentation gap)
- Recommend an inline comment explaining WHY the throw is acceptable where the skip used to be
- The recommendation is NOT to restore the null check — only to document the deliberate change in contract

Do not conflate this with dependency injection wiring (DI is fine). The concern is specifically about optional parameters on non-injected call sites (extension methods, static helpers) where callers can silently omit the toggle. The toggle's promotion cleanup is also the right time to remove the optional parameter entirely.

---

## Named Constant Value Leaking Into Method Name Is a Low Readability Finding

**Date**: 2026-04-28
**Category**: Process/Model

When a class defines a named constant to avoid a magic number (e.g., `private const double _offsetDistance = 3d`) but then names a method using the raw value (e.g., `GetBaseValuePlus3`), flag this as **Low readability**. The constant exists precisely to avoid value-specific names; encoding the value in the method name re-introduces the maintenance risk — if the constant value changes, the method name becomes stale documentation. The reliable recommendation: remove the value from the method name and describe the operation instead (e.g., `GetBaseValuePlusOffset`).

---

## Pre-Existing Property Factories Rate As Low, Not Medium

**Date**: 2026-04-28
**Category**: Process/Model

The GLOBAL entry "Default interface member factories are identity-unstable — flag as Medium" applies when the property-factory pattern is **introduced** by the PR under review. When the diff only changes constructor arguments passed to an existing `=> new Foo(...)` property getter, the pattern is pre-existing and should be rated **Low** with a note that it is a codebase-wide convention. Do not escalate to Medium just because the changed line appears in the diff — check whether the factory structure itself is new or inherited.

---

## Env-Context Classes: Private Static Methods With >4 Parameters Often Have Redundant Params

**Date**: 2026-04-28
**Category**: Process/Model

When a class's public API takes a single "env" or "context" object and all its public methods accept that same object, any `private static` method in the same class with 4+ parameters is a reliable source of a Medium finding. Check whether the parameters were extracted from `env` in the calling method and immediately forwarded. If so, the private method could extract them itself, reducing the signature to only the parameters that are NOT derivable from `env` (typically just behavioral flags). This is distinct from the pre-existing parameters on the public interface — it only applies to private implementation helpers.

---

## SignalR Event-Name Magic Strings Spanning Multiple Assemblies Are a Reliable Medium Finding

**Date**: 2026-05-20
**Category**: Process/Model

When a SignalR event name string (e.g., the first argument to `SendAsync`/`.On`) appears as a hardcoded literal in both a server hub/publisher AND a client handler registered in a separate project, rate it as **Medium** — not Low. The key risk is that a rename or typo produces a runtime-silent failure: the server broadcasts and the client never receives the event; no compiler error, no exception, no log. The failure is invisible until an integration test covers the full send-to-receive path.

Reliable finding criteria:
- The string appears in `SendAsync("EventName", ...)` in one file
- The same string appears in `.On<T>("EventName", ...)` or an equivalent registration in a different project
- No shared constant, interface, or typed hub contract binds them

Recommendation: define the event name as a `public const string` in the shared core/contracts assembly. Alternatively, use a typed hub interface where the event name is encoded in the method signature — making mismatches a compile error.

Do not rate this Low just because "they can always grep for it." The risk is proportional to how many assemblies and teams share the string, and how often the event contract is likely to evolve.

---

## Multi-Interface Single-Concrete Registration in DI Is a Self-Documenting-Code Finding, Not a Design Smell

**Date**: 2026-05-20
**Category**: Process/Model

When a DI container registers a single concrete service as five registrations — one concrete, four interface facades each resolving the concrete via `sp.GetRequiredService<ConcreteType>()` — this is the correct pattern for sharing a single scoped instance across multiple interfaces. It is NOT an SRP violation or a code smell.

However, the pattern is non-obvious to contributors unfamiliar with it, and the wrong variation (`AddScoped<IFoo, ConcreteType>()` instead of the factory lambda) creates a second instance per scope, silently breaking the shared-instance guarantee.

The correct finding: **Medium self-documenting-code gap** — recommend a single inline comment explaining the pattern and what NOT to do. Do not recommend refactoring the pattern itself. Do not flag the five-registration block as a design issue. The block is intentional and correct; the gap is just the missing explanation.

---

## Graphics renderer line count driven by domain element breadth is not an SRP violation

**Date**: 2026-05-13
**Category**: Process/Model

When a renderer class is large (e.g., 800-1000 lines) because the domain model has many element types (N element types = N draw methods + N capture/snapshot methods), do NOT flag this as an SRP violation. The class has one responsibility — rendering the domain model as a visual output — and its length scales directly with domain breadth. The tell: each method handles a different named domain element, not a different concern. Rate the file length as a non-finding (or at most Low with "could be split if it grows further"). The signal that it IS an SRP violation: multiple unrelated orchestration concerns mixed into the same class (e.g., network I/O + rendering + state management).

---

## Pre-increment/rollback counter patterns are a Low KISS finding

**Date**: 2026-05-13
**Category**: Process/Model

When a counter is incremented at the top of a method so its value can be embedded in a filename/label before a conditional write, then decremented if the write is suppressed — rate this as a **Low KISS finding**. The pattern is correct but non-obvious; the rollback is easy to drop in a future refactor. The recommended fix is either a comment explaining "pre-increment so the label uses the post-write number; roll back if suppressed" or a restructure that increments only on success. Do not escalate to Medium unless the counter appears in more than one code path.

---

## Test harness code that configures the DI container is excused from using production abstractions — but must be documented

**Date**: 2026-05-13
**Category**: Process/Model

Test harness setup code that configures the DI container (e.g., registers services, reads config values to conditionally wire dependencies) often cannot use the production service abstractions it would normally use — because those services are part of the container being built. Raw config reads, string comparisons against toggle values, and direct `IServiceCollection` manipulation are all legitimate in this bootstrap context. Rate any resulting code quality gap as **Medium** (for missing documentation or case-sensitivity issues), not High (for bypassing the abstraction). The fix is always: add a comment explaining why the bootstrap constraint prohibits the production-code pattern.

---

## Role-based + status-based UIs have a predictable string vocabulary scatter pattern — always check for constants

**Date**: 2026-05-16
**Category**: Process/Model

In apps that combine role-based routing with status-machine-style display logic (badge colors, sort orders, filter dropdowns), the domain vocabulary (role names and status names) tends to scatter across a specific set of file types in a predictable pattern:
1. Service/initialization — role inference result strings
2. Routing — role-to-route mapping switches
3. Layout/shell — role display label switches, nav label computed properties
4. Page guards — role string comparisons in `OnInitializedAsync`
5. Data model — status string literals in `ComputedStatus` / sort lambdas
6. Page code-behind — badge class switch expressions, filter comparisons
7. Sort expressions — status strings as sort keys with ordinal magic numbers

When a codebase exhibits this structure and has no constants class for these strings, rate the missing-constants finding as **High** (not Medium). The vocabulary is spread across 7 structural categories that all require independent maintenance for any vocabulary change. Additionally: if the correctness audit identifies any status/role vocabulary mismatch with an external system, the absence of constants directly amplifies the severity of that correctness finding — there is no single place to correct it.

The fix pattern: one `static class` per vocabulary domain (e.g., `UserRole`, `ReviewStatus`), placed in the Core/shared layer so all projects can reference it. Razor templates can reference these directly; no adapter layer needed.

---

## Service Interface Methods Referencing Non-Existent Entity Properties — Reliable Medium Finding

**Date**: 2026-05-16
**Category**: Process/Model

In domain-centric codebases where service interfaces are the primary API surface, a `SetXxxAsync(Guid id, T value)` method on a service interface implicitly promises that the entity has a readable `Xxx` property. When the entity does not have the corresponding property, callers can set the state but cannot read it back from the entity — breaking the write/read symmetry that consumers expect.

When reviewing domain contracts:
1. For each `SetXxxAsync` or mutation method on a service interface, verify the corresponding property exists on the entity type it returns
2. If the property is absent, rate it as **Medium** — this is an Interface-Entity Gap that creates invisible state consumers cannot introspect
3. Do NOT assume the property is stored as an EF shadow property unless you can confirm it — shadow properties are invisible to the domain by design, which makes the gap worse, not better
4. Also check change-type / event log enum values — they record state transitions that must correspond to settable/readable fields

A related pattern: enums that exist in Core but have no corresponding property on any entity. These are often orphaned after a field was removed from the entity without cleaning up the enum. Rate as Low (YAGNI/dead code) and recommend verifying before deletion.

---

## Computed Properties Calling `DateTime.UtcNow` — Rate Higher When Project Has No Tests Yet

**Date**: 2026-05-16
**Category**: Process/Model

When a computed property (e.g., `Machine.Status`) calls `DateTime.UtcNow` directly, and the codebase already establishes a `TimeProvider` injection pattern elsewhere (e.g., in a sibling service class), this inconsistency is normally a **Medium** — two ways to do the same thing, testability concern.

Elevate to **High** when: the review explicitly notes the project has no unit tests yet. The reason for the elevation is that the inconsistency becomes a structural testability blocker the moment the first test suite is introduced — the test author cannot mock time for the entity without modifying the production code. In a codebase with existing tests, the prior pattern likely already works around it. In a test-less codebase, fixing it now is cheap; fixing it after a test suite exists (and has workarounds baked in) is expensive.

---

## CLI composition root factories are intentional, not DI violations — flag drift risk only

**Date**: 2026-05-18
**Category**: Process/Model

CLI tools without a DI host commonly use local factory functions (CreateXxx()) to manually construct services. This is an intentional, appropriate pattern — not an SRP violation or DI anti-pattern. Do NOT flag a CreateXxx() factory as "wrong." Instead, evaluate it for *drift risk*: if the constructed service has 5+ positional constructor arguments and is likely to gain new dependencies, rate the factory as **High** (drift-safety concern) and recommend a comment documenting what must be kept in sync. The severity is earned by invisible-failure mode (no compiler error when the constructor gains a param), not by the pattern's existence.

---

## Snapshot-based dirty detection (JSON serialization) is a valid MVVM pattern for nested ViewModels — flag the performance assumption, not the approach

**Date**: 2026-05-19
**Category**: Process/Model

When a ViewModel with nested child objects (entries containing sub-collections) uses JSON serialization to snapshot state and compare for dirty detection, do NOT flag the serialization approach as a KISS violation or poor design. For small datasets, this is often the *simpler and more correct* approach than building an observable event graph across nested view models. The observable graph requires subscribing/unsubscribing at every level, handling collection replacements, and intercepting every mutation path — significant complexity that the snapshot approach avoids entirely.

The correct finding is **Medium** on the performance assumption: IsDirty computed as a serialization comparison is called on every Blazor render cycle (once per binding site per render). For small datasets this is imperceptible; for large datasets it silently becomes expensive. Recommend documenting the performance assumption inline, not rewriting the approach.

---

## Blazor RegisterLocationChangingHandler must be called after first render — OnAfterRender(firstRender) placement is correct

**Date**: 2026-05-19
**Category**: Process/Model

When reviewing Blazor components that register a RegisterLocationChangingHandler inside OnAfterRender(bool firstRender) guarded by if (firstRender), do NOT flag this as non-standard lifecycle usage. The Blazor framework requires the component to be interactive before RegisterLocationChangingHandler can be called safely; calling it in OnInitializedAsync fails silently in server-pre-rendered and SSR scenarios. The correct finding is **Low / comment-level**: note that a comment explaining the OnAfterRender placement would prevent future developers from "fixing" it by moving it to OnInitializedAsync.

---

## Pass-through async delegators in Blazor code-behinds are a reliable Low YAGNI finding

**Date**: 2026-05-19
**Category**: Process/Model

In Blazor components, one-line code-behind wrapper methods of the form private async Task Foo() => await ViewModel.Foo() are unnecessary: Blazor's @onclick directive accepts Task-returning no-parameter method references directly (e.g., @onclick="ViewModel.Foo"). When these wrappers appear, flag as **Low YAGNI** — they add one layer of indirection with no benefit. Do not confuse with wrappers that add pre/post logic, which are legitimate.

---

## Hardcoded SQL table lists in test teardown are a reliable Medium finding

**Date**: 2026-05-22
**Category**: Process/Model

When a test base class truncates the database using a raw SQL string that explicitly names each table (e.g., `TRUNCATE TABLE "TableA", "TableB", ... CASCADE`), flag this as **Medium** — not Low. The failure mode is schema drift: a developer adds a new entity and migration but forgets to add the table to the hardcoded list. Tests pass individually but fail non-deterministically when run in sequence (leftover rows persist between tests), which is the hardest type of test failure to diagnose. The standard fix is to derive the table list from the ORM model at runtime (e.g., `db.Model.GetEntityTypes().Select(e => e.GetTableName())`), making the teardown self-maintaining. Until that fix lands, recommend adding an explicit "SCHEMA SYNC REQUIRED" comment at the truncation site so future migration authors know to update it.

---

## DI module XML "caller responsibilities" lists should be cross-checked against the method body

**Date**: 2026-05-22
**Category**: Process/Model

When reviewing DI extension methods that include an XML `<remarks>` block listing services as "caller responsibilities" (i.e., intentionally omitted so the host can provide context-appropriate implementations), always verify each listed service against the method body. If a listed service is actually registered inside the method unconditionally, flag it as **Medium**: a developer adding a new host context reads the docs, concludes they must supply that service, and either double-registers it with a wrong implementation or wastes time creating a no-op implementation. In frameworks where last-registration-wins semantics apply (e.g., ASP.NET Core DI), a wrong over-registration silently replaces the correct one with no diagnostic. The fix is a one-line doc correction, but the severity is Medium because the misleading doc actively increases the risk of a future silent regression.

---

## Immutable-record domain aggregate + mutable UI working copy creates a structurally-forced DRY violation on derived predicates

**Date**: 2026-05-30
**Category**: Process/Model

When a domain aggregate is an immutable record (e.g., a C# `record`) that computes a derived boolean predicate (`AllItemsDecided`, `IsComplete`, `HasErrors`) over a list it owns, and a UI component must maintain a mutable copy of that same list (to support two-way binding), the component will re-implement the same predicate over the mutable copy. This is not a bad-faith DRY violation — it is a structural consequence of the immutability constraint. However, rate it **Medium** because: (a) the two implementations have no compiler or test linkage, so a future change to the domain predicate's semantics (e.g., a new "skipped" state that should also satisfy the gate) must be applied in both places independently; (b) reviewers reading one side won't know to check the other. **Rule:** For any immutable-record aggregate that exposes a derived gate predicate, check whether any UI consumer maintains a mutable copy of the list and re-implements the predicate. If so: Medium, with a recommendation to add a comment explicitly linking the two and warning that they must stay in sync.

---

## Service method `newPermissions`-style parameters are a YAGNI / Least Surprise trap when callers can't supply them at call time

**Date**: 2026-05-30
**Category**: Process/Model

When a "prepare session" service method accepts a parameter representing the proposed final state (e.g., `newPermissions`, `proposedValues`) but the caller hasn't determined that state yet (because the user must interact first), the parameter creates a false contract. Callers will pass the *current* state as a placeholder, making `session.NewValues == session.CurrentValues` on creation — semantically wrong and unused. This pattern is a **Medium YAGNI / Principle of Least Surprise violation**: (a) the parameter implies the caller knows the future state, which the prepare-session-first workflow precludes; (b) any derived field (e.g., `TemplateEditSession.NewPermissions`) is populated with wrong data and will mislead future readers who assume it represents the proposed change. **Rule:** If a "prepare/initialize session" method takes a future-state parameter, verify that every current caller can actually supply that value at prepare time. If any caller must pass a placeholder, recommend removing the parameter and receiving it only at the "apply/commit" step where the caller does know the final state.

