# Lessons Learned: REVIEW-StructuralPatternsAuditor

> # ⚠️ GLOBAL FILE — CODEBASE-SPECIFIC CONTENT IS STRICTLY FORBIDDEN
>
> **This file is committed to a shared repository and read across all projects and codebases.**
>
> The following are BANNED from this file:
> - Class names, interface names, method names, field names
> - File paths, namespace names, project names, solution names
> - Work item IDs, ticket numbers, branch names
> - Any name that is specific to one repository, team, or system
>
> **Write ONLY:** abstract patterns, heuristics, and model-behavior observations that are true regardless of the codebase, programming language, or domain.
>
> **The test:** Remove all proper nouns. If the sentence still makes sense as general engineering advice, it belongs here. If it requires context from a specific project to be meaningful, it belongs in `LessonsLearned.md` (gitignored, local only).

---

## When to Append an Entry

Only append if the session revealed something surprising: a false-positive pattern for a catalog signal, a signal-detection improvement, or an observation about how to calibrate severity. If the review ran cleanly with existing catalog patterns, skip the update.

---

## Entry 1 — SP-003 scope is narrower than the smell it names

**Session**: Full codebase structural review (Blazor dev tool, May 2026)
**Category**: Process/Model

The SP-003 signal as written targets **constructor parameter types** — a concrete class injected where an interface is expected. However, the same smell appears just as commonly as an **inline static call** in a method body (e.g., `DateTime.Now`, `File.ReadAllText`, `Directory.Exists`) in a service-layer class with a clean constructor. These inlined statics produce the same un-swappable concrete dependency that SP-003 is meant to catch, but the current signal definition would not detect them because it only checks constructor parameters.

**Suggested catalog update**: Add a second signal variant to SP-003: "Static method calls that access the file system, system clock, environment, or process state inside a business-logic or application-layer class, without being routed through an injected abstraction." This would catch `DateTime.Now` in private helper methods and `File.ReadAll*` in service method bodies.

---

## Entry 2 — The catalog's five patterns may not fully cover "anemic domain model" and "feature envy" smells

**Session**: Full codebase structural review (Blazor dev tool, May 2026)
**Category**: Process/Model

In a multi-auditor pipeline, prior audits (correctness, maintainability) will sometimes surface symptoms of a structural smell without naming its structural root cause. Specifically: a correctness auditor finding that a caller unconditionally overwrites a timestamp field is a symptom; the structural root cause is that the domain object's state machine lives in the caller (feature envy / anemic domain model). The structural auditor's value-add is to name the structural root cause and connect it to the correctness finding.

**Heuristic**: When a correctness finding describes unexpected or inconsistent field mutation, ask "who owns the logic that sets this field?" If the answer is "a caller N layers away from the model," that is a feature-envy / caller-owned state machine smell — and it is worth raising as a High structural finding even if the catalog has no exact SP-XXX match.

**Suggested catalog addition**: Propose SP-006 (Feature Envy on State Transition). Draft recorded in the structural-patterns-audit report from this session.

---

## Entry 3 — Two-component side-channel state sharing is not covered by any catalog pattern

**Session**: Full codebase structural review (Blazor dev tool, May 2026)
**Category**: Process/Model

When two components (e.g., a layout shell and a router) share runtime state through a file-backed or store-backed side channel using string keys as the only contract, none of SP-001 through SP-005 detect it. The only way to find this smell is to trace all `Load()` / `Save()` call sites and look for matching key usage in components that do not declare a dependency on each other.

**Detection heuristic**: For any settings-style service that persists keyed strings (view name, role name, path), enumerate all write sites and all read sites. If two components write and read the same key without either component depending on the other, this is an implicit behavioral contract with no compile-time enforcement. Flag it even if neither component alone looks suspicious.

**Suggested catalog addition**: Propose SP-007 (Side-Channel State Sharing). Draft recorded in the structural-patterns-audit report from this session.

---

## Entry 4 — CLI Entrypoint Files Are High-Probability God File Sites

**Session**: Full-project CLI structural review (May 2026)
**Category**: Process/Model

In a full-project CLI review, the entry file contained 600+ lines spanning configuration loading, multiple manual service factory functions, 14+ command handlers, utility functions (directory copy, path traversal), and a complex ~200-line command implementation mixing file I/O, JSON manipulation, and external tool integration — all in one file. The pattern emerged incrementally: each new command added "just a few lines." No existing SP entry (SP-001 through SP-007) catches this because they all operate at the class or method level, not at the file-scope accumulation level.

