# Lessons Learned: REVIEW-StructuralPatternsAuditor

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
> **Write ONLY:** abstract patterns, heuristics, and model-behavior observations that are true regardless of the codebase, programming language, or domain.
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

Only append if the session revealed something surprising: a false-positive pattern for a catalog signal, a signal-detection improvement, or an observation about how to calibrate severity. If the review ran cleanly with existing catalog patterns, skip the update.

---

## Entry 1 — SP-003 scope is narrower than the smell it names

**Session**: Full codebase structural review (Blazor dev tool, May 2026)
**Category**: Process/Model

The SP-003 signal as written targets **constructor parameter types** — a concrete class injected where an interface is expected. However, the same smell appears just as commonly as an **inline static call** in a method body (e.g., `DateTime.Now`, `File.ReadAllText`, `Directory.Exists`) in a service-layer class with a clean constructor. These inlined statics produce the same un-swappable concrete dependency that SP-003 is meant to catch, but the current signal definition would not detect them because it only checks constructor parameters.

**Suggested catalog update**: Add a second signal variant to SP-003: "Static method calls that access the file system, system clock, environment, or process state inside a business-logic or application-layer class, without being routed through an injected abstraction." This would catch `DateTime.Now` in private helper methods and `File.ReadAll*` in service method bodies.

---

## Entry 2 — SP-007 Fires on Multi-File String Literal Scatter Even Without a Classic Strategy Pattern

**Session**: Auth service structural review (May 2026)
**Category**: Process/Model

SP-007's catalog description focuses on a strategy-registry pattern where a discriminator string is compared to resolve an implementation. The same smell applies more broadly when provider/vendor/channel identifier strings (known at compile time) appear as bare literals in two or more separate files with no shared constant declaration — even without a classic strategy interface. The review question remains valid: can the identifier be renamed by changing one declaration? If not, the string literals are scattered and SP-007 should fire.

**Application guidance**: When reviewing any feature that supports N named providers (OAuth, payment gateways, notification channels), search for the provider slug string in more than one file. If the same literal string appears in a routing/dispatch table AND in a service-call call site in a registration class, flag SP-007 Medium. The fix is a central constant class, not necessarily an enum (since the strings may need to interface with external systems or DB columns).

---

## Entry 3 — Abandoned Session State: a UI-layer gap not covered by SP-001 through SP-009

**Session**: Permissions lifecycle structural review (May 2026)
**Category**: Process/Model

When a UI component receives an immutable domain session record from a service, seeds a local mutable copy for UI state tracking, and then never updates the session record as that state evolves, the session object's computed properties become stale immediately after the first mutation. None of SP-001 through SP-009 detect this because: SP-004 (Tell-Don't-Ask) targets strategy/policy bridges, not session state management; SP-009 (Untestable Logic Path) targets infrastructure entanglement; and no existing catalog entry covers duplicated behavioral methods between a domain session object and its consumer.

**Detection heuristic**: When reviewing a UI component that holds both a domain session object field (`_session`) and a local mutable collection field (`_items`, `_decisions`, `_entries`), ask: (1) Are the local mutable items populated FROM the session at init time? (2) Is the session object ever UPDATED when the local items change? (3) Does the consumer declare any boolean or list property that uses the same LINQ predicate as a property on the session object? If (1) = yes, (2) = no, and (3) = yes, this is an Abandoned Session State smell. The fix is always to sync the session record on each mutation using a `with` expression, then delete the duplicated consumer property.

**Severity calibration**: Medium when the abandoned session properties could be read by a future maintainer in the same component (e.g., the session is a named field). The risk is a silent stale-state bug at future-maintenance time, not a current defect.

**Proposed catalog entry**: Draft recorded in structural-patterns-audit — **TBD** (not yet in catalog; current max is SP-009).

---

## Entry 4 — Verify-Before-Execute Mutable State Is a Hidden Lifecycle Signal

**Session**: Full-project CLI structural review (May 2026)
**Category**: Process/Model

A strategy class used two private mutable fields populated as side effects of a `VerifyAsync`-style method and consumed silently by an `ExecuteAsync`-style method and a metadata accessor. The second method had a silent fallback that produced degraded output when the first had not been called. The hidden lifecycle was signalled by a `"(unknown — call X first)"` string in the output — essentially a runtime error message embedded in a return value.

