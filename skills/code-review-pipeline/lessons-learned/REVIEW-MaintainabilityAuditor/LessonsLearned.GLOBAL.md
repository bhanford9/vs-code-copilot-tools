# Lessons Learned: REVIEW-MaintainabilityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

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

## Toggle-conditional method name mismatch is a reliable Medium finding

**Date**: 2026-04-29
**Category**: Process/Model

When a method is renamed to include "IgnoringX" (e.g., `HasAnyCheckOutputIgnoringMoiChecks`), but the implementation only ignores X when a toggle is ON — and includes X when the toggle is OFF — the method name is actively misleading for the default (toggle-off) production state. Rate this as **Medium**: callers see only the method name and cannot know there is conditional behavior inside. The fix is either to name the method to reflect its conditional semantics, or to add an inline comment. This pattern occurs reliably on toggle-integration commits that backfit toggle awareness into pre-existing utility methods.

---

## Apply existing lessons before assigning severity — re-read before rating

**Date**: 2026-04-29
**Category**: Process/Model

Step-list duplication within toggle branches (where both branches share surrounding steps but differ in the middle) is already documented as **Low** in this file. Re-read the full LessonsLearned file before assigning severity to each finding. A finding that matches a documented pattern should receive the documented severity level, not an independently reasoned one. Missing an existing lesson and assigning a higher severity is a false positive against the codebase's deliberate intent.

---

## Guard-added Commits Leave Throw-Path Comments Stale — Check "Unchanged" Methods

**Category: Process/Model**
**Date**: 2026-04-23

When a commit adds a guard (e.g., `CanReach`) to prevent a throw from being reached, the guarded method (e.g., `DistanceToClear`) is typically left "unchanged." But unchanged methods may carry comments like "impossible condition" that are now demonstrably false — the guard was added *because* the condition was observed. Always check throw-path comments in guarded methods for staleness, even when the guarded method is listed as unmodified. This is a reliable source of Medium maintainability findings on guard-adding commits.

---

## Paired Complementary Tests Parameterized on Side Predictably Produce Setup Duplication

**Date**: 2026-04-23
**Category**: Process/Model

When a toggle-addition commit adds two complementary test methods — one asserting the "data present" path and one the "data absent" path — and both are parameterized on `[Values] bool isLeftSide`, their setup code is structurally forced to be near-identical: same section factory call, same joist description, same seat environment, differing only in the `designInputs`. This is a reliable Medium-finding pattern on toggle-feature commits. Look for this specifically: two new tests in the same fixture, both `[Values] bool isLeftSide`, same toggle setup, diverging only at the thing under test. Extract-to-helper is the correct recommendation; not `[SetUp]` (only two of N tests in the fixture use it).

---

## Optional Parameter with Null Default on Toggle-Gated Extension Methods Is a Medium Maintainability Risk

**Date**: 2026-04-24
**Category**: Process/Model

When a toggle-gated feature is threaded into an extension method via `IToggles? toggles = null`, the null default creates a silent failure mode: any call site that omits the parameter gets toggle-off behavior regardless of the system-level toggle state — no compiler error, no runtime warning. Current callers may be correct, but the risk compounds over the toggle's lifetime in the codebase.

Rate this as **Medium** and recommend one of:
1. A documentation comment on the parameter explaining that production paths must pass it explicitly.
2. Removing the null default once all callers are confirmed wired (makes the contract compiler-enforced).

Do not conflate this with dependency injection wiring (DI is fine). The concern is specifically about optional parameters on non-injected call sites (extension methods, static helpers) where callers can silently omit the toggle. The toggle's promotion cleanup is also the right time to remove the optional parameter entirely.

---

## Named Constant Value Leaking Into Method Name Is a Low Readability Finding

**Date**: 2026-04-28
**Category**: Process/Model

When a class defines a named constant to avoid a magic number (e.g., `private const double _reinforcementLengthPastPanelPoint = 3d`) but then names a method using the raw value (e.g., `GetW2InterceptPlus3OnChord`), flag this as **Low readability**. The constant exists precisely to avoid value-specific names; encoding the value in the method name re-introduces the maintenance risk — if the constant value changes, the method name becomes stale documentation. The reliable recommendation: remove the value from the method name and describe the operation instead (e.g., `GetW2InterceptPlusOffsetOnChord`).

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