**Detection heuristic**: When reviewing CLI projects, go directly to the entrypoint file first. The threshold for escalation is: any static utility function with no coupling to the command infrastructure, OR any handler lambda exceeding 30 lines with non-trivial logic. Flag as High if a handler contains file I/O, JSON DOM manipulation, or external tool integration.

**Catalog gap**: Not covered by any existing SP entry. Proposed as SP-008 in the audit where this was discovered.

---

## Entry 5 — Verify-Before-Execute Mutable State Is a Hidden Lifecycle Signal

**Session**: Full-project CLI structural review (May 2026)
**Category**: Process/Model

A strategy class used two private mutable fields populated as side effects of a `VerifyAsync`-style method and consumed silently by an `ExecuteAsync`-style method and a metadata accessor. The second method had a silent fallback that produced degraded output when the first had not been called. The hidden lifecycle was signalled by a `"(unknown — call X first)"` string in the output — essentially a runtime error message embedded in a return value.

**Detection heuristic**: When reviewing classes with a two-method interface (verify/execute, check/process, build/run), look for: (a) private nullable fields that are set in the first method and consumed in the second, and (b) `?? fallback` expressions in the second method that reconstruct what the first method already computed. A `"(unknown — call X first)"` return string is a near-certain signal that a hidden lifecycle exists.

**Catalog gap**: Not covered by any existing SP entry. Proposed as SP-009 in the audit where this was discovered.

---

## Entry 6 — SP-001 on Eligibility Methods Should Trigger a Gate-Object Pattern Check

**Session**: Full-project CLI structural review (May 2026)
**Category**: Process/Model

When SP-001 fires on an eligibility, authorization, or validation method with numbered sequential checks, immediately ask: does the broader codebase have an established gate-object or policy-object abstraction for this kind of check? If it does, the SP-001 finding should be co-reported with SP-006 and severity elevated (from Medium to High), because the numbered steps reveal both a structural smell AND an inconsistency with an existing architectural pattern.

**Heuristic**: After detecting SP-001 in an eligibility method, search the codebase for terms like "Gate", "Policy", "Rule", "Evaluator" near the same domain area before determining severity. If a gate-object pattern exists elsewhere, co-report SP-006 and escalate.

---

## Entry 4 — SP-003 static-call variant also appears in computed properties on entities, not just method bodies

**Session**: Domain/contract layer structural review (TaskTracker.Core, May 2026)
**Category**: Process/Model

LessonsLearned Entry 1 noted that SP-003's static-call variant (inline system-clock access) appears in method bodies of service-layer classes. This session confirmed the same variant in a **computed property on a domain entity** — specifically a `Status` property that calls `DateTime.UtcNow` inline to determine a state value. This is distinct from a service method body: the static call is evaluated on every property read, not just during an explicit operation.

**Extended heuristic**: When scanning for SP-003 static-call violations, include computed properties (`=> ...`) on entity and domain model classes, not only method bodies. A computed property that evaluates system clock, environment, or filesystem state on each access is at least as problematic as an equivalent inline call in a service method — and potentially worse, because callers often do not expect property reads to have I/O or time-sensitivity.

**Key inconsistency signal**: If a codebase correctly injects a time abstraction (`TimeProvider`, `IClock`) in one domain computation class but another class calls the system clock inline in a computed property, the inconsistency is worth flagging as High even though the entity pattern might otherwise look like a Low finding.

---

## Entry 5 — A general update command that bundles state-machine fields with content fields is a distinct smell confirmed in a pure contract layer

**Session**: Domain/contract layer structural review (TaskTracker.Core, May 2026)
**Category**: Process/Model

Entry 2 first identified SP-006 (Feature Envy on State Transition) in an application/service layer. This session confirmed the same pattern in a pure **domain contract layer** (interfaces and request records only) — a general update record that carries a status-transition field alongside content fields, while the same service interface also declares dedicated named transition methods.

---

## Entry 6 — Two methods mapping the same type pair with intentionally different field sets is a distinct structural smell (Asymmetric Sibling Mappings)

**Session**: Full ViewModel project structural review (TaskTracker.ViewModels, May 2026)
**Category**: Process/Model

