# Lessons Learned: REVIEW-StructuralPatternsAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append for false-positive patterns, severity calibration updates, or new structural smell candidates not yet in the catalog. Skip if the review ran cleanly with existing catalog knowledge.

---

### SP-003 scope is narrower than the smell it names: also covers inline static calls
SP-003 targets constructor parameters typed as concrete classes. The same smell appears as inline static calls in method bodies (`DateTime.Now`, `File.ReadAllText`, `Directory.Exists`) in service-layer classes. These produce the same un-swappable concrete dependency but evade the constructor-parameter check. When reviewing for SP-003, also scan method bodies for static calls that access the file system, system clock, environment, or process state without routing through an injected abstraction.

---

### SP-007 fires on multi-file string literal scatter even without a classic strategy pattern
SP-007's catalog description focuses on strategy-registry dispatch. The same smell applies when a provider/vendor/channel identifier string appears as a bare literal in two or more files with no shared constant. The review question is the same: can the identifier be renamed by changing one declaration? If not, SP-007 applies even without a strategy interface.

---

### Abandoned session state: a UI-layer smell not covered by SP-001 through SP-009
When a UI component seeds a local mutable collection from an immutable domain session object at init time but never updates the session object as the local collection evolves, the session's computed properties become stale after the first mutation. Detection: (1) is the local collection seeded FROM the session? (2) is the session ever updated WHEN the local collection changes? (3) does the consumer re-implement a predicate already on the session object? If (1) yes, (2) no, (3) yes → Abandoned Session State, Medium. Proposed catalog entry: not yet assigned a number.

---

### Verify-before-execute hidden lifecycle is signaled by a "call X first" fallback string
When a class has a two-method interface (verify/execute, check/process) and the second method has a `?? "(unknown — call X first)"` fallback, private nullable fields set in the first method and consumed in the second represent a hidden lifecycle dependency. Rate Medium when the second method produces degraded output without an error signal. Not covered by existing SP entries.

---

### Composition-root-dominated reviews produce expected clean verdicts — do not manufacture findings
When the entire changeset is DI registration code (extension methods on `IServiceCollection`, composition roots), SP-002 explicitly exempts composition roots. SP-003 through SP-007 require call-site or instance-creation patterns absent from pure registration code. A clean verdict is correct — do not escalate marginal Low signals to compensate.

---

### "Scoped" in a class name ≠ Scoped DI lifetime — check the constructor before flagging captive dependency
Before flagging a Singleton-registered class named `ScopedXxxFactory` as a captive dependency, inspect its constructor. If it only injects `IServiceScopeFactory` and creates scopes per-call via `CreateAsyncScope()`, the Singleton registration is intentional and correct. Downgrade the finding from correctness to naming observation (Low).

---

### Mutually exclusive DI extension methods: no catalog entry detects competing registrations for the same interface
When two DI extension methods register competing implementations for the same interface (real vs. no-op, production vs. test) without a compile-time or runtime guard, a caller can invoke both and the last registration wins silently. Detection: for each interface registered in method A, search for the same interface in method B. If both exist without a `TryAddSingleton` or existence guard, flag Medium. Proposed catalog entry: not yet assigned a number.

---

### Correctness findings about scope-alignment gaps often have a structural root cause in data structure type
When a correctness audit identifies a missing scope/category check in a membership predicate, trace it to the data structure. A flat `HashSet<T>` spanning two implicit categories cannot enforce scope without an external derivation step. The structural fix (two named per-category sets, or a dictionary keyed by category) resolves both the structural smell and the correctness gap simultaneously. Rate Medium even when all current call sites are consistent — no test asserts cross-category rejection.

---

### Deprecated API surface without `[Obsolete]` is a distinct, underrepresented structural smell
Deprecated members (aliases, renamed constants, superseded overloads) without `[Obsolete]` appear in tooling autocomplete alongside current API members with no visual distinction. Rate Medium for pure aliases (risk is migration cost and audit confusion); High when the deprecated form has different behavior. The fix is always `[Obsolete("Use X instead.", error: false)]`. False-positive gate: if the deprecated form is in a separately-named legacy class or companion file, dismiss as Low.

---

### SP-001 severity escalates to Medium when two files in the same subsystem use opposite documentation conventions in the same PR
SP-001 (numbered step comments) is normally Low when the method is otherwise clean. When two files in the same functional subsystem are both modified in the same PR and use opposite conventions (one uses numbered comments, the other uses named private methods), escalate to Medium. The co-modification makes the inconsistency visible and creates an ongoing convention ambiguity.

---

### Non-exhaustive enum dispatch is the structural root cause of "dead code enum member" correctness findings
When a correctness audit identifies an enum member with dead or stub behavior, trace it to the dispatch logic. An `if/else` on a multi-member enum that silently absorbs the unimplemented member is a structural Medium co-finding. The `switch` expression form produces a compiler warning on future additions — making the structural fix also preventive.

---

### Duplicated conditional initialization blocks are a structural smell even when the logic is simple
The same non-trivial branching logic (tenant scoping, feature flag, authorization, environment check) appearing verbatim in two unrelated classes creates a rule-change risk. Rate Medium. Detection shortcut: look for a general update command alongside a specific-verb service method for the same field — if both exist with overlapping fields, flag structural duplication.

---

### Additive-only property extensions: when all sibling consistency checks pass, "Clean" is the correct verdict
When a changeset adds exactly one new property to an existing entity with matching service method, EF config, and no new class-level behavior, the structural audit's value is a consistency check (same access modifier, type, default, and EF config as siblings). If all three checks pass, the correct honest verdict is Clean.

---

### Early-exit precedence chain is NOT a candidate for SP-006 (Closed Stage List)
A method that uses early returns to enforce priority ordering (e.g., explicit deny > explicit allow > no-decision) is not a SP-006 "Closed Stage List" pattern. SP-006 targets linearly accumulated stage states; an early-exit chain is a correctly-structured guard pattern. Do not co-report these.
