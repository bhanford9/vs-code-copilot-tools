# Lessons Learned: REVIEW-MaintainabilityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

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

When a method is confirmed commutative (e.g., `DistanceAlong(a, b) == DistanceAlong(b, a)`) and the code uses an inline ternary to swap arguments by side, flag it as a **Medium KISS violation** (unnecessary complexity) rather than a correctness risk. The finding should recommend simplifying the call site, not re-examining the method's commutativity.

---

## Guard-added Commits Leave Throw-Path Comments Stale — Check "Unchanged" Methods

**Category: Process/Model**
**Date**: 2026-04-23

When a commit adds a guard (e.g., `CanReach`) to prevent a throw from being reached, the guarded method (e.g., `DistanceToClear`) is typically left "unchanged." But unchanged methods may carry comments like "impossible condition" that are now demonstrably false — the guard was added *because* the condition was observed. Always check throw-path comments in guarded methods for staleness, even when the guarded method is listed as unmodified. This is a reliable source of Medium maintainability findings on guard-adding commits.
