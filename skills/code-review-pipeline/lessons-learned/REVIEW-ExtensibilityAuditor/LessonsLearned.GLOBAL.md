# Lessons Learned: REVIEW-ExtensibilityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## 2026-05-19 — `const` with "Future Configurable" Comment Is a Reliable Medium Finding

**Finding**: When a class contains a compile-time `const` (or `static readonly`) value with an inline comment saying "configurable per X in a future step" or "MVP constant — will become configurable", the comment is a documentation signal of a blocked extension point. The extension is consciously deferred but there is no injection path yet. This is a reliable **Medium** (High when a concrete planned feature depends on it, such as a new gate or a new host type). The fix is always: introduce an options type that follows the project's established `IOptions<T>` pattern with the current constant as the default value. The options type requires zero breaking changes — existing behavior is preserved via the default.

**Heuristic**: Grep for comments containing "configurable", "future step", or "MVP constant" adjacent to `const` or `static readonly` field declarations. Each match is a medium extensibility candidate. Elevate to High if the requirements audit identifies a feature that will require the configured value to vary.

**Corollary**: The options class template for the fix should mirror any existing options class in the same project — use it as the documented reference in the recommendation. This makes the fix concrete and pattern-consistent rather than generic.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future extensibility reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-18 — `IsActive = true` in MVVM Toolkit Constructor Is a Reliable High Finding for Testability

**Finding**: In CommunityToolkit.Mvvm projects, `ObservableRecipient` subclasses that set `IsActive = true` in the constructor immediately invoke `OnActivated()` → `Messenger.RegisterAll(this)`. This is a side-effect constructor pattern: any test that `new`s the ViewModel subscribes it to `WeakReferenceMessenger.Default` before any test assertion runs. If the messenger is not reset between tests, messages can leak across test cases. This is a **High** extensibility finding — not Medium — because it eliminates the "construct dormant, activate on mount" lifecycle that makes MVVM ViewModels testable in isolation.

**Heuristic**: In any MVVM Toolkit project using `ObservableRecipient`, search for `IsActive = true` in constructors. If found, flag as High and recommend moving activation to an explicit `Activate()` method or a navigation lifecycle hook.

**Corollary**: `ObservableRecipient` accepts an `IMessenger` constructor parameter. If the class does not thread a custom `IMessenger` through to the base, it defaults to `WeakReferenceMessenger.Default` — a second static-singleton coupling that should be called out alongside the constructor-activation finding.

---

## 2026-05-18 — `ObservableCollection<T>` in a ViewModel Interface Is a Reliable Medium Finding

**Finding**: When a ViewModel interface declares `ObservableCollection<ConcreteViewModel> Items { get; }`, any mock or alternate implementation must provide the full `ObservableCollection<T>` infrastructure — there is no `IObservableCollection<T>` in .NET. The finding is **Medium** (not High) because: (a) `ObservableCollection<T>` is the de-facto standard for MVVM collections and most test code can construct one trivially; (b) the coupling is in the collection type, not the element type. Elevate to High only if the concrete element type (`ConcreteViewModel`) also lacks an interface and has non-trivial behavior that test doubles would need to vary.

**Heuristic**: In any ViewModel interface, any property that returns a concrete mutable type (`Dictionary<K,V>`, `ObservableCollection<T>`, `List<T>`) is a coupling finding. Prefer `IReadOnlyDictionary`, `IReadOnlyList`, or at least expose a read-only view. `Dictionary<K,V>` returning mutable is the higher-severity of the two because callers can write to the internal state without going through the ViewModel.

---

## 2026-05-16 — Service Interface Signature Is the Most Impactful Extensibility Check for Roadmap Features

**Finding**: When the requirements audit has identified planned features with new data access patterns (e.g., round-aware queries, per-user aggregations, new write operations), the most impactful extensibility check is: does the current service interface signature accommodate the parameters those features will require? An interface method missing a `currentRound`, `userId`, or similar required parameter is a Medium extensibility blocker — not a Low — because changing an interface signature cascades to every caller and both DI registrations (or more, in multi-host architectures). The finding is especially actionable early: there is typically only one implementation and a handful of call sites, making the fix cheap now and expensive later.

