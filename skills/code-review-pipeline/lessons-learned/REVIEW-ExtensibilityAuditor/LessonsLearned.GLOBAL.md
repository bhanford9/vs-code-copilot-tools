# Lessons Learned: REVIEW-ExtensibilityAuditor

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

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future extensibility reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-19 — `const` with "Future Configurable" Comment Is a Reliable Medium Finding

**Category**: Process/Model
**Finding**: When a class contains a compile-time `const` (or `static readonly`) value with an inline comment saying "configurable per X in a future step" or "MVP constant — will become configurable", the comment is a documentation signal of a blocked extension point. The extension is consciously deferred but there is no injection path yet. This is a reliable **Medium** (High when a concrete planned feature depends on it, such as a new gate or a new host type). The fix is always: introduce an options type that follows the project's established `IOptions<T>` pattern with the current constant as the default value. The options type requires zero breaking changes — existing behavior is preserved via the default.

**Heuristic**: Grep for comments containing "configurable", "future step", or "MVP constant" adjacent to `const` or `static readonly` field declarations. Each match is a medium extensibility candidate. Elevate to High if the requirements audit identifies a feature that will require the configured value to vary.

**Corollary**: The options class template for the fix should mirror any existing options class in the same project — use it as the documented reference in the recommendation. This makes the fix concrete and pattern-consistent rather than generic.

---

## 2026-05-20 — Hard-Coded Fan-Out Aggregator: Reliable Medium When New Subscriber Types Are Plausible

**Category**: Process/Model
**Finding**: When a coordinator/aggregator class calls a fixed, hard-coded set of subscribers inline (e.g., a notification dispatcher that calls exactly two subscriber interfaces in sequence inside its implementation body), and the requirements context suggests new subscriber types are plausible (audit logs, webhooks, external notifications), this is a reliable **Medium** extensibility finding. The pattern is closed for extension: each new subscriber type requires a code change to the coordinator.

**Heuristic**: Search for service classes whose constructor injects exactly two or three subscriber-like interfaces (e.g., two `IXxxNotifier`-typed fields). If the class body calls all of them in a fixed sequence, the fan-out is hard-coded. The fix is: accept `IEnumerable<ICommonObserverInterface>` and iterate. If a common observer interface doesn't exist yet, introduce a narrow one (`ITaskStatusObserver`, `IEventSubscriber`, etc.) and have the existing implementations adapt to it.

**Severity calibration**: Elevate to High if the requirements audit identifies a concrete planned subscriber type (e.g., "send Slack notification on dispatch") that cannot be added without touching the aggregator. Keep at Medium if the subscriber types are anticipated but not yet on the roadmap.

**Corollary**: Do not flag this as Medium if the class explicitly documents "there will never be more than these two subscribers" with a domain reason. In that case, the aggregator is intentionally closed and the finding is a false positive.

---

## 2026-05-31 — Write-Biased Append Service with Named Future Consumer Types: Reliable High Read-Surface Finding

**Category**: Process/Model
**Finding**: When a write-first append service (audit trail, event log, ledger) exposes only the read methods needed to satisfy the current slice's test scenarios, but the requirements audit explicitly names additional consumer types that the current read surface cannot serve (e.g., alerting, compliance export, correlation-group retrieval), the interface will require extension at the next consumer-adding slice. The blast radius for that extension grows with every mock implementation added in unit tests for future services. This is a reliable **High** finding — the cost of adding read methods now (one implementation class + one test class) is at its minimum; every deferral adds a file to the blast radius.

**Heuristic**: At review time, compare: (a) the read methods on the service interface, and (b) the consumer types named in the requirements doc. For each consumer type, ask: "Can it be served without pulling all records for a resource/actor into memory and filtering in application code?" If no, flag as **High** and recommend a filter-object query pattern that can serve all named consumer types from a single interface method.

**Severity calibration**: High when multiple consumer types are named and none can be served without application-side filtering. Medium when only one consumer type is anticipated and a single new overload would serve it. Low when all named consumer types can be served by the existing read methods with minor query composition.

**Corollary**: The filter-object pattern (`QueryAsync(FilterObject filter)`) is the most future-proof read expansion because new filter dimensions can be added to the filter type without changing the method signature. Separate methods (`GetByEventTypeAsync`, `GetByCorrelationIdAsync`) are easier to implement but foreclose the filter-composition use case and grow the interface surface with each addition.

---

## 2026-05-31 — Non-Nullable Grouping/Correlation Field on a Predominantly Standalone-Event Record: Reliable Medium Schema Finding

**Category**: Process/Model
**Finding**: When an append-only record schema includes a mandatory (non-nullable) correlation or grouping ID field, but most events in the system are standalone (no natural group), callers are forced to generate semantically meaningless values (e.g., `Guid.NewGuid()` or a post-hoc reuse of a different identifier) to satisfy the constraint. The field's semantic value is diluted: future queries that filter by the grouping ID return misleading results (single-record "groups" for every standalone event). Making the field nullable is a low-cost, semantically correct migration that should be made before production data accumulates incorrect values.