**Detection heuristic**: When reviewing classes with a two-method interface (verify/execute, check/process, build/run), look for: (a) private nullable fields that are set in the first method and consumed in the second, and (b) `?? fallback` expressions in the second method that reconstruct what the first method already computed. A `"(unknown — call X first)"` return string is a near-certain signal that a hidden lifecycle exists.

**Catalog gap**: Not covered by any existing SP entry. Proposed new pattern — **TBD** (SP-009 was assigned to “Untestable Logic Path”).

---

## Entry 5 — Composition-Root-Dominated Reviews Produce Expected Clean Verdicts

**Session**: DI module consolidation structural review (May 2026)
**Category**: Process/Model

When the entire changeset is composed of DI registration modules (extension methods on `IServiceCollection`, composition roots, or factory wrappers), the structural patterns audit will correctly produce a Clean or near-Clean verdict. SP-002 explicitly exempts composition roots. SP-003, SP-004, SP-005, SP-006, and SP-007 all require call-site or instance-creation patterns that are absent from pure registration code.

**Calibration note**: A Clean verdict in this scenario is not a failure to find issues — it IS the correct finding. The auditor should not manufacture findings or over-escalate marginal Low signals to compensate for the absence of Medium or High matches. When the changeset is structurally clean, say so clearly and direct analysis energy toward catalog gaps (new patterns observed that no SP entry covers).

---

## Entry 6 — DI Lifetime-Qualifier Word in a Class Name Is a Recurring False-Positive Signal

**Session**: DI module consolidation structural review (May 2026)
**Category**: Process/Model

When a concrete service class name includes the word `Scoped`, `Transient`, or `Singleton` — and the class is registered with a *different* lifetime than the word implies — multiple independent review passes will incorrectly flag this as a captive-dependency or lifetime-mismatch bug. The pattern appears when a class uses a lifetime-qualifier word to describe its *behavioral* model (e.g., "creates a scope per call") rather than its own DI registration lifetime.

**Detection heuristic**: Before flagging a Singleton-registered class whose name includes "Scoped" as a captive-dependency issue, check its constructor for `IServiceScopeFactory` (a framework singleton). If the constructor injects only `IServiceScopeFactory` and the implementation creates a scope per method call via `CreateAsyncScope()`, the Singleton registration is intentional and correct. The finding should be downgraded from a correctness issue to a naming observation and recorded as a catalog gap candidate (proposed new pattern — **TBD**; SP-008 was assigned to “Excessive Test Arrangement Complexity”).

---

## Entry 7 — Mutually Exclusive DI Extension Methods Are Not Detected by Any Existing Catalog Entry

**Session**: DI module consolidation structural review (May 2026)
**Category**: Process/Model

A recurring structural smell appears in multi-host codebases where DI extension methods register competing implementations for the same interface (real vs. no-op, production vs. test). When these methods are defined without any compile-time or runtime guard preventing a caller from invoking both, the only enforcement is documentation. This is not detected by SP-001 through SP-007 because none of them scan for method pairs that register the same service type.

**Detection heuristic**: During a DI module review, for each interface registered in extension method A, search for the same interface registered in any other extension method B. If A and B both register `services.AddSingleton<ISomeInterface, ImplementationX>()` and `services.AddSingleton<ISomeInterface, ImplementationY>()` respectively, ask: is there a guard in either method (a `services.Any(...)` check, a `TryAddSingleton`, or a builder that enforces exactly-one)? If not, document it as a catalog gap candidate (proposed new pattern — **TBD**; SP-009 was assigned to “Untestable Logic Path”) and note the severity based on how critical the interface is.

**Key inconsistency signal**: If a codebase correctly injects a time abstraction (`TimeProvider`, `IClock`) in one domain computation class but another class calls the system clock inline in a computed property, the inconsistency is worth flagging as High even though the entity pattern might otherwise look like a Low finding.

---

## Entry 8 — Correctness Findings About Scope-Alignment Gaps Often Have a Structural Root Cause in Data Structure Type

**Session**: Permission catalog structural review (May 2026)
**Category**: Process/Model