**Heuristic**: For each planned feature identified in the requirements audit, ask: "What parameters would a new or modified service method need?" Compare that against the current interface. If a required parameter is absent, flag the interface as incompatible with that feature at Medium severity (dev tool) or High (production service).

---

## 2026-05-16 — Data Model Granularity Mismatch Is a Compounding Extensibility Risk

**Finding**: When a data model carries a single instance of a type (e.g., `Review: ReviewEntry` on a package item) but the roadmap plans to expand it to multiple instances (e.g., one review entry per mark), this is not just a correctness defect — it's an extensibility risk that compounds. Every UI feature built on top of the single-instance model must be refactored when the model is corrected. The earlier the mismatch is caught, the lower the refactor cost. Always check: does the granularity of the data returned by the service match the granularity that planned features will need? If the answer is "planned features need finer granularity than the current model provides," flag as Medium and recommend the model change before UI build-out continues.

**Heuristic**: Look for fields like `SomeItem Item { get; set; }` (singular) on a container where the requirements audit describes a future state of `List<SomeItem> Items { get; set; }` (plural). The singular field is the signal. The severity depends on how much UI is already built on top of it.

---

## 2026-05-18 — Enum-as-Gate-Registry Is a Reliable High Finding

**Finding**: When an interface has a `Name` property typed as an enum (e.g., `IEligibilityGate.Name => EligibilityGateName`), that enum is a closed registry in the core library. Every new implementation of the interface requires a core library change, violating OCP. This is a reliable **High** finding. The fix is always the same: replace the enum type with `string` and provide a constants class for well-known values.

**Heuristic**: Any interface where a property returns an enum that represents "which kind am I" (registry pattern) is a candidate for this finding. Contrast with enums that represent *state* (valid) vs enums that represent *identity* (risky).

---

## 2026-05-18 — CLI Top-Level Statement Files Hide Extensibility Debt

**Finding**: C# top-level statement `Program.cs` files that grow beyond ~300 lines with embedded local factory functions (`CreateSvc()`, `CreateDocSvc()`) are reliable signals of extensibility debt. The local factory functions serve as ad-hoc composition roots without DI. Each new service with complex dependencies requires a new factory function, and the file becomes a modification hotspot for every feature. Flag as **High** when the factory functions construct service dependencies with more than 2–3 levels of nesting, or when the file contains domain logic (MIME maps, switch statements on enum values) rather than only wiring.

**Heuristic**: Count the number of local `Create*()` functions. If > 3, recommend a DI container. If the file contains any `switch` on an enum value that would need editing when new enum values are added, flag the specific switch.

---

## 2026-05-18 — `Enum.TryParse` Is the Fix for Closed Switch-on-Status Patterns

**Finding**: When a CLI command maps a string arg to an enum value via a `switch` (e.g., `"pending" => TaskItemStatus.Pending`), any new enum value is silently unhandled (falls through to default). This is always a Medium finding. The fix is always one line: `Enum.TryParse<TEnum>(value, ignoreCase: true, out var parsed)`. Flag every such pattern — it is a consistent one-line fix with high forward-extensibility value.

**Corollary**: The silent fallback to "return all" or "use default" is technically functional but behaviorally incorrect — callers expecting an empty result for an invalid filter get all results instead. Mention this behavioral inconsistency alongside the extensibility finding.

---

## 2026-05-18 — "Built But Not Wired" Infrastructure Is Critical, Not Dead Code

**Finding**: When a project contains fully implemented infrastructure (dispatch loop, strategy resolver, coordinator) that is never activated via any command or entry point, this is a **Critical** extensibility finding — not a dead code warning. The extension points are real and well-designed, but dormant. Frame it as: "The extension point exists and is correct; the activation mechanism is missing." Recommend adding the entry point rather than removing the infrastructure.