When a class contains two methods that both transfer state from the same source type to the same target type (e.g., a factory/initializer and an updater), they will naturally cover different field sets — the updater may intentionally skip immutable fields. The structural risk is that field additions to the source type must be propagated to both methods with no compile-time enforcement, and the asymmetry is enforced only by comments or tribal knowledge.

**Detection signal**: Look for two methods in the same class whose bodies both contain the pattern `target.PropertyX = source.PropertyX` across many properties. If one method has materially fewer assignments than the other for the same property surface, ask whether the excluded fields are truly immutable and whether the exclusion is documented.

**False-positive gate**: If the excluded fields carry a clear, accurate inline comment (e.g., `// CreatedAt intentionally omitted — immutable after creation`), treat as Low rather than Medium. The smell is about undocumented asymmetry, not documented intentional design.

**Suggested catalog addition**: Draft SP-009 (Asymmetric Sibling Mappings) recorded in the structural-patterns-audit report from this session.

---

## Entry 7 — Duplicated conditional initialization blocks are a structural smell even when the logic is simple

**Session**: Full ViewModel project structural review (TaskTracker.ViewModels, May 2026)
**Category**: Process/Model

The same branching pattern (e.g., "if no board is set, use the global variant; otherwise use the scoped variant") appearing verbatim in two unrelated classes is a structural smell even if the logic is short. The structural risk is not the code volume but the implicit maintenance contract: a rule change requires finding every site independently. Unlike pure code duplication (which a linter can detect), the smell here is that the condition encodes a domain or scoping rule that belongs in one place.

**Key distinguisher from ordinary duplication**: The block must contain a non-trivial conditional whose branching logic reflects a domain rule (tenant scoping, feature flag, authorization, environment check). Mechanical null-checks or try/catch boilerplate do not qualify.

**Suggested catalog addition**: Draft SP-010 (Duplicated Conditional Initialization Block) recorded in the structural-patterns-audit report from this session.

**Calibration note**: In a pure contract layer where entities are anemic by design (EF Core pattern), SP-006 severity should be upgraded: because the entity offers no protection (all setters are public), the service interface is the only place where transition guards can exist. Two paths to the same transition at the interface level is therefore a direct correctness risk, not merely a maintainability smell.

**Detection shortcut**: Look for a general update command (named `UpdateXxxRequest`, `EditXxxCommand`, etc.) in a codebase that also has a service method whose name is a specific verb for the same field (`SetStatusAsync`, `SetApprovedAsync`, `SetEnabledAsync`). If both exist, check whether the general update command carries any of those same fields.

---

## Entry 6 — Dual-channel notification (SP-008 proposed) is distinct from SP-007 Side-Channel State Sharing

**Session**: Domain/contract layer structural review (TaskTracker.Core, May 2026)
**Category**: Process/Model

SP-007 (Side-Channel State Sharing) covers two components exchanging state through an implicit, untyped side channel (string keys, file paths) without compile-time enforcement of the contract. The Dual-Channel Notification smell (proposed SP-008) is different: two typed, intentional interfaces both represent the same domain event but differ in transport (sync vs. async, in-process vs. network). The risk in SP-008 is **completeness** (every call site must invoke all channels) and **extensibility** (a third channel requires updating every call site). The risk in SP-007 is **discoverability** (the contract is invisible to the type system). They share no mechanism and should remain separate catalog entries.

**Suggested catalog addition**: Propose SP-008 (Dual-Channel Notification Without Coordination). Draft recorded in the structural-patterns-audit report from this session.

---

## Entry 7 — "Misleading Async Contract" (SP-009 proposed) is detectable by searching for Task.FromResult at method exit

**Session**: Domain/contract layer structural review (TaskTracker.Core, May 2026)
**Category**: Process/Model

When an interface method is declared with `Task<T>` return type and an `Async` suffix, but the implementation returns `Task.FromResult(...)` with no `await` anywhere in the method body, the async contract is misleading. The practical detection method: search for `Task.FromResult` in any class that implements an interface with an `Async`-suffixed method. Any match is a candidate for this pattern.

**Severity calibration**: This is typically Medium. Upgrade to High only if callers hold locks, use `Task.WhenAll`, or set cancellation timeouts based on the assumption that the operation is genuinely async. Downgrade to Low if there is an XML doc comment explicitly noting the implementation is synchronous and the interface is forward-looking.

**Suggested catalog addition**: Propose SP-009 (Misleading Async Contract Wrapping Synchronous Work). Draft recorded in the structural-patterns-audit report from this session.
