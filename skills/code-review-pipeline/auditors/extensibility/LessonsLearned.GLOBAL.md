# Lessons Learned: REVIEW-ExtensibilityAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed a false-positive pattern or a non-obvious heuristic for detecting extensibility constraints. If the review ran cleanly with existing knowledge, skip the update.

---

## `const` with a "future configurable" comment is an EX-001/002 signal

A `const` field annotated with a comment like "future: configurable" or "move to settings" is explicitly flagged by the author as a hardening item. Treat it as a confirmed Medium EX-001 regardless of whether a current use case requires flexibility. The comment documents known intent.

---

## Hard-coded fan-out aggregator where the author named the consumers

When a method builds a result by combining outputs from a list of hard-coded subsystems — and comments in the code name which subsystems are wired — the addition of any new subsystem requires a code change. Rate Medium EX-002. The fix is a registry or `IEnumerable<ISubsystem>` pattern. The presence of author-supplied comments naming the list is direct evidence that the author knows the list will grow.

---

## Write-biased append service with named "future consumer" comments

A service with only a write/append interface and no read/query interface means consumers must get data through a separate channel. If comments in the code name the intended consumers, rate Medium EX-002 — the design is closed to future consumers. Recommend exposing a query interface rather than requiring each consumer to maintain its own parallel read path.

---

## Non-nullable grouping field when most events are standalone

When an audit or event record carries a nullable grouping/correlation field, and most events are standalone (no grouping), an optional grouping field is correct. Do NOT flag optional (nullable) grouping fields as extensibility gaps. Flag only when the field is required and the required-vs-optional decision conflicts with the stated design intent.

---

## Manually-initialized catalog without a reflection-based exhaustiveness guard

When a catalog or registry is populated by manual registration calls at startup and the set of registerable items can be derived by type-scanning (interfaces, attribute markers, base class), the catalog is at risk of silent incompleteness. Any new item added to the codebase without a corresponding registration call will work at compile time and fail at runtime. Rate Medium EX-003. The fix is a one-time automated scan that validates the manual registrations are exhaustive.

---

## Multi-class catalog with fewer than 4 values may be better as an enum

When a catalog pattern (interface + N concrete classes) has fewer than 4 implementations and each concrete class is a pure value (no virtual methods required), an enum accomplishes the same purpose with less ceremony. Flag as Low EX-003 only — the over-engineering smell, not a blocking finding.

---

## Enum-dispatched service methods without exhaustiveness enforcement

When a service has a method-per-enum-value pattern (e.g., `BuildForTypeA`, `BuildForTypeB`) rather than dispatching on the enum, new enum values require a new method and a new dispatch. Without an exhaustive `switch` or interface constraint, future additions will silently produce default/null results. Rate Medium EX-005. Recommend a `switch` expression with a discard arm that throws `ArgumentOutOfRangeException`.

---

## String-persisted enum: stable-contract guarantee in a doc comment is not enforcement

When an enum value persisted as a string to a database is annotated only with a doc comment saying "do not rename," the contract is unenforced. Any developer who rename-refactors the identifier without reading the doc comment will silently break persisted data. Rate Medium EX-005. The fix is an explicit `[EnumMember(Value = "...")]` or equivalent attribute that makes the serialization contract independent of the identifier name.

---

## Binary ternary on an open enum: silent default for all future values

A ternary `condition == SomeEnum.Value ? x : y` on an enum with 3+ values treats all non-matching values identically. Future enum additions silently fall into the `y` branch. Rate Medium EX-005. Recommend an exhaustive switch with a throw on the default arm.

---

## Single-method evaluator interface is a positive, not a finding

A dedicated interface with a single evaluation method (e.g., `IPermissionEvaluator`) is the Strategy pattern applied correctly. It enables mock substitution, multiple implementations, and future extension. Mark as positive. Do not flag narrow interfaces as under-designed.

---

## Auth trace labels as hidden coupling between interface contracts

When an interface method returns a trace label or identifier string that is consumed externally (e.g., by a dispatcher or log aggregator), the string values are effectively part of the public contract. Any rename of the string breaks downstream consumers silently. Rate Medium EX-005 when the string values are not declared as constants shared between the producer and consumer.