**Heuristic**: Before flagging any class as dead code, check whether it is referenced transitively by any other class in the same project. Only flag as truly dead if no class ever instantiates it. If it has interfaces, constructors, and tests — it was designed to be used.

---

## 2026-05-16 — Define Platform-Specific Service Seams Before the Feature, Not During It

**Finding**: In a multi-host architecture (Desktop + Web, or Desktop + MAUI + Web), some planned features will need behavior that differs per host (e.g., "open file in system default handler" works on Desktop, not on Web). When the requirements audit identifies such features and no interface seam yet exists for the platform-specific operation, flag it as Medium at review time — not Low. The cost of defining the seam now (one interface + two null/real implementations) is near-zero. The cost of defining it mid-feature under schedule pressure is higher, and the risk of an incomplete seam (e.g., no `IsSupported` guard, no web no-op) breaks the alternative host. The check: does every planned platform-divergent feature have a corresponding `IXxxService` in the Core project?

---

## 2026-05-16 — Positional C# Records Used as Pipeline Output DTOs Are Frozen Extensibility Anti-Patterns

**Finding**: When a C# positional record is used as the output type of a multi-step pipeline (e.g., an eligibility evaluation result, a validation summary, a scoring breakdown), every named parameter in the positional list becomes a breaking change surface. Adding a new pipeline gate/layer requires changing the record's parameter list, which breaks every call site that constructs or destructures the record. This is a High extensibility issue — not Medium — when: (a) the pipeline is actively evolving with more gates planned, and (b) the record is returned by a service interface consumed across multiple projects.

**Heuristic**: Look for records with more than three named non-primitive positional parameters, especially when those parameters represent "categories" or "gates" of the same concept (e.g., five `LayerResult` fields named by check type). Any time a reader of the record would have to add a new same-typed field to extend the pipeline, the design is frozen. The fix is to replace fixed named fields with a dictionary or list, using constants for named access.

**Corollary**: Distinguish between a positional record used as a simple data carrier (fine — adding fields is additive) vs. a positional record used as a categorized summary of pipeline results (problematic — each category is a positional parameter that breaks callers).

---

## 2026-05-16 — Strategy Pattern With Partial Extension Points Is a Reliable High-Severity Finding

**Finding**: When a strategy interface provides one extension hook (e.g., `GetManifestMetadata()` for metadata customization) but not a parallel hook for an adjacent concern (e.g., prompt template, output format, completion signal), the "partial extension" is a reliable High finding. The pattern signals that the design was started correctly but not completed. The consequence is that the builder/orchestrator must hard-code the unhooked concern for all strategies, creating an OCP violation at the builder layer even while the strategy layer itself is correctly open.