**Heuristic**: For each non-nullable grouping/correlation field on a record type, count: (a) how many callsites fill the field with a value that genuinely identifies a logical group (multiple related records share the same value), and (b) how many callsites fill it with a per-record stub (the record's own ID, or a freshly generated random value). If type (b) callsites exceed or equal type (a) callsites, flag as **Medium** — the field's semantic contract is not enforceable with a non-nullable constraint.

**Severity calibration**: Medium (not High) when the field is not yet indexed or used in a critical query path. Elevate to High if a query method filters by this field and returns misleading result sets that affect correctness. Keep at Low if all callsites genuinely participate in a correlation group and standalone events are the exception.

**Corollary**: The fix (change to nullable + migration) is cheapest before any production data has been written with stub values. Once rows exist, a migration must decide how to treat existing stubs — document that `NULL` means "standalone event, no correlation group." A companion `GetByCorrelationIdAsync` (or `QueryAsync(filter)`) method should exclude null values to avoid returning singleton groups.

---

## 2026-05-30 — Manually-Initialized Catalog Set Without Reflection Guard: Reliable Medium Finding

**Category**: Process/Model
**Finding**: When a static class maintains a `IReadOnlySet<string>` (or equivalent) populated by a hand-written initializer list of constants defined in the same class, there is no compile-time or structural test enforcement that every declared constant is present in the set. A developer who adds a new constant to the source type but omits it from the set will see: (a) a green build, (b) passing tests for all existing entries, and (c) a silent behavioral failure — any evaluation using the new constant returns a "not in catalog" deny without an exception or error log. The test suite's per-entry `Contains` assertions only prove what is already known to be there; they do not discover unknown omissions.

**Heuristic**: When a static class combines: (a) `const string` or similar compile-time fields AND (b) a static `IReadOnlySet<string>` initialized from those same fields, check whether any test uses reflection to assert that every declared constant is in the set. If not, flag as **Medium** and recommend a reflection-based structural test that enumerates `GetFields(BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly)` and asserts each declared value is in the set.

**Severity calibration**: Keep at Medium when the failure mode is silent runtime deny (not a security breach). Elevate to High if the set is used as an authorization gate and missing entries would silently grant or deny broad permissions in ways that bypass other controls.

**Corollary**: Do NOT recommend converting the set to a reflection-populated runtime enumeration if the set encodes a security invariant that must be explicitly curated. In that case, the curated set is correct and the fix is the structural test only.

---

## 2026-05-30 — Multi-Class Catalog vs. Fewer-Valued Enum: Undocumented Caller Scope Contract — Reliable High Finding

**Category**: Process/Model
**Finding**: When a catalog class defines N nested type groups (e.g., N nested static classes with string constants), but the enum used to classify items at evaluation time has fewer than N values, callers of the evaluation API face an undocumented choice: which enum value to pass for items from the "extra" group. If only one test uses the extra group and makes an undocumented scope choice, future callers have no signal — a different developer may choose a different enum value and get different evaluation behavior with no compiler or test failure.

**Heuristic**: At review time, compare: (a) the number of distinct top-level groups in the catalog/constants class, and (b) the number of values in the associated scope/type enum. If the groups exceed the enum values by one or more: (a) locate any tests that pass one of the extra-group constants through the evaluator and note what enum value they choose, (b) flag as **High** — the caller contract is undocumented, and (c) recommend either adding the missing enum value(s) or documenting the intentional scope aliasing decision in both the enum XML doc and the architecture doc.

**Severity calibration**: High (not Medium) because the undocumented contract is a correctness risk — two developers independently choosing different enum values for the same constant get different authorization decisions, with no indication which is correct. Medium is only appropriate if there is exactly one call site and it is the only place the extra-group constants will ever be evaluated.

**Corollary**: This finding often co-occurs with a structural test that uses a string-prefix check (e.g., `perm.StartsWith("PREFIX-A") ? Scope.TypeA : Scope.TypeB`) to classify entries. An `else` branch that catches all non-A entries will silently misclassify any future entry from a third group. Flag the `else`-based classification as a **Low** companion finding and recommend replacing it with an explicit throw on unrecognized prefixes.

---

## 2026-05-30 — Enum-Dispatched Service Methods Without Exhaustiveness Guard: Reliable Medium Finding

**Category**: Process/Model
**Finding**: When a service method iterates over a collection of enum-valued decision entries and handles each enum case with explicit `if`/`else if` branches — but has no final `else`/`default` that throws — adding a new enum value causes a silent no-op. The method completes successfully, returns no error, and the new case is never processed. This failure mode is invisible to all existing tests because the existing tests only exercise the known values.

**Heuristic**: When reviewing a service method that branch-dispatches on an enum, check whether the method has an exhaustiveness guard (a `throw` in the final `else`, or a C# exhaustive `switch` expression). If not, and if the enum has any realistic chance of growing (decision types, state types, category types), flag as **Medium** and recommend a throwing `else`/`default` branch. The fix is a single-line throw that converts a silent data corruption into an immediate, unmissable failure.

**Severity calibration**: Keep at Medium when the enum is domain-stable (unlikely to gain values). Elevate to High when the requirements context explicitly anticipates new decision types or states for the same flow. Keep at Low only if the enum is a system-internal type with no planned extension path.

**Corollary**: A guard at the top of the method that rejects the zero-value sentinel (e.g., `Pending`) does not substitute for an exhaustiveness guard on the other values. Both are needed: the sentinel guard is a safety net; the exhaustiveness guard is a design completeness check.

---

---

## 2026-05-31 — String-Persisted Enum Stable-Contract in Doc Comment Only: Reliable Medium Finding

**Category**: Process/Model
**Finding**: When an enum's values are persisted as strings (e.g., via an ORM's string conversion) and the stable-contract promise is expressed only as an XML doc comment, the compiler provides no protection against accidental renames. A refactoring tool that renames `EventTypeA` to `EventTypeB` will compile cleanly, pass all existing tests, and silently corrupt every historical row with the old string value. ORM parsing of the old string will typically return the zero-value sentinel (`Unknown`, `None`) with no exception or warning log.

**Heuristic**: When reviewing a string-persisted enum, check for a test that asserts the string representation of each value against a hard-coded expected string. If no such test exists, flag as **Medium** and recommend adding one. The test pattern: iterate a hand-authored array of `(enumValue, expectedString)` pairs and `Assert.That(value.ToString(), Is.EqualTo(expected))`. A new enum value added without a corresponding array entry causes a test failure.

**Severity calibration**: Medium (not High) when the enum covers events on a single subsystem and the blast radius of a rename is contained. Elevate to High when the enum values are used as classification keys in compliance, audit, or regulatory reporting where historical record accuracy is a hard requirement.

**Corollary**: The test array also serves as live documentation: every reader of the test file knows exactly which string values appear in the DB and can trace them to enum members. This is more reliable than relying on the enum member names as implicit documentation.

---

## 2026-05-31 — Binary Ternary on an Open (3+-Value) Enum: Reliable High Finding for Security/Auth Scope Mappings

**Category**: Process/Model
**Finding**: When a method maps a `scope` or `type` enum to a policy/permission/handler using a binary ternary (`value == CaseA ? resultA : resultB`), and the enum has or will have three or more values, any value that is neither `CaseA` nor the zero sentinel silently evaluates as `CaseB`. For authorization scope mappings, this means "evaluate under the wrong permission" — not a denial, not an exception, but a silent wrong-policy evaluation that appears to succeed. This is more dangerous than a miss because callers receive a plausible Allow/Deny result from the evaluator rather than an error.

**Heuristic**: Search for ternary expressions of the form `enumField == X ? A : B` where the enum type has more than two values. For each match, verify that every current and anticipated enum value is explicitly handled — if not, the ternary is closed against extension. For authorization and security policy mappings, flag as **High** regardless of whether the third value exists today; the cost of a silent wrong-policy evaluation is always high.

**Severity calibration**: High for authorization, security policy, or billing-scope mappings (wrong result is silent and plausible). Medium for display/label mappings (wrong result is visible and unlikely to cause correctness issues). Low for default-value fallbacks where the `else` result is explicitly documented as the intended fallback for all other values.

**Corollary**: The fix is a switch expression with a throwing default arm: `value switch { CaseA => A, CaseB => B, _ => throw new ArgumentOutOfRangeException(...) }`. This converts a silent wrong-policy evaluation into an immediate, logged, test-catchable exception. The throw is caught the first time a developer exercises the new value in any test — before production.

---

## 2026-05-28 — Single-Method Evaluator Interface Is a Positive Finding: Note It Explicitly

**Category**: Process/Model
**Finding**: When an authorization or evaluation engine exposes a single-method interface, this is the design's strongest extensibility asset and should be called out **positively** in the audit. A single-method interface enables fully transparent decorator chains — caching, audit emission, rate-limit detection, multi-tenant routing — without modifying the concrete evaluator. These cross-cutting concerns are common sequels to any phase-1 evaluation engine.

**Heuristic**: When the interface has exactly one method, note: (a) what cross-cutting concerns are enabled by the seam without touching the evaluator, and (b) specifically name the likely sequels (caching, audit, rate-limit). Frame it as an architectural strength, not just an absence of a finding. This makes the positive design decision visible to reviewers who read the report.

**Corollary**: A `sealed` concrete class paired with a single-method interface is not a restriction — it is the correct composition of OCP compliance at the caller boundary and LSP safety at the class level. Do not flag the `sealed` keyword as a low extensibility concern when the interface is already the extension seam.

---

## 2026-05-28 — Authorization Trace Labels Are a Hidden Consumer-Coupling Surface

**Category**: Process/Model
**Finding**: In an authorization engine, the string labels used to identify resolution steps are initially local to the evaluator. But as audit log, UI, and API consumers multiply, each consumer must hardcode the same strings. This is a hidden coupling surface that grows silently: no compiler error when a label changes, and only tests that assert against the exact label catch the mismatch.

**Heuristic**: When reviewing a phase-1 authorization engine that uses raw string literals for trace/decision labels, flag as **Medium** and recommend a `ResolutionSteps` (or equivalent) constants class before the first downstream consumer (audit log, UI display, API response) is built. The fix is a zero-behavior-change, single-file change that makes every consumer reference a named constant rather than a string literal.

**Severity calibration**: Keep at Medium (not High) when no downstream consumer exists yet. Elevate to High when an audit log, admin UI, or API serializer already references the strings independently — at that point the coupling has materialized and a rename requires a multi-file coordinated change.

---

## 2026-05-28 — Security-Invariant Collection Coupled to Enum Expansion: Structural Invariant, Not OCP Violation

**Category**: Process/Model
**Finding**: When a hard-coded collection (e.g., a guardrail set, a whitelist) encodes a security invariant and is intentionally NOT made configurable, it may still be structurally coupled to an enum or type system elsewhere. Adding a new enum value requires a coupled update to the collection — but this is a **structural invariant to enforce**, not an OCP violation to eliminate. Making such a collection configurable via options/environment would weaken the security guarantee.

**Heuristic**: When you find a security-closed collection that parallels an enum (e.g., 4 entries per enum value), rate as **Medium** and recommend: (a) document the structural invariant explicitly (in comments or a README), and (b) add a unit test that asserts the invariant structurally (e.g., "the collection must have N entries for each enum value"). The test makes missing entries a CI failure rather than a silent security regression.

**Corollary**: Do NOT recommend making the collection `IOptions<T>`-configurable. The correct fix is documentation + structural test, not injection. Configurable security invariants are themselves a security finding.

---

## 2026-05-28 — Security-Motivated Narrow Interface: Assess Temporal Cost, Not OCP Violation

**Category**: Process/Model
**Finding**: When a service interface exposes only one or two members and its own XML doc comment explains the narrowness as a deliberate security decision (e.g., "only exposes `bool IsAvailable` to prevent secrets from reaching client-visible types"), this is NOT a current-phase OCP violation. Flagging it as "too narrow" misreads the design intent. The correct assessment is: the interface is phase-1 correct by design; measure the temporal cost of expanding it at the next feature boundary, not the OCP violation today.

**Heuristic**: Before flagging a narrow interface as a Medium extensibility finding, check: (a) does the interface XML doc or surrounding code comment explain the narrowness? (b) is the narrowness a security or API-stability decision rather than an oversight? If yes to both, shift the finding to: "What must be added when the next feature arrives, and how large is the blast radius?" If the blast radius is one implementation + a few tests, rate as Medium/Watch rather than Medium/Fix-Now.

**Corollary**: The security reason for narrowness may still create a future interface-breaking change (any implementor must add the new member). That is worth flagging — but the severity should reflect the actual blast radius (number of implementors and their test helpers), not the theoretical one.

---

## 2026-05-28 — Convergent Medium Findings at a Known Feature Boundary: Group as a Pair

**Category**: Process/Model
**Finding**: When two or more medium extensibility gaps share the same trigger — both will be addressed by the same planned upcoming feature — they are cheaper to fix together than separately. Flagging them as independent "fix sometime" Medium findings misrepresents the action cost. The better recommendation is: identify the shared trigger event, note both gaps, and recommend addressing them in the same PR at that trigger.

**Heuristic**: When two medium findings arise in the same feature area and one of them involves an interface expansion that the other one's feature will also need, look for the convergence explicitly. If both gaps unlock at the same next-feature event: (a) flag both individually with severity, (b) add a cross-reference note ("Fix together with EXT-XX at the same feature boundary"), and (c) recommend which one — if any — is cheaper to pre-empt now while implementation context is loaded.

**Corollary**: Convergent findings often indicate that the "current phase" design was correct all along — the two gaps are a natural consequence of phased delivery, not a design oversight. Framing them as "phase-1 appropriate, converge at phase-2" is more accurate and more useful to the reader than framing them as "two separate OCP violations."

---

## 2026-05-22 — Incomplete DI Consolidation: Missed Host Contexts Are High-Severity Drift Surfaces

**Category**: Process/Model
**Finding**: When a DI consolidation refactor introduces per-layer `Container.cs` modules but does not migrate all host entry points (e.g., a MAUI or WPF host is left with inline registrations), the unmigrated host is a high-severity extensibility gap. Every new service added to the consolidated module must also be manually added to the unmigrated host — creating a live drift surface that is invisible to code reviewers who only inspect the `Container.cs` files. Silent behavioral divergence is the most dangerous outcome: missing gate-chain or pipeline registrations may produce wrong behavior (e.g., all tasks approved unconditionally) with no build or test failure.

**Heuristic**: When reviewing a DI consolidation, enumerate every host entry point in the solution (`*Program.cs`, `*MauiProgram.cs`, `*App.xaml.cs`, any startup class). For each one, verify it calls the consolidated module rather than hand-wiring registrations. Flag any unmigrated host as **High** — not Medium — because: (a) it produces silent behavioral divergence, not just code duplication, and (b) the divergence compounds with every future service addition.

**Corollary**: The correctness finding (missing service at runtime) and the extensibility finding (manual sync required for every future addition) are distinct but co-located. File both. The extensibility finding is often more impactful long-term even when the correctness gap is more urgent.

---

## 2026-05-19 — Positional Record as Event Payload: Severity Depends on Who Constructs It

**Category**: Process/Model
**Finding**: When a `sealed record` type uses positional syntax and serves as an event/notification payload (e.g., a toast notification record fired through a service event), the extensibility risk of adding optional fields is **lower than it appears** if the record is only ever constructed through a single factory method (e.g., a `private void Fire(string, Level)` helper). Adding an optional positional parameter at the end of the constructor (with a default value) is non-breaking for that one factory site. Rate this **Low** if construction is encapsulated behind a private factory; rate it **Medium** if callers construct the record directly across multiple projects or in test code.

**Heuristic**: Before citing "breaking constructor change" for a positional record, check: (a) how many distinct call sites construct the record directly, and (b) whether all construction goes through a factory method. If all construction flows through one factory, the extension cost is ~1 line. The finding is still valid (init-based records are more ergonomic for optional-field growth), but the severity must reflect the actual blast radius, not the theoretical one.

**Corollary**: The recommendation to convert to `init`-based properties is still sound for ergonomic reasons (enables `new T { Field = x }` object initializer syntax, which is more readable for records with many optional fields). But frame it as an ergonomics improvement rather than a blocking extensibility risk when the factory pattern already exists.

---

## 2026-05-19 — Dirty-Tracking via `ToModel()` Serialization: Silent Omission Is a Reliable Medium Finding

**Category**: Process/Model
**Finding**: When a ViewModel's dirty-tracking mechanism works by calling `ToModel()` (a projection to the data model type) and serializing the result, any data model field that is NOT mapped in `ToModel()` is silently excluded from change detection. The Save button stays disabled while the user edits the excluded field, and the change is lost on reload. There is no compiler error, no runtime exception, and no obvious test to write — the omission is invisible. This is a reliable **Medium** finding when: (a) the data model is expected to grow new fields, and (b) there is no test that asserts complete field coverage. Rate as **Low** only if the model is explicitly frozen (e.g., a DTO from an external API with no roadmap additions).

**Heuristic**: When you see dirty-tracking via serialization of `ToModel()` output, always compare the set of `[ObservableProperty]` fields on the ViewModel against the set of serializable properties on the data model type. Any ViewModel field that does not appear in `ToModel()` is either transient UI state (correct — not a finding) or a missing field (incorrect — a finding). Distinguish between the two by asking: "Would a user expect changes to this field to be saved?"

**Recommended fix pattern**: A reflection-based unit test that asserts `typeof(DataModel).GetProperties(BindingFlags.Public | BindingFlags.Instance).All(p => json.Contains(p.Name))` where `json` is the output of `viewModel.ToModel()` serialized with the same options as the dirty tracker. This turns silent omission into a CI failure.

---

## 2026-05-26 — Typed Binary Dispatcher with N Call Sites: High Finding When N > 5

**Category**: Process/Model
**Finding**: When a class contains a private generic dispatch method that accepts exactly two typed handlers
(`Func<ITypeA, T> handlerA`, `Func<ITypeB, T> handlerB`) and is called N times within the same class,
adding a third type requires changing the method signature AND all N call sites simultaneously. When N > 5,
this is a reliable **High** extensibility finding: the change surface is so broad that any new type
addition is a multi-file, multi-site coordinated change. When N ≤ 5, rate as Medium.

**Heuristic**: Count all call sites of the dispatch method. If the dispatch signature is binary (two handler
parameters), flag as High when N > 5. The fix pattern is: either push the formula into the type via an
interface method (`ITypeA.ComputeProperty()`, `ITypeB.ComputeProperty()`) so the dispatcher is eliminated
entirely, or replace the binary handler pair with a type-keyed registry (`Dictionary<Type, Func<IMaterial, T>>`).

**Corollary**: The binary dispatch pattern is often introduced as a clean one-time refactor ("this is cleaner
than two separate if branches"). It stays clean until the third type. Call it out before the third type
arrives — the fix is cheapest when there are only two types, since both handlers can be migrated to their
respective type implementations in a single PR.

---

## 2026-05-26 — Parameter Type Mismatch Between Factory and Dispatcher Creates a Bypass Architecture

**Category**: Process/Model
**Finding**: When a factory interface adds a new method with a different parameter type than an existing
dispatcher/retriever that routes to the factory (e.g., factory method takes `IPlateType` but the existing
dispatcher takes `IAngleType`), the dispatcher cannot uniformly route all types through its own interface.
The caller of the dispatcher must then bypass it for the new type, calling the factory directly. This
creates a "split calling convention": some types go through the dispatcher, others bypass it. This is a
reliable **Medium** finding when:
1. The bypass is not documented with a clear architectural rationale, OR
2. The dispatcher is a public interface (meaning future callers would need to know the bypass rule)

**Heuristic**: Search for cases where a class injects both a factory and a dispatcher/retriever for the same
concept (e.g., `ICompositeMaterialFactory` AND `ICombinedSectionMaterialRetriever`). If the class has a
switch/conditional that calls one or the other based on a type or enum value, the split convention already
exists. Rate as Medium unless the split is documented with a clear invariant.

**Corollary**: The fix is either (a) extend the dispatcher interface to accommodate the new parameter type
(e.g., via an overload), or (b) explicitly document the bypass as a contract in the dispatcher interface
with an XML comment explaining which types bypass it and why.

---

## 2026-05-19 — Private Static Strategy Methods Inside Services: Reliable Medium for Testability+Extensibility

**Category**: Process/Model
**Finding**: When a service class contains a `private static bool SomeStrategy(T candidate, T existing)` method that implements a named, documented replacement rule (e.g., "timestamp-wins merge"), the method is both untestable in isolation and non-swappable without editing the service body. This is a reliable **Medium** finding when the strategy is documented as a deliberate policy choice (implying future policy variation is plausible). The fix is always the same: extract the strategy as a `Func<T, T, bool>` delegate parameter with a default value pointing to the private static — zero behavior change, full testability.

**Heuristic**: In any service that has a private static method with a name like `IsMoreRecent*`, `ShouldReplace*`, `HasPriority*`, or `CompareFor*`, ask: (a) is this strategy documented as a specific named policy? (b) could the policy change based on context? If yes to both, flag as Medium. The delegate default pattern is the lowest-cost fix — it preserves backward compatibility and enables both unit testing and future injection.

**Corollary**: `private static` is correct for helper methods that have no policy semantics (formatting, parsing, null-checks). Reserve the Medium finding for methods whose name implies a deliberate choice among alternatives.

---

## 2026-05-18 — `ObservableCollection<T>` in a ViewModel Interface Is a Reliable Medium Finding

**Category**: Process/Model
**Finding**: When a ViewModel interface declares `ObservableCollection<ConcreteViewModel> Items { get; }`, any mock or alternate implementation must provide the full `ObservableCollection<T>` infrastructure — there is no `IObservableCollection<T>` in .NET. The finding is **Medium** (not High) because: (a) `ObservableCollection<T>` is the de-facto standard for MVVM collections and most test code can construct one trivially; (b) the coupling is in the collection type, not the element type. Elevate to High only if the concrete element type (`ConcreteViewModel`) also lacks an interface and has non-trivial behavior that test doubles would need to vary.

**Heuristic**: In any ViewModel interface, any property that returns a concrete mutable type (`Dictionary<K,V>`, `ObservableCollection<T>`, `List<T>`) is a coupling finding. Prefer `IReadOnlyDictionary`, `IReadOnlyList`, or at least expose a read-only view. `Dictionary<K,V>` returning mutable is the higher-severity of the two because callers can write to the internal state without going through the ViewModel.

---

## 2026-05-16 — Service Interface Signature Is the Most Impactful Extensibility Check for Roadmap Features

**Category**: Process/Model
**Finding**: When the requirements audit has identified planned features with new data access patterns (e.g., round-aware queries, per-user aggregations, new write operations), the most impactful extensibility check is: does the current service interface signature accommodate the parameters those features will require? An interface method missing a `currentRound`, `userId`, or similar required parameter is a Medium extensibility blocker — not a Low — because changing an interface signature cascades to every caller and both DI registrations (or more, in multi-host architectures). The finding is especially actionable early: there is typically only one implementation and a handful of call sites, making the fix cheap now and expensive later.

**Heuristic**: For each planned feature identified in the requirements audit, ask: "What parameters would a new or modified service method need?" Compare that against the current interface. If a required parameter is absent, flag the interface as incompatible with that feature at Medium severity (dev tool) or High (production service).

---

## 2026-05-16 — Data Model Granularity Mismatch Is a Compounding Extensibility Risk

**Category**: Process/Model
**Finding**: When a data model carries a single instance of a type (e.g., `Result: ResultEntry` on an aggregate item) but the roadmap plans to expand it to multiple instances (e.g., one result entry per sub-item), this is not just a correctness defect — it's an extensibility risk that compounds. Every UI feature built on top of the single-instance model must be refactored when the model is corrected. The earlier the mismatch is caught, the lower the refactor cost. Always check: does the granularity of the data returned by the service match the granularity that planned features will need? If the answer is "planned features need finer granularity than the current model provides," flag as Medium and recommend the model change before UI build-out continues.

**Heuristic**: Look for fields like `SomeItem Item { get; set; }` (singular) on a container where the requirements audit describes a future state of `List<SomeItem> Items { get; set; }` (plural). The singular field is the signal. The severity depends on how much UI is already built on top of it.

---

## 2026-05-18 — Enum-as-Gate-Registry Is a Reliable High Finding

**Category**: Process/Model
**Finding**: When an interface has a `Name` (or `Kind`, or `Type`) property typed as an enum (e.g., `IExtensionPoint.Kind => ExtensionPointKind`), that enum is a closed registry in the core library. Every new implementation of the interface requires a core library change, violating OCP. This is a reliable **High** finding. The fix is always the same: replace the enum type with `string` and provide a constants class for well-known values.

**Heuristic**: Any interface where a property returns an enum that represents "which kind am I" (registry pattern) is a candidate for this finding. Contrast with enums that represent *state* (valid) vs enums that represent *identity* (risky).

---

## 2026-05-18 — CLI Top-Level Statement Files Hide Extensibility Debt

**Category**: Process/Model
**Finding**: C# top-level statement `Program.cs` files that grow beyond ~300 lines with embedded local factory functions (`CreateSvc()`, `CreateDocSvc()`) are reliable signals of extensibility debt. The local factory functions serve as ad-hoc composition roots without DI. Each new service with complex dependencies requires a new factory function, and the file becomes a modification hotspot for every feature. Flag as **High** when the factory functions construct service dependencies with more than 2–3 levels of nesting, or when the file contains domain logic (MIME maps, switch statements on enum values) rather than only wiring.

**Heuristic**: Count the number of local `Create*()` functions. If > 3, recommend a DI container. If the file contains any `switch` on an enum value that would need editing when new enum values are added, flag the specific switch.

---

## 2026-05-18 — `Enum.TryParse` Is the Fix for Closed Switch-on-Status Patterns

**Category**: Process/Model
**Finding**: When a CLI command maps a string arg to an enum value via a `switch` (e.g., `"pending" => EntityStatus.Pending`), any new enum value is silently unhandled (falls through to default). This is always a Medium finding. The fix is always one line: `Enum.TryParse<TEnum>(value, ignoreCase: true, out var parsed)`. Flag every such pattern — it is a consistent one-line fix with high forward-extensibility value.

**Corollary**: The silent fallback to "return all" or "use default" is technically functional but behaviorally incorrect — callers expecting an empty result for an invalid filter get all results instead. Mention this behavioral inconsistency alongside the extensibility finding.

---

## 2026-05-18 — "Built But Not Wired" Infrastructure Is Critical, Not Dead Code

**Category**: Process/Model
**Finding**: When a project contains fully implemented infrastructure (dispatch loop, strategy resolver, coordinator) that is never activated via any command or entry point, this is a **Critical** extensibility finding — not a dead code warning. The extension points are real and well-designed, but dormant. Frame it as: "The extension point exists and is correct; the activation mechanism is missing." Recommend adding the entry point rather than removing the infrastructure.

**Heuristic**: Before flagging any class as dead code, check whether it is referenced transitively by any other class in the same project. Only flag as truly dead if no class ever instantiates it. If it has interfaces, constructors, and tests — it was designed to be used.

---

## 2026-05-16 — Define Platform-Specific Service Seams Before the Feature, Not During It

**Category**: Process/Model
**Finding**: In a multi-host architecture (Desktop + Web, or Desktop + MAUI + Web), some planned features will need behavior that differs per host (e.g., "open file in system default handler" works on Desktop, not on Web). When the requirements audit identifies such features and no interface seam yet exists for the platform-specific operation, flag it as Medium at review time — not Low. The cost of defining the seam now (one interface + two null/real implementations) is near-zero. The cost of defining it mid-feature under schedule pressure is higher, and the risk of an incomplete seam (e.g., no `IsSupported` guard, no web no-op) breaks the alternative host. The check: does every planned platform-divergent feature have a corresponding `IXxxService` in the Core project?

---

## 2026-05-16 — Positional C# Records Used as Pipeline Output DTOs Are Frozen Extensibility Anti-Patterns

**Category**: Process/Model
**Finding**: When a C# positional record is used as the output type of a multi-step pipeline (e.g., an eligibility evaluation result, a validation summary, a scoring breakdown), every named parameter in the positional list becomes a breaking change surface. Adding a new pipeline gate/layer requires changing the record's parameter list, which breaks every call site that constructs or destructures the record. This is a High extensibility issue — not Medium — when: (a) the pipeline is actively evolving with more gates planned, and (b) the record is returned by a service interface consumed across multiple projects.

**Heuristic**: Look for records with more than three named non-primitive positional parameters, especially when those parameters represent "categories" or "gates" of the same concept (e.g., five `LayerResult` fields named by check type). Any time a reader of the record would have to add a new same-typed field to extend the pipeline, the design is frozen. The fix is to replace fixed named fields with a dictionary or list, using constants for named access.

**Corollary**: Distinguish between a positional record used as a simple data carrier (fine — adding fields is additive) vs. a positional record used as a categorized summary of pipeline results (problematic — each category is a positional parameter that breaks callers).

---

## 2026-05-16 — Strategy Pattern With Partial Extension Points Is a Reliable High-Severity Finding

**Category**: Process/Model
**Finding**: When a strategy interface provides one extension hook (e.g., `GetManifestMetadata()` for metadata customization) but not a parallel hook for an adjacent concern (e.g., prompt template, output format, completion signal), the "partial extension" is a reliable High finding. The pattern signals that the design was started correctly but not completed. The consequence is that the builder/orchestrator must hard-code the unhooked concern for all strategies, creating an OCP violation at the builder layer even while the strategy layer itself is correctly open.

**Heuristic**: For every customization hook on a strategy interface, ask: "What other aspects of the operation could legitimately differ per strategy?" If the answer includes something the builder currently hard-codes, that is a missing extension point at High severity (if the variation is imminent) or Medium (if it's speculative). The fix is symmetric: add a `GetX()` method parallel to the existing `GetManifestMetadata()` pattern.

---

## 2026-05-12 — Always Check `AddSingleton` Registrations for Global State When Multi-Tenant/Multi-Board Is Planned

**Category**: Process/Model
**Finding**: When a planned roadmap item includes multi-user, multi-board, or multi-tenant support, the first place to look for Critical extensibility blockers is the DI registration list — specifically any `AddSingleton` service that holds mutable state. A singleton that stores a "current board", "current user", or "current tenant" is architecturally incompatible with multiple concurrent users. The code that reads from the singleton looks correct in isolation, but every caller is implicitly sharing the same state. Flagging this as Critical (not High) is correct when: (a) the planned feature explicitly requires per-user isolation, and (b) every query in the application passes through the singleton to get its board/tenant scope.

**Heuristic**: In `Program.cs` (or `Startup.cs`), search for `AddSingleton` and examine each registration. For each one, ask: "Would two concurrent users get different results from this service?" If yes and multi-user is planned, it's Critical.

---

## 2026-05-12 — Request/DTO Record Field Comparison Is a Reliable Extensibility Check

**Category**: Process/Model
**Finding**: When an entity has a FK column (e.g., `OwnerId`, `ScopeId`) but the corresponding request/DTO record does not include that field, new objects can never be assigned that relationship through the normal API surface. The service's `AddAsync` method will never set the field. The data arrives unassigned and must be backfilled externally. This is a Low-to-Medium extensibility finding (exact severity depends on how soon the FK is needed) that is easy to miss because the entity and the request look correct in isolation. Always compare FK fields between entity and request records as a checklist step.

---

## 2026-05-08 — `Enum.GetValues<T>()` in UI Is an Accurate Signal of Open Extension Points

**Category**: Process/Model
**Finding**: When reviewing enum-backed UI controls, check whether buttons/options are rendered via `Enum.GetValues<T>()` or via hard-coded element-per-value markup. `Enum.GetValues<T>()` is a genuine open extension point — adding an enum value automatically surfaces in the UI with zero code changes. Hard-coded per-value markup is a closed pattern. The two look similar at a glance; distinguish them before reporting extensibility findings for form controls.

**Pattern**: This distinction can produce false positives if you assess "effort to add a horizon value" as "High" without checking the form component. Always check both the consuming form/component AND the business logic (inference, scoring) separately — the UI may be open while the business logic is closed, or vice versa. Report both facts in the finding with separate impact lines.

---

## 2026-05-08 — Duplicate Display Metadata in Multiple View Components Is a Reliable High-Value Finding

**Category**: Process/Model
**Finding**: When the same enum-to-CSS-class and enum-to-label mappings appear independently in multiple view components, always flag this as a Medium finding even if each individual occurrence is trivially small. The duplicated static method pattern compounds: each new view component independently re-authors the same mappings, and divergence between them becomes a source of subtle UI inconsistencies. A shared static display-metadata utility eliminates the multiplication.

**Heuristic**: Search for the string `switch` in view code-behind files (`*.razor.cs`). If you find the same enum being switched for a style/label result in more than one file, flag the duplication and recommend a shared utility.

---

## 2026-05-13 — Dev Tool Tier Requires Lower Severity Calibration Than Production

**Category**: Process/Model
**Finding**: When the code under review is a developer-only tool (DevTools project, default-off toggle, never registered in production DI), apply a lower severity baseline than for production code. Patterns that would be Medium in production are Low in a dev tool; patterns that would be High are Medium at most. The key question is: "What is the actual cost if this needs to change?" For a dev tool used locally by a handful of engineers, modifying the code is trivial — there is no deployment, no API contract, no concurrent users.

**Heuristic**: Ask "Is this in a DevTools project, behind a default-off toggle, and never referenced by production assemblies?" If yes, apply the severity downgrade. If the pattern also lives in the shared Framework layer (e.g., `FlowRunner`), evaluate that layer at production severity — the framework is reused broadly.

**Corollary**: Do NOT flag missing abstractions in dev tools as High extensibility issues. A `bool` mode selector on a dev tool's constructor is Low, not Medium, unless a third mode is actively planned or the flag also appears in a production class.

---

## 2026-05-14 — Domain-Constrained Binary Parameters Are Low Severity, Not Medium

**Category**: Process/Model
**Finding**: The existing lesson about `bool` parameters says "Medium when a method has exactly two states and a third variant is plausible in the domain context." The key qualifier is **domain context**. When a `bool` encodes a **physical or domain-structural concept** where exactly two values are legally possible (e.g., left end / right end of a physical member, primary pass / secondary pass of an operation), rate it as **Low**, not Medium. The "plausibility of a third variant" test fails when the domain itself constrains the cardinality to two.

**Contrast**: A `bool useSecondaryStrategy` that selects between two calculation strategies IS plausibly extensible to three strategies — rate that Medium. A `bool isSecondSide` on a factory for a component that by definition has exactly two sides is NOT plausibly extensible — rate that Low, with a note that an enum would improve readability without changing the severity assessment.

**Heuristic**: Before assigning Medium for a bool parameter, ask: "Is there a structural, physical, or contractual reason this can only ever be two values?" If yes, downgrade to Low.



**Date**: 2026-04-28
**Category**: Process/Model

When a private method on a resolver/calculator accepts a `bool` parameter that selects between two fundamentally different fallback or strategy paths (e.g., `bool useLegacyFallback`), treat it as a Medium extensibility finding. The flag signals that the method is doing two different jobs unified by a boolean rather than by abstraction. The correct severity is Medium (not Low) when the method has exactly two states and a third variant is plausible in the domain context. The correct recommendation is a `Func<...>` strategy parameter or two separate methods, not an enum — enums require modification too. Only escalate to High if a third variant is explicitly planned or if the boolean selects between behaviors with different correctness consequences (not just different fallback values).

---

## Entry: C# Default Interface Members — Overrides Dispatch Correctly Through Interface References

**Date**: 2026-04-22
**Category**: Process/Model

When a C# 8+ interface uses default property/method implementations that `new` up concrete types, those defaults CAN be overridden in implementing classes — and the override WILL be called as long as the consumer holds an interface reference (not a concrete reference). Do NOT flag this pattern as "defaults are not overridable" or "tightly coupled to concrete types at the interface level" when the calling code uses the interface reference. The extension point is real and functional. Severity should not exceed Low unless the implementing class is also `sealed` and no alternative implementation path exists.

---

## 2026-04-22 — Feature Toggle Severity Depends on Toggle Lifetime

**Category**: Process/Model
**Finding**: When auditing toggle-duplicated dispatch logic, check the application's shared configuration file (or the equivalent default configuration file for the deployment environment) to determine whether a feature toggle is a **temporary safe-release flag** or a **long-lived opt-in flag**. A toggle set to `"Off"` globally with no documented retirement plan is permanent. Permanent toggle duplication should be rated High severity; temporary safe-release toggles are Medium. The two look identical in code — only the config file reveals intent.

**Pattern**: Search for the toggle name in the app settings file early in the review. If the toggle is "Off" in shared/production settings, treat the duplication as long-lived.

---

## 2026-04-24 — Dual-Track Enum Mapping Creates Silent Divergence Risk

**Category**: Process/Model
**Finding**: When a codebase has two independent code paths that both map the same enum (e.g., old-path switch statement, new-path attribute-based lookup), adding a new enum value will silently break only the path that uses the switch. The failure mode is not an exception — the switch falls to `default → null` and skips the affected behavior. This is an extensibility risk that is easy to miss because the two paths are often in different files and activated by different conditions.

**Heuristic**: When you find a switch statement that maps one enum to another, search for alternative mapping approaches for the same enum pair elsewhere in the codebase. If they coexist, flag the switch as "closed for extension" at High severity and recommend a shared utility.

---

## 2026-05-06 — Co-Required Step Pairs Without Structural Enforcement Are Medium Extensibility Findings

**Category**: Process/Model

When two flow steps must always appear in sequence (e.g., StepA followed immediately by StepB), and the framework provides no mechanism (base class, template method, composed sub-flow, or compile-time constraint) to enforce co-occurrence, rate this as Medium severity. The correct recommendation is either: (a) compose the pair into a single named unit so consumers reference one thing, or (b) add a prominent comment at the declaration site of the first step stating the required pairing. Do NOT rate this as Low simply because the pattern has been correctly applied so far — the risk is additive: each new call site is an independent opportunity for omission. Escalate to High only if the pair must appear in a hot path where an omission produces a silent wrong-answer defect with no exception signal (i.e., a bug exactly like the one the PR was fixing).

---

## 2026-05-12 — Template Method FlowDecision Subclasses Are Not Tight-Coupling Issues

**Category**: Process/Model

When a codebase uses an abstract template-method decision base class with a single `Decide(TContext)` override as the primary extension mechanism, concrete subclasses that read all state from the shared context object (no injected dependencies) are idiomatic — **do not flag them as tight-coupling**. The context object is the intentional single dependency for all decision steps. Similarly, registration of parameterless decision classes directly instantiated in a constructor (when the class has no service dependencies) is the correct pattern for this template-method design, not a DI violation.

Also: when an `internal interface` gains a new property (the standard extensibility step in this pattern), the blast radius is bounded to one assembly. Do not report this as a "breaking API change" — it is specifically not that when the interface is internal.

---

## 2026-05-12 — Asymmetric Features Between Sibling Classes Are Usually Intentional

**Category**: Process/Model

When sibling classes (e.g., two processor variants for the two sides of a physical or logical pair) have different capabilities — one has a guard, the other does not — verify the business reason before flagging as a DRY violation or extensibility gap. Domain context frequently justifies asymmetry: if the skip condition is driven by a concern that genuinely only applies to one of the siblings, separate implementations are the correct design. Always check the requirements-audit for the business reason before rating asymmetry at Medium or above.

---

## 2026-04-24 — Two-Toggle Mutual Exclusivity Invariants Need Explicit Documentation

**Category**: Process/Model
**Finding**: When a new toggle is introduced to replace an older one (new mechanism supersedes old mechanism), and the old mechanism has a bypass that prevents double-application, the bypass code has a hidden invariant: "the bypass must remain as long as both toggles can be independently on." This is a **toggle retirement trap**. After the new toggle is promoted, the bypass looks like dead code — but it is not. Removing it silently reintroduces the original defect.

**Pattern**: When auditing two overlapping toggles, check:
1. Is there a bypass in the old code path that references the new toggle by name?
2. Is the bypass's purpose to prevent double-application?
3. Is there a test that verifies the bypass?

If (3) is missing, flag High. If (2) is present with no retirement comment, recommend adding a `// RETIREMENT NOTE` comment at the bypass site.

---

## 2026-04-29 — Exclusion-Accumulation Naming on Public Interfaces Is a Medium Finding

**Category**: Process/Model
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

**Category**: Process/Model
**Finding**: An optional toggle parameter with a null default (`IToggles? toggles = null`) is a backward-compatibility shim that becomes a liability as more toggle-gated features use the same method. Any caller that omits the parameter silently opts out of all toggle-gated behavior — not just the original one. The failure mode is incorrect results (not exceptions), making it hard to diagnose.

**Pattern**: Flag `IToggles? toggles = null` as a Medium finding when it appears on a method that has more than one toggle-gated branch. The recommendation should be to make the parameter required and provide an explicit "all-off" value for callers that need legacy behavior.

---

## 2026-05-23 — `file`-Scoped Test Helper Classes Are a Reliable Medium Finding When Time-Control Is the Pattern

**Category**: Process/Model
**Finding**: When a test file defines a helper type (e.g., a `TimeProvider` subclass, a custom comparer, a fake scheduler) using the C# `file` access modifier, that helper is invisible outside the declaring compilation unit. If the test project will grow new test classes that need the same time-control capability — which is almost always true when the first class needs it — the `file` scope creates inevitable duplication. Each additional test file either re-defines the class under a new local name or invents a different approach, producing inconsistency across the test suite.

**Heuristic**: When a test helper class has the `file` modifier and implements a replaceable dependency (e.g., `TimeProvider`, `IScheduler`, `IRandom`), flag as Medium. Check whether the project already has or references a package providing the same capability (e.g., `Microsoft.Extensions.TimeProvider.Testing`). If the package exists in the shared test infrastructure project but is not referenced by the current test project, that is the fix: add the package reference and remove the `file` modifier (or delete the local class entirely). If no shared package exists, promote the class to a non-`file` internal helper in a `TestHelpers/` or `Fakes/` folder.

**Severity calibration**: Medium is correct when the first duplication has not yet occurred. Downgrade to Low only if the helper is inherently test-class-specific and could not logically be shared (e.g., a `file` class that captures private state from the declaring fixture). Keep at Medium when the class wraps a replaceable system dependency.

**Corollary**: The `file` modifier is a good tool for truly test-local types (e.g., a named data record used only in one `[TestCase]` set). Reserve the Medium finding for types that implement interfaces or base classes representing replaceable system collaborators.

---

## 2026-05-23 — Hand-Rolled Mock `IServiceProvider` Is a Medium Finding in Unit Test Infrastructure

**Category**: Process/Model
**Finding**: When a test helper mocks `IServiceProvider` via a mocking framework (e.g., `new Mock<IServiceProvider>()` with `.Setup(sp => sp.GetService(typeof(T))).Returns(mock.Object)` for each service), only the explicitly wired services are reachable. Any new service dependency added to the code under test falls through to `null` — which `GetRequiredService<T>()` converts to `InvalidOperationException` rather than a build error. The failure is a runtime test failure, not a compile error, so the missing registration is discovered at test run time rather than at dependency introduction time.

**Heuristic**: In any test infrastructure file, if you see `Mock<IServiceProvider>` or `Mock<IServiceScopeFactory>` with hand-written `Setup` chains for each service, flag as Medium. The fix is to replace the mock chain with a real `ServiceCollection`/`BuildServiceProvider()` populated with `Mock<T>.Object` instances. This is the pattern already used by the integration test infrastructure (`TestServiceProvider.Create()`) and is equally appropriate for unit test helpers. With a real `ServiceProvider`, `GetRequiredService<T>()` throws a descriptive, immediately actionable error for any unregistered service, and adding a new handler dependency requires exactly one new `services.AddSingleton(newMock.Object)` line.

**Severity calibration**: Medium (not High) because the current wired services work correctly and the test suite runs clean. The failure mode (silent `null` return for new services) only manifests after a code change, not during stable periods. Elevate to High if the project is actively adding new service dependencies to the code under test and the mock infrastructure is a recurring maintenance cost.

**Corollary**: Do NOT flag `Mock<IServiceProvider>` as High extensibility when the set of wired services is documented and stable. The finding's severity is proportional to how often new service dependencies are introduced.

---

## 2026-05-30 — Static Pure-Logic Class Without Interface Seam: Reliable Medium Finding

**Category**: Process/Model
**Finding**: When a pure, stateless logic class is implemented as a `static` class (no instance, no DI), it creates a hard compile-time dependency in every caller. Callers cannot substitute a test double, apply a decorator, or change the projection algorithm at runtime. The failure mode is deferred: the class is simple today, but when cross-cutting concerns arrive (audit logging, telemetry, conditional logic that needs injected dependencies), the static class must either grow with new static parameters (threading dependencies manually) or be refactored into an injectable instance. The refactor surface grows proportionally with the number of callers.

**Heuristic**: When a `static` utility class is called from a service-layer class that itself participates in DI, flag as **Medium** if: (a) the class contains any domain logic beyond pure data transformation, or (b) the calling service is part of a feature area where cross-cutting extensions (audit, telemetry, conditional behavior) are plausible. The fix is always: extract a single-method interface, convert the class to a non-static `sealed` implementation, register as `Singleton` (stateless = thread-safe), update call sites. Existing tests of the concrete class require no changes.

**Severity calibration**: Keep at Medium when the class is small and the feature area is stable. Elevate to High when multiple callers have already hardcoded the static call — each caller is a refactor touch point. Keep at Low only if the class is a pure math/string utility with zero domain coupling and no realistic need for behavioral variation.

**Corollary**: A `static` class that lives alongside a non-static `IXxx` interface in the same feature area is a strong signal that the static class is an oversight — the project already established the injectable-interface pattern for the sister component. Use the existing interface pattern as the concrete fix example in the recommendation.

---

## 2026-05-30 — Create/Edit Workflow Asymmetry: Blast Radius Is Larger Than Just the Apply Method

**Category**: Process/Model
**Finding**: When a service's "create" method accepts a parameter that the corresponding "prepare/apply edit" workflow does not, the correctness audit typically flags only the `ApplyEditAsync` method as the incomplete path. But the actual blast radius for extending the edit workflow is consistently larger:
1. The **prepare** method must also accept the new parameter (or derive it from existing state)
2. The **session/DTO type** returned by prepare must gain new fields to carry the new parameter through the UI flow
3. The **apply** method must accept the parameter
4. The **implementation** must process it
5. Any **consumers** that construct or bind the session type (ViewModels, controllers) must update

**Heuristic**: When the correctness audit flags `ApplyEditAsync` (or any `CommitEditAsync`-style method) as incomplete for a new parameter, immediately check whether the corresponding `PrepareEditAsync` (or `BeginEditAsync`) method and its returned session/DTO type are also unaware of the new parameter. If so, add both to the extensibility finding — not just apply. The prepare method and session type are structurally linked: the session carries data from prepare to apply, so a parameter that isn't in prepare cannot arrive in apply through the normal workflow.

**Severity calibration**: High when the prepare/apply/session triple is all unaware and a concrete planned UI slice will require the complete extension. Medium when the gap is documented as intentional phase deferral and no UI slice is imminent.

**Corollary**: The recommendation should explicitly list all five touch points and suggest adding a code comment to the interface's apply method identifying the full set, so the next developer picking up the UI slice does not discover the other touch points by runtime failure.

---

## 2026-05-30 — Authorization Result `string` Field Conflating Machine-Readable and Human-Readable Content: Reliable High Finding

**Category**: Process/Model
**Finding**: When an authorization result type carries a single `string?` field used for two purposes — (a) a machine-readable constant (e.g., a permission identifier string) that downstream UI consumers branch on, and (b) human-readable prose messages that explain configuration errors — this is a reliable **High** extensibility finding. UI consumers must `string.Equals` against known constants to determine which denial category they are in, creating silent coupling to internal string values. Any message rewording, any new denial category, or any new permission identifier breaks the consumers silently — no compiler error, no test failure unless the tests assert on the exact strings.

**Heuristic**: When reviewing an authorization or validation result type, check whether `DenialReason`, `ErrorMessage`, or equivalent field is used for both: (a) values the UI switches on (permission constants, error codes), and (b) display-only prose. If yes, flag as **High** and recommend a discriminant enum (`DenialKind`, `ErrorCategory`, or equivalent) alongside the string field. The fix is additive: the `string?` field is preserved for display text; the new enum property carries the machine-readable category.

**Severity calibration**: High (not Medium) when: (a) any downstream consumer already performs string comparison to determine denial category, OR (b) the result type is returned across a service interface consumed in multiple projects. Medium when the result type is strictly internal and no downstream consumer branches on its string value yet.

**Corollary**: The fix is always non-breaking: add the discriminant enum as a new nullable property alongside the existing string field. Existing callers that only read the string for display are unaffected. Callers that were previously doing string comparisons are migrated to the enum at their own pace under compiler deprecation. The static factory methods (`Allow()`, `Deny(reason)`) should be updated to set the new property — this is the only mandatory change site.

---

## 2026-05-31 — Copy-Pasted Security Guard in Multiple Method Bodies: Reliable High Finding

**Category**: Process/Model
**Finding**: When a service interface has multiple mutating methods and each one contains an independently inlined copy of the same security guard (fetch entity → check ownership → log + throw on mismatch), this is a reliable **High** extensibility finding. The guard is opt-in: a developer adding a new method must know to follow the pattern and reproduce each step correctly (correct parameter name, correct log fields, correct exception message). If any step is skipped or slightly wrong (e.g., the exception message differs from the not-found message, leaking existence), the build is green, all existing tests pass, and the new method is silently exploitable.

**Heuristic**: When reviewing a service implementation: (a) count the distinct mutating methods, (b) grep for the guard pattern (a conditional check against a resource's owner field followed by a log statement and throw). If the same pattern appears in 3+ method bodies verbatim or near-verbatim, this is a High finding regardless of correctness. The fix is always a private `VerifyOwnershipAsync`-style helper that encodes the guard once. Each guarded method then calls the helper — one line, impossible to forget a step.

**Severity calibration**: High (not Medium) because: (a) the failure mode for omission is a security vulnerability (unguarded write path), not a quality issue; (b) each future method added to the interface is an independent opportunity for omission; and (c) future cross-cutting concerns on the guard path (rate limiting, security event bus) require shotgun surgery across all methods without the helper.

**Corollary**: The co-occurring extensibility gap is the absence of a decorator seam for cross-cutting guard concerns. If the service is already exposed via an interface, note that a decorator can wrap the interface without touching the concrete service — this is the path for adding rate limiting, event emission, and metrics to the guard path. Both the helper refactoring (internal) and the decorator opportunity (external) should be called out together.

**False positive guard**: Do NOT elevate to Critical if the guard is currently correct — the finding is about future extensibility risk, not present incorrectness. The three existing methods are guarded correctly; the finding is that the fourth (and fifth, and sixth) methods are unprotected by default.

---

## 2026-06-02 — `internal static` Pure Classifier Function Is NOT a Medium Extensibility Finding

**Category**: Process/Model
**Finding**: When a component contains an `internal static bool` method that classifies a string, enum, or simple value with no dependencies (no injected services, no I/O, no async), the `static` accessor is the **correct** design — not an extensibility gap. Flagging it as Medium ("no injection seam") is a false positive. The `internal static` signature enables direct unit test invocation without any DI scaffolding, component lifecycle, or test doubles. This is a better testability model than an injected interface for a pure function with no dependencies.

**Heuristic**: Before flagging a non-injectable static method as a Medium extensibility finding, ask: (a) does the function have any dependencies (injected services, configuration, I/O)? (b) is there a concrete future scenario where the classification logic needs to vary at runtime? If both answers are no, the static design is correct. Only flag as Low/Watch if there is a plausible future requirement for injectable variation (e.g., the classification boundary is expected to be configuration-driven). Never flag as Medium for a pure, side-effect-free classifier.

**Corollary**: The `internal` visibility (rather than `public`) signals that the function is unit-testable within the same assembly without being exposed as a public API. This is the correct visibility for a component-local helper. Do not recommend making it a separate injectable service — that adds complexity without adding testability.

---

## 2026-06-02 — "Stable Contract" Comment Naming Multiple Update Sites Is a Medium Finding (Not Just "Future Configurable")

**Category**: Process/Model
**Finding**: The 2026-05-19 lesson covers constants with "future configurable" or "MVP constant" comments as reliable Medium findings. A separate trigger pattern: when a constant's comment says "Stable contract: **if X changes, update this constant AND <other expression site>**", the comment names multiple dependent sites that must be updated in concert. This is a multi-site coupling finding, not a "will be configurable" signal. It is still a Medium finding — the mechanism is different (coupling, not deferred injection) but the consequence is the same: a future change requires editing multiple lines that are semantically independent and rely on developer attention for coherence.

**Heuristic**: Search for inline comments that say "if this changes, update [location A] and [location B]." Each such comment is evidence that a single logical value has been encoded in multiple locations without a structural binding. Flag as Medium and recommend an options/constant class that binds the two sites through a single declaration.

**Severity calibration**: Medium regardless of whether the comment says "stable" or "future configurable." The stability claim does not eliminate the coupling — it only asserts the coupling is unlikely to matter soon. Elevate to High if the requirements audit identifies an upcoming feature that explicitly requires the value to change (e.g., multi-tenant routing, configurable auth roots).