When a correctness audit surfaces a scope-alignment gap — "policy X fires without verifying the resource's scope" — the structural root cause is frequently that the policy is encoded as a flat membership set (`HashSet`, `IReadOnlySet`) where all scope-specific members share a single collection. A flat set can only answer "is this value a member?" — it cannot answer "is this value a member of the correct scope for this context?" without an additional, external scope derivation step that the flat set itself does not enforce.

**Heuristic**: When reviewing a correctness finding about missing scope/category enforcement in a membership check, trace it to the data structure holding the policy. If the policy is a flat set whose members span two or more implicit categories, the correct structural fix is to replace the flat set with either (a) two named per-category sets, or (b) a dictionary keyed by category. The structural fix simultaneously resolves the correctness gap — no separate correctness patch is needed. Always recommend the structural fix as the combined resolution.

**Calibration for severity**: If the scope mismatch produces an incorrect security decision (an allow where a deny is required), rate the structural finding at Medium even if the mismatch requires a caller error to trigger and all current call sites are consistent. The absence of a test asserting cross-category rejection is the secondary signal — if no test covers the mismatch, the gap is invisible until a caller error occurs in production.

---

## Entry 9 — Deprecated API Surface Without `[Obsolete]` Is a Distinct, Underrepresented Structural Smell

**Session**: Permission catalog structural review (May 2026)
**Category**: Process/Model

When a public class carries deprecated members (backward-compatible aliases, renamed constants, superseded overloads) alongside current API members with no `[Obsolete]` attribute, the deprecation is documentation-only. This is a structural smell not covered by any catalog entry through SP-009: it is not a strategy-dispatch string issue (SP-007), not a concrete dependency issue (SP-003), and not a numbered-step-comment issue (SP-001). The signal is specifically: "deprecated member visible in tooling autocomplete with no visual or compiler distinction from current members."

**Severity calibration**: Rate Medium when the deprecated and current forms are pure aliases (no behavioral difference today) — the risk is future migration cost and audit confusion. Rate High when the deprecated form has different behavior (e.g., silently drops a field, uses a legacy API that will be removed).

**The fix is always a one-liner**: `[Obsolete("Use X instead.")]` with `error: false` preserves backward compatibility for existing callers while generating a warning for new adoption. This is the lowest-cost structural fix in the catalog — recommend it whenever the pattern appears, regardless of how small the alias count is.

**False-positive gate**: If the deprecated form is in a separately named nested class or companion file whose name signals legacy nature (e.g., `LegacyApi`, `_Compat`), the structural isolation is adequate — dismiss as Low or pass.

---

## Entry 10 — SP-001 Severity Escalates to Medium When Two Files in the Same Subsystem Use Opposite Step-Documentation Conventions in the Same PR

**Session**: Authorization service structural review (May 2026)
**Category**: Process/Model

SP-001 (Numbered Step Comments) is normally Low when a method is otherwise clean and the numbered comments are the only issue. However, when two files in the same functional subsystem are BOTH modified in the same PR and use opposite step-documentation conventions — one using numbered comments, the other using named private methods — the inconsistency rises to Medium. The co-modification makes the inconsistency directly visible to reviewers and raises the question of which convention is canonical, creating ongoing maintenance ambiguity.