**Heuristic**: For every customization hook on a strategy interface, ask: "What other aspects of the operation could legitimately differ per strategy?" If the answer includes something the builder currently hard-codes, that is a missing extension point at High severity (if the variation is imminent) or Medium (if it's speculative). The fix is symmetric: add a `GetX()` method parallel to the existing `GetManifestMetadata()` pattern.

---

## 2026-05-12 — Always Check `AddSingleton` Registrations for Global State When Multi-Tenant/Multi-Board Is Planned

**Finding**: When a planned roadmap item includes multi-user, multi-board, or multi-tenant support, the first place to look for Critical extensibility blockers is the DI registration list — specifically any `AddSingleton` service that holds mutable state. A singleton that stores a "current board", "current user", or "current tenant" is architecturally incompatible with multiple concurrent users. The code that reads from the singleton looks correct in isolation, but every caller is implicitly sharing the same state. Flagging this as Critical (not High) is correct when: (a) the planned feature explicitly requires per-user isolation, and (b) every query in the application passes through the singleton to get its board/tenant scope.

**Heuristic**: In `Program.cs` (or `Startup.cs`), search for `AddSingleton` and examine each registration. For each one, ask: "Would two concurrent users get different results from this service?" If yes and multi-user is planned, it's Critical.

---

## 2026-05-12 — Request/DTO Record Field Comparison Is a Reliable Extensibility Check

**Finding**: When an entity has a FK column (e.g., `BoardId`, `OwnerId`) but the corresponding request/DTO record does not include that field, new objects can never be assigned that relationship through the normal API surface. The service's `AddAsync` method will never set the field. The data arrives unassigned and must be backfilled externally. This is a Low-to-Medium extensibility finding (exact severity depends on how soon the FK is needed) that is easy to miss because the entity and the request look correct in isolation. Always compare FK fields between entity and request records as a checklist step.

---

## 2026-05-08 — `Enum.GetValues<T>()` in UI Is an Accurate Signal of Open Extension Points

**Finding**: When reviewing enum-backed UI controls, check whether buttons/options are rendered via `Enum.GetValues<T>()` or via hard-coded element-per-value markup. `Enum.GetValues<T>()` is a genuine open extension point — adding an enum value automatically surfaces in the UI with zero code changes. Hard-coded per-value markup is a closed pattern. The two look similar at a glance; distinguish them before reporting extensibility findings for form controls.

**Pattern**: This distinction can produce false positives if you assess "effort to add a horizon value" as "High" without checking the form component. Always check both the consuming form/component AND the business logic (inference, scoring) separately — the UI may be open while the business logic is closed, or vice versa. Report both facts in the finding with separate impact lines.

---

## 2026-05-08 — Duplicate Display Metadata in Multiple View Components Is a Reliable High-Value Finding

**Finding**: When the same enum-to-CSS-class and enum-to-label mappings appear independently in multiple view components, always flag this as a Medium finding even if each individual occurrence is trivially small. The duplicated static method pattern compounds: each new view component independently re-authors the same mappings, and divergence between them becomes a source of subtle UI inconsistencies. A shared static display-metadata utility eliminates the multiplication.

**Heuristic**: Search for the string `switch` in view code-behind files (`*.razor.cs`). If you find the same enum being switched for a style/label result in more than one file, flag the duplication and recommend a shared utility.

---

## 2026-05-13 — Dev Tool Tier Requires Lower Severity Calibration Than Production

**Finding**: When the code under review is a developer-only tool (DevTools project, default-off toggle, never registered in production DI), apply a lower severity baseline than for production code. Patterns that would be Medium in production are Low in a dev tool; patterns that would be High are Medium at most. The key question is: "What is the actual cost if this needs to change?" For a dev tool used locally by a handful of engineers, modifying the code is trivial — there is no deployment, no API contract, no concurrent users.

**Heuristic**: Ask "Is this in a DevTools project, behind a default-off toggle, and never referenced by production assemblies?" If yes, apply the severity downgrade. If the pattern also lives in the shared Framework layer (e.g., `FlowRunner`), evaluate that layer at production severity — the framework is reused broadly.

**Corollary**: Do NOT flag missing abstractions in dev tools as High extensibility issues. A `bool` mode selector on a dev tool's constructor is Low, not Medium, unless a third mode is actively planned or the flag also appears in a production class.

---

## 2026-05-14 — Domain-Constrained Binary Parameters Are Low Severity, Not Medium

**Finding**: The existing lesson about `bool` parameters says "Medium when a method has exactly two states and a third variant is plausible in the domain context." The key qualifier is **domain context**. When a `bool` encodes a **physical or domain-structural concept** where exactly two values are legally possible (e.g., left end / right end of a physical member, left side / right side of a joist), rate it as **Low**, not Medium. The "plausibility of a third variant" test fails when the domain itself constrains the cardinality to two.

**Contrast**: A `bool useW2Fallback` that selects between two calculation strategies IS plausibly extensible to three strategies — rate that Medium. A `bool isRightSeat` on a joist factory where a joist has exactly two ends by structural definition is NOT plausibly extensible — rate that Low, with a note that an enum would improve readability without changing the severity assessment.

**Heuristic**: Before assigning Medium for a bool parameter, ask: "Is there a structural, physical, or contractual reason this can only ever be two values?" If yes, downgrade to Low.



**Date**: 2026-04-28
**Category**: Process/Model

When a private method on a resolver/calculator accepts a `bool` parameter that selects between two fundamentally different fallback or strategy paths (e.g., `bool useW2Fallback`), treat it as a Medium extensibility finding. The flag signals that the method is doing two different jobs unified by a boolean rather than by abstraction. The correct severity is Medium (not Low) when the method has exactly two states and a third variant is plausible in the domain context. The correct recommendation is a `Func<...>` strategy parameter or two separate methods, not an enum — enums require modification too. Only escalate to High if a third variant is explicitly planned or if the boolean selects between behaviors with different correctness consequences (not just different fallback values).

---

## Entry: C# Default Interface Members — Overrides Dispatch Correctly Through Interface References

**Date**: 2026-04-22
**Category**: Process/Model

When a C# 8+ interface uses default property/method implementations that `new` up concrete types, those defaults CAN be overridden in implementing classes — and the override WILL be called as long as the consumer holds an interface reference (not a concrete reference). Do NOT flag this pattern as "defaults are not overridable" or "tightly coupled to concrete types at the interface level" when the calling code uses the interface reference. The extension point is real and functional. Severity should not exceed Low unless the implementing class is also `sealed` and no alternative implementation path exists.

---

## 2026-04-22 — Feature Toggle Severity Depends on Toggle Lifetime

**Finding**: When auditing toggle-duplicated dispatch logic, check `appsettings.shared.json` (or the equivalent default configuration file) to determine whether a feature toggle is a **temporary safe-release flag** or a **long-lived opt-in flag**. A toggle set to `"Off"` globally with no documented retirement plan is permanent. Permanent toggle duplication should be rated High severity; temporary safe-release toggles are Medium. The two look identical in code — only the config file reveals intent.

**Pattern**: Search for the toggle name in the app settings file early in the review. If the toggle is "Off" in shared/production settings, treat the duplication as long-lived.

---

## 2026-04-24 — Dual-Track Enum Mapping Creates Silent Divergence Risk

**Finding**: When a codebase has two independent code paths that both map the same enum (e.g., old-path switch statement, new-path attribute-based lookup), adding a new enum value will silently break only the path that uses the switch. The failure mode is not an exception — the switch falls to `default → null` and skips the affected behavior. This is an extensibility risk that is easy to miss because the two paths are often in different files and activated by different conditions.

**Heuristic**: When you find a switch statement that maps one enum to another, search for alternative mapping approaches for the same enum pair elsewhere in the codebase. If they coexist, flag the switch as "closed for extension" at High severity and recommend a shared utility.

---

## 2026-05-06 — Co-Required Step Pairs Without Structural Enforcement Are Medium Extensibility Findings

**Category**: Process/Model

When two flow steps must always appear in sequence (e.g., StepA followed immediately by StepB), and the framework provides no mechanism (base class, template method, composed sub-flow, or compile-time constraint) to enforce co-occurrence, rate this as Medium severity. The correct recommendation is either: (a) compose the pair into a single named unit so consumers reference one thing, or (b) add a prominent comment at the declaration site of the first step stating the required pairing. Do NOT rate this as Low simply because the pattern has been correctly applied so far — the risk is additive: each new call site is an independent opportunity for omission. Escalate to High only if the pair must appear in a hot path where an omission produces a silent wrong-answer defect with no exception signal (i.e., a bug exactly like the one the PR was fixing).

---

## 2026-05-12 — Template Method FlowDecision Subclasses Are Not Tight-Coupling Issues

**Category**: Process/Model

When a codebase uses an abstract `FlowDecision` base class with a `DecideStep(TContext)` override as the primary extension mechanism, concrete subclasses that read all state from the shared context object (no injected dependencies) are idiomatic — **do not flag them as tight-coupling**. The context object is the intentional single dependency for all decision steps. Similarly, `AddSingleton`-free registration of parameterless decision classes directly instantiated in a constructor is the correct pattern, not a DI violation.

Also: when an `internal interface` gains a new property (the standard extensibility step in this pattern), the blast radius is bounded to one assembly. Do not report this as a "breaking API change" — it is specifically not that when the interface is internal.

---

## 2026-05-12 — Asymmetric Features Between Sibling Classes Are Usually Intentional

**Category**: Process/Model

When sibling classes (e.g., `TopChordDesignEngineFlow` and `BottomChordDesignEngineFlow`) have different capabilities — one has a guard, the other does not — verify the business reason before flagging as a DRY violation or extensibility gap. Domain context frequently justifies asymmetry: if the skip condition is driven by a concern that genuinely only applies to one chord, separate implementations are the correct design. Always check the requirements-audit for the business reason before rating asymmetry at Medium or above.

---

## 2026-04-24 — Two-Toggle Mutual Exclusivity Invariants Need Explicit Documentation

**Finding**: When a new toggle is introduced to replace an older one (new mechanism supersedes old mechanism), and the old mechanism has a bypass that prevents double-application, the bypass code has a hidden invariant: "the bypass must remain as long as both toggles can be independently on." This is a **toggle retirement trap**. After the new toggle is promoted, the bypass looks like dead code — but it is not. Removing it silently reintroduces the original defect.

**Pattern**: When auditing two overlapping toggles, check:
1. Is there a bypass in the old code path that references the new toggle by name?
2. Is the bypass's purpose to prevent double-application?
3. Is there a test that verifies the bypass?

If (3) is missing, flag High. If (2) is present with no retirement comment, recommend adding a `// RETIREMENT NOTE` comment at the bypass site.

---
## 2026-05-06 — Version-Specific Namespace Does Not Guarantee Version-Specific Routing

**Finding**: When a calculator class lives in a namespace named after a specification version (e.g., `Sji45.PanelPointShearStressCalculator`), do NOT assume it is only used for that version. Check the provider's `BuildCalculators` method to see whether it is version-routed or shared. A common pattern: a base calculator in the `Sji45` namespace is instantiated unconditionally in the shared provider, and version-specific overrides are applied via a separate mutation mechanism. If the mutation interface for a given member type has no version-specific implementation, the Sji45 calculator runs for ALL versions.

**Consequence for audits**: If a fix targets "the Sji45 path" but the calculator used is shared (no version-specific mutation override), the fix implicitly affects all versions. Check whether characterization test reference files were updated for ALL versions that use the calculator — not just the named version. If only one version's reference files were updated, flag a High finding: the toggle/fix applies to an untested code path.

**Pattern**: Search for `IPanelPointMutations` (or the equivalent mutation interface for the member type). If no `*Sji46Mutations.cs` implementation exists for that interface, the behavior is shared. Do this check before concluding a fix is version-isolated.

---

## 2026-04-29 — Exclusion-Accumulation Naming on Public Interfaces Is a Medium Finding

**Finding**: When a public interface method uses a naming pattern that accumulates excluded types in the method name (e.g., `HasAnyCheckOutputIgnoringX` → `HasAnyCheckOutputIgnoringXAndY` → ...), flag it as Medium severity. Each new excluded type requires renaming the public interface member, which is a breaking change for any external callers and forces updates at the interface declaration, implementation, all callers, and all test mocks. The violation compounds on public interfaces because name stability is an API contract.

**Pattern**: Look for method names containing `Ignoring`, `Excluding`, `Without`, or similar words followed by a list of concrete type names. If the name grew from a previous version (prior rename), rate the finding Medium. The fix is to replace the exclusion list in the name with a parameterized predicate (`Func<T, bool>` include-filter or an exclusion enum/set). This keeps the method name stable as the exclusion set evolves.

**When NOT to flag**: Internal methods (not on a public interface) with exclusion-list names are Low severity — renaming is contained within the assembly. Only escalate to Medium when the exclusion-accumulation pattern is on a `public` interface member.

---
## Toggle Embedded in Utility Method Body Hides Conditionality at Every Call Site

**Date**: 2026-05-07
**Category**: Process/Model

When a utility or service method reads a feature toggle internally and uses it to vary its filtering or predicate behavior, the method name typically implies a fixed, unconditional result. Call sites give no indication that a toggle influences the outcome. At toggle retirement time, a developer must search for toggle usage inside method bodies rather than at call sites — a non-obvious search that is easy to miss. The method name also becomes incorrect after toggle promotion: a name like `HasAnyOutputIgnoringX` will still say "ignoring X" even after the toggle is removed and X is no longer ignored.

**Heuristic**: When reviewing utility classes that inject `IToggles`, check each method for internal toggle reads. If a toggle is read inside a method whose name describes a fixed filtering behavior (e.g., `GetItemsIgnoringX`, `HasAnyMatchExcludingY`), flag it as a Medium extensibility/retirement finding. The fix is to surface the toggle check at the caller and pass a resolved `bool` or predicate parameter into the utility method, so the method is free of toggle awareness. Also recommend adding a `// RETIREMENT NOTE` comment at the toggle branch inside the method body.

**When NOT to flag**: If the method name does not imply a fixed behavior (e.g., `GetFilteredOutputs(Func<T, bool> include)`) and the toggle is resolved externally before calling it, no flag is needed.

---

## Public Extension Methods as Partial Enum Mappings Create a Hidden-Throw Contract

**Date**: 2026-05-06
**Category**: Process/Model

When an enum-to-enum mapping method is `public` and covers only a *subset* of the source enum's values (throwing `ArgumentOutOfRangeException` for the rest), the method name typically sounds complete ("MapToX", "ToY") — it gives no hint that certain enum members will throw. Future callers who iterate all enum values, or who receive an unfiltered value at runtime, will encounter an unexplained exception.

**Pattern**: Flag this as Medium severity when: (a) the method is `public`; (b) it throws for ≥1 enum value that a caller could plausibly pass; and (c) there is no XML doc comment or `Try...` companion method advertising the partial contract. The recommended fix is either (1) restrict visibility to `internal`, (2) add an XML doc comment listing the throwing values, or (3) add a `TryMapToX` companion that returns `bool` instead of throwing. Option (3) also solves the caller's problem by giving them a safe code path.

**When NOT to flag**: If the throwing values are clearly system-internal sentinels (e.g., `TestHarness = 0` with a `RestrictUsage` attribute) and the source enum itself documents the restriction, the throw is expected and discoverable. Only flag when the throwing values are ordinary domain members with no such marker.

---

## `_ => throw` in Switch Expressions Is a Runtime-Only Exhaustiveness Check

**Date**: 2026-05-06
**Category**: Process/Model

In C#, using a catch-all `_ => throw new ArgumentOutOfRangeException(...)` as the final arm of a switch expression SUPPRESSES compiler warning CS8509 (non-exhaustive switch). This means: adding a new enum value to the source type will compile cleanly and only fail at runtime when the new value is first encountered. If the default arm were *removed* instead, the compiler would emit CS8509, providing a build-time signal that the switch needs updating.

**Heuristic**: When auditing switch-based enum mappings that use `_ => throw`:
- Do NOT flag `_ => throw` as a defect — it is the correct fail-loud strategy, far better than `_ => default`.
- DO flag it as Medium if the enum is in active development (new values are plausible soon) AND there is no exhaustive unit test that iterates all enum values through the mapping. The test compensates for the suppressed compiler warning.
- A switch with `_ => throw` and an exhaustive test is at parity with a no-default-arm switch for practical purposes; a switch with `_ => throw` and no exhaustive test is a hidden runtime trap.

---

## 2026-04-24 — Optional `IToggles? toggles = null` Accumulates as a Silent Opt-Out Pattern

**Finding**: An optional toggle parameter with a null default (`IToggles? toggles = null`) is a backward-compatibility shim that becomes a liability as more toggle-gated features use the same method. Any caller that omits the parameter silently opts out of all toggle-gated behavior — not just the original one. The failure mode is incorrect results (not exceptions), making it hard to diagnose.

**Pattern**: Flag `IToggles? toggles = null` as a Medium finding when it appears on a method that has more than one toggle-gated branch. The recommendation should be to make the parameter required and provide an explicit "all-off" value for callers that need legacy behavior.
