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