**Calibration rule**: Before rating SP-001 as Low, check whether any other file in the same subsystem (or the same PR's changeset) contains the correct form (named private methods for each step). If it does, escalate to Medium. The inconsistency is the finding, not just the numbered comments in isolation.

**Why this matters**: A Medium finding prompts the team to establish and apply the naming convention in the same PR rather than accumulating an inconsistency that compounds over time. A Low finding might be deferred indefinitely.

---

## Entry 11 — Non-Exhaustive Enum Dispatch Is the Structural Root Cause of “Dead Code Enum Member” Correctness Findings

**Session**: Authorization service structural review (May 2026)
**Category**: Process/Model

When a correctness audit surfaces an enum member that is documented as having distinct behavior but is silently handled identically to another member (effectively dead code), the structural auditor should look immediately for a non-exhaustive `if/else` at the enum's dispatch site. If found, this is a Medium structural co-finding — it explains WHY the dead code was easy to introduce (the `else` branch caught the unimplemented member silently) and WHY it will recur if not fixed (future enum additions will be silently absorbed the same way).

**Detection heuristic**: When a correctness audit identifies dead or stub behavior in a named enum member, trace back to the dispatch logic. If the dispatch uses `if (x == SomeValue) {} else {}` on a multi-member enum rather than an exhaustive `switch`, flag it as a structural Medium co-finding. Include a note that the switch form (C# 8+ `switch` expression) would emit a compiler warning on the next addition, making the structural fix a preventive measure for all future enum members, not just the current stub.

**Catalog gap**: This pattern was proposed as a new catalog entry ("Non-Exhaustive Enum Dispatch") in the audit where it was first identified. Promote to the catalog after one additional confirmation sighting.

---

## Entry 12 — Duplicated conditional initialization blocks are a structural smell even when the logic is simple

**Session**: Full ViewModel project structural review (May 2026)
**Category**: Process/Model

The same non-trivial branching logic (tenant scoping, feature flag, authorization, environment check) appearing verbatim in two unrelated classes is a structural smell — not because of code volume, but because a rule change requires finding every site independently. Mechanical null-checks or try/catch boilerplate do not qualify.

**Detection shortcut**: Look for a general update command (named `UpdateXxxRequest`, `EditXxxCommand`) in a codebase that also has a specific-verb service method for the same field (`SetStatusAsync`, `SetApprovedAsync`). If both exist with overlapping fields, flag as structural duplication.

**Proposed catalog addition**: Draft (Duplicated Conditional Initialization Block) — **TBD** (not yet in catalog; current max is SP-009).

---

## Entry 13 — Additive-Only Property Extensions Require Consistency Audit, Not Pattern Hunt

**Session**: Entity property extension with persistence configuration (May 2026)
**Category**: Process/Model

When a changeset adds exactly one new property to an existing entity with matching service method, EF config, and no new class-level behavior, SP-001 through SP-009 will produce a Clean verdict by construction. The structural audit's real value is a **consistency check**: same access modifier/type/default as sibling? Same optional-parameter ordering? EF config copied verbatim (if so, extraction opportunity = Low finding)?

When all three checks pass, "Clean" is the correct honest verdict.

---

## Entry 14 — Early-exit precedence chain is NOT a co-report candidate for SP-006 (Closed Stage List)

**Session**: Pure-domain authorization engine structural review (May 2026)
**Category**: Process/Model

SP-006 applies only when ALL stages are evaluated and results collected into a record with fields named after stages. An early-exit precedence chain (return at first match) does NOT require changing the result type when a new step is added — SP-006’s core structural risk is absent. When SP-001 fires on a numbered method using early-return short-circuiting, check only:
1. Is there an established gate-object pattern elsewhere? → If yes, co-report SP-006 (Entry 6 rule)
2. Does the result type accumulate one field per step? → If yes, that IS SP-006

If neither, SP-001 alone is the correct finding.

---

## Entry 15 — Repeated Inline Authorization Guard Is a Distinct Structural Smell Not Covered by SP-001 Through SP-009

**Session**: IDOR guard implementation structural review (May 2026)
**Category**: Process/Model

The same 4–8-line authorization guard (condition + audit log + throw) copied to N ≥ 3 methods in the same class is not detected by any existing catalog entry. A single private helper would create one enforcement point.

**Detection**: After any security feature adding guards to multiple methods, search for identical `if (condition) { log + throw }` blocks in the same class. Flag **Medium** if condition, log message, and exception text appear in 3+ methods. Escalate to **High** if a co-current correctness audit identified a gap in the guard condition.

**Proposed catalog entry**: Repeated Inline Authorization Guard (May 2026). Promote after one additional sighting.

---

## Entry 16 — SP-009 Co-occurrence With a Correctness Finding Auto-Elevates to High

**Session**: Sharing authority model structural review (May 2026)
**Category**: Process/Model

SP-009 (Untestable Logic Path) is normally rated Medium when the untestable path contains business logic subject to change. The severity should be auto-elevated to High when a correctness or security auditor has independently identified a bug in that same logic block in the same review cycle.

**Rationale**: A correctness finding on an untestable block is direct, empirical evidence that the untestability gap has already caused a real failure. The structural finding is no longer predictive ("this path might produce a bug") — it is retrospective ("this path already produced a confirmed bug"). The correct severity for a structural pattern that has a proven consequence is High, not Medium.

**Escalation rule**: At the end of applying SP-009, check the correctness audit report for any overlapping finding. If the correctness auditor flagged a bug or defensive gap in the same method body or logic branch, escalate the SP-009 finding from Medium to High, and note in the report: "Co-occurs with correctness [M-N] — escalated per pattern rule."

**Severity cap**: If the correctness finding is Critical or the structural untestability directly prevents detection of a security-relevant bug, escalate the SP-009 finding to Critical — not just High.

---

## Entry 17 — Asymmetric Inverse-Operation Delegation as a Structural Smell

**Session**: Sharing authority model structural review (May 2026)
**Category**: Process/Model

When a service implements two inverse operations (Grant/Revoke, Add/Remove) and routes one through a domain service interface but the other directly to infrastructure, future service-layer additions (audit, validation) silently apply only to the service-interface path.

**Detection**: For every inverse method pair, trace mutation paths. If one calls a service interface and the other calls infrastructure (DbSet, HTTP client, file system) directly, flag as **Medium**. Escalate to **High** if the paths already diverge (e.g., one has IDOR guard + audit; the other has neither).

**Fix**: Add an inverse method to the service interface and route through it. The direct-infrastructure access in the calling class disappears.

**Proposed catalog entry**: Asymmetric Inverse-Operation Delegation (May 2026).

---

## Entry 18 — CancellationToken Threading Into Fire-and-Forget Secondary Actions Creates Silent Loss Window

**Session**: Sharing authority model / audit trail structural review (May 2026)
**Category**: Process/Model

A secondary action (audit write, notification) wrapped in `try/catch` for resilience silently loses its result if the caller’s `CancellationToken` is passed to it — a request cancellation between primary completion and secondary completion is swallowed as a generic write failure.

**Detection**: Any method that wraps a secondary async call in `try/catch`, passes the caller’s `CancellationToken` to the secondary call, and does not distinguish `OperationCanceledException` in the catch block.

**Severity**: High for compliance-required writes (audit, consent). Medium for recoverable secondary actions. Low for telemetry.

**Fix**: Pass `CancellationToken.None` to secondary actions. Or split the catch: `OperationCanceledException` → log "cancelled"; all others → existing behavior.

**Proposed catalog entry**: CancellationToken threading smell (May 2026).

---

## Entry 19 — Fixed-Delay Negative Assertion Is a Test-Code Structural Smell Not Covered by Any Catalog Entry

**Session**: Auth redirect handler structural review (June 2026)
**Category**: Process/Model

When a test asserts the *absence* of a state change (no navigation, no DOM update, no event emission) by sleeping a fixed duration and then observing unchanged state (`Task.Delay(N)` or `Thread.Sleep(N)` before the assertion), the assertion window is defined by an arbitrary constant rather than a deterministic framework signal. This pattern appeared in two tests in the same test class, both using the same sleep duration — sharing an implicit coupling that requires a coordinated update if the timing assumption ever changes.

**Why it matters structurally:**
1. The fixed duration is inherently racy: too short in slow CI environments (false negative), too long on fast machines (wasteful).
2. When the same delay appears in multiple tests, it is a de facto "test-class scoped constant" with no declaration — a maintenance coupling invisible to the type system.
3. Modern UI test frameworks offer deterministic absence-assertion alternatives: a short-timeout URL wait expected to time out, a settled-state attribute assertion, or a negative `WaitForSelector` with a short explicit timeout. These are both faster and unambiguous.

**Severity calibration**: Low if the delay is ≤1 second and only one test in the class uses it. Medium if the pattern appears in 2+ tests in the same class, the delay is ≥2 seconds, or the test class has a known flakiness history.

**Note**: This is a TEST CODE structural smell, not a production code pattern. None of SP-001 through SP-009 cover test code timing. The structural auditor should note it as a catalog gap candidate and route the finding to the Test Coverage auditor for the current review cycle, rather than issuing it as a standalone structural finding.

**Proposed catalog entry**: Fixed-Delay Negative Assertion (test-code structural smell, June 2026). Consider adding as a test-code annex to the structural catalog.