---

## Interface return-type asymmetry when only one implementation can reject

When an interface has two similar methods where one returns `bool` (can signal failure) and the other returns `void` (hardwired success), the interface encodes an extensibility constraint. Future callers cannot uniformly handle rejection across both methods without an interface change. Rate Medium — flag the asymmetry and recommend either aligning the return types (making void→bool with `return true`) or documenting the invariant explicitly in the interface contract. Do not rate it High unless there is active evidence the always-success constraint is fragile.

---

## Security-invariant collections coupled to enum definitions

When an immutable constant set (whitelist, catalog) is defined inline adjacent to the enum whose members it describes — and no automated check validates that the set contains every enum member — the invariant is purely manual. Adding an enum member without updating the set produces a silent security gap. Rate HIGH EX-006 when the set is used as an authorization guard. The fix is a compile-time completeness assertion.

---

## Security-motivated narrow interface is a positive — do not flag write-exclusion as a gap

An interface deliberately exposes only read operations when the design intent is to prevent callers from mutating data directly. This is correct design. Do not flag the absence of write methods as EX-002. Flag only when the read-only restriction is undocumented and appears to be an oversight rather than intent.

---

## Convergent Medium findings at a feature boundary may warrant a compound upgrade

When three or more Medium extensibility findings all cluster around the same feature boundary (e.g., "every new auth provider requires changes to these 5 sites"), consider synthesizing them into a single High: "extensibility gap at feature boundary." The compound finding is more actionable than a list of Mediums.

---

## Incomplete DI consolidation: new method without old method removal

When a changeset introduces a new DI extension method to replace an existing one but the old method is retained without deprecation, future callers will use whichever they find first. Rate Medium EX-002. The finding is not about DI lifetime — it is about the ambiguity created by two methods registering competing implementations for the same interface.

---

## Positional record as event payload limits future additions to append-only

A C# positional record used as an event payload fixes its constructor signature at declaration. Adding a new field is a breaking change for any constructor call site. Rate Low EX-004 in stable code (existing call sites are known); rate Medium if the event is dispatched across assembly boundaries where call sites are not visible.

---

## Dirty-tracking via serialization-then-comparison is a hidden coupling to serialization format

When a ViewModel tracks changes by serializing state to JSON and comparing strings, adding a non-serializable property to the model silently breaks dirty-tracking. Rate Medium EX-003. The fix is explicit property-level change tracking rather than serialization-round-trip comparison.

---

## Typed binary dispatcher with N call sites: all N must be updated for a new type

When a dispatcher resolves behavior by testing a sealed type hierarchy with `if (x is TypeA) ... else if (x is TypeB)...`, every new type requires modifying the dispatcher. Rate Medium EX-005. The structural fix is a visitor pattern or type-keyed dictionary so new types self-register.

---

## Parameter type mismatch between factory and dispatcher silences new-type handling

When a factory creates objects of one type hierarchy and a dispatcher handles a different type hierarchy with overlapping names, a new type may be created by the factory but never reach a handler — silently dropped. Rate HIGH EX-006 if the dispatch miss results in no processing and no error. The diagnostic signal is a factory that produces types not present in the dispatcher's handler list.

---

## Private static strategy methods: each new strategy requires a code change at the dispatch site

When strategy logic is encoded as private static methods in a dispatch class rather than as injectable strategy objects, adding a new strategy requires: (1) new private method, (2) new dispatch branch, (3) possible new registration/catalog entry. Rate Medium EX-005. Recommend extracting to an interface and using a dictionary keyed by discriminator.

---

## Observable collection in ViewModel interface creates UI-framework coupling at the contract level

When a ViewModel exposes an `ObservableCollection<T>` on its interface rather than `IEnumerable<T>` or `IReadOnlyList<T>`, the UI framework type leaks into the contract. Consumers must reference the UI framework assembly. Rate Medium EX-003. Use `IReadOnlyList<T>` or `IReadOnlyObservableCollection<T>` on the interface; implement with `ObservableCollection<T>` in the concrete class.
