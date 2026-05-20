# Lessons Learned: REVIEW-UnitTestCoverageAuditor

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

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future unit test coverage reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## Zero-Test Subsystems Require Infrastructure Assessment First

**Category: Process/Model**

When reviewing a subsystem that has **no test project at all**, lead the report with an infrastructure assessment before the per-requirement coverage table. The standard "coverage by requirement" analysis becomes secondary to answering: "what would it take to create a test project?" and "are the methods testable as-is?".

Key questions to answer early in a zero-test audit:
1. What test framework and mocking library does the broader solution use? (Match it — do not introduce a new framework.)
2. Are the critical methods `public`, `internal`, or `private`? If `private static`, recommend making them `internal static` + `[assembly: InternalsVisibleTo(...)]`. Name this as a prerequisite blocker, not a recommendation.
3. What interfaces exist for dependencies? If the service under test has interface-typed collaborators, mocking is trivial — say so explicitly. If concrete types are used, note that as a testability gap.
4. Does a DI container initialization path exist that could be reused in tests, or must the object be constructed manually?

Rating in a zero-test audit: the overall score should be 0/10 (or "Inadequate") and the primary recommendation should be "create test project first." Do not soften this to "Poor" just because the production code is logically correct.



---

## Dead Toggle Assertions in Test Fixtures

**Category: Process/Model**

When reviewing tests that gate assertions on a feature toggle, check whether the toggle instance used in the fixture (e.g., built with an all-disabled toggle helper) makes any `if (toggles.IsEnabled(...))` assertion branches permanently dead code. This pattern is common when a developer adds toggle-aware test branching but forgets to create a second toggle instance with the toggle enabled.

- Rating this as **Critical** is correct when the dead branch is the primary behavior change under test (not just a parallel path).
- Do NOT downgrade to Medium just because the developer has written the expected-log arrays — the arrays being present means they thought about it, but the code never executes.
- Recommend: extract to parameterized `[TestCase(true/false)]` pattern OR add a parallel toggle-enabled fixture field. Both are valid; mention both so developer can choose.

---

## Check Test Inputs for Degenerate Cases When Auditing Numeric Fixes

**Category: Process/Model**

When reviewing a fix that changes a calculation formula (e.g., from one distance metric to another, or from an absolute value to a projected one), always check whether the test input is degenerate for that distinction. Symmetric, axis-aligned, or boundary-condition inputs often produce identical values under both the old and new formula. If the only test input is degenerate, the core fix is untestable and the test provides false confidence. Look for an explicitly non-degenerate input (e.g., an off-axis or angled configuration where the two formulas would produce meaningfully different results) before concluding the fix is tested.

---

## Known-Gap Requirements Should Always Have a Test — Even a Documenting One

**Category: Process/Model**

When a requirements audit or correctness audit identifies a known implementation gap (e.g., a missing floor or ceiling constraint in a numeric computation), always check whether the test suite has a test that documents the current incorrect behavior. If not, this is a coverage gap regardless of whether the gap is "acknowledged." A test that asserts the current (wrong) behavior prevents silent fixes and regression in either direction. Flag the absence of such a test as High priority even when the gap itself was flagged by a prior audit.

---

## Bounded Assertions (`Is.GreaterThan`) Are Red Flags for Core Fix Tests

**Category: Process/Model**

When a test uses `Is.GreaterThan(x)` or `Is.LessThan(x)` for the single test case that exercises the feature's core correctness (e.g., "the corrected formula produces a larger result than the old formula for this specific non-degenerate input"), flag it as a weak assertion. The test proves the direction of change but not the magnitude. Any implementation that produces a result in the right direction (but wrong magnitude) passes. Recommend replacing with an exact expected value derived from the test geometry.

---

## `Assert.DoesNotThrow` With a Non-Throwing Mock Is a Hollow Assertion

**Category: Process/Model**

When auditing a test that uses `Assert.DoesNotThrow(() => sut.Method(...))` alongside a mock, always check whether the mock is configured to throw. If the mock returns a value (`.Returns(x)`) rather than throws, `DoesNotThrow` will pass regardless of whether the short-circuit or guard being tested is working. The real load-bearing assertion is elsewhere (typically `Times.Never` for the would-have-thrown method). Flag this as Medium:
- The assertion appears to verify crash prevention but does not.
- The recommendation is to change the mock to `.Throws(new SpecificException(...))` so that `DoesNotThrow` gains real teeth. This also makes the test simulate the actual production failure scenario more faithfully.
- `Times.Never` on the dangerous method should be retained as belt-and-suspenders documentation even after fixing the mock.

---

## Fallthrough Tests With Degenerate Outcomes Are Assertion-Ambiguous

**Category: Process/Model**

When a test is named `ShouldFallThrough...` (or similar) but only asserts the terminal result of the downstream path (e.g., `Is.False`), verify that the test geometry makes both paths distinguishable:

- If both "correctly fell through and downstream returned false" AND "prematurely exited with return false" produce `Is.False`, the test name is aspirational — the assertion does not enforce fallthrough.
- Flag as **Medium** and recommend adding a complementary case where the downstream path returns `true`, so that `Is.True` can only be produced if fallthrough actually occurred.
- This pattern is distinct from Bounded Assertions (which use `GreaterThan`/`LessThan`) — here the assertion is exact, but the test geometry makes the correct and broken paths produce identical outcomes.
- Do not downgrade to Low just because the code structure makes the current result "structurally sound" — that reasoning requires reading the production code, which is exactly what a good test should eliminate the need for.

---

## `Times.AtLeastOnce` in Short-Circuit Tests Is Often Imprecise

**Category: Process/Model**

When a test verifies that a guard/short-circuit fires — and the geometry of the test means the guarded method should be called exactly once — flag `Times.AtLeastOnce` as imprecise and recommend `Times.Once`. The distinction matters because:
- A broken short-circuit that re-enters the guarded path N > 1 times would still pass `Times.AtLeastOnce`.
- `Times.Once` would catch that regression.
Only downgrade to `Times.AtLeastOnce` (or leave it) when the loop/iteration count is genuinely variable and unknown from the test setup. In short-circuit tests with fixed geometry, the call count is deterministic.

---

## Test Names Referencing Toggle States That Don't Match the Fixture

**Category: Process/Model**

When a test is named `...WhenToggleEnabled` (or `...WhenFeatureOn`, `...IfFlagSet`, etc.) but the fixture uses `AllDisabled()` or a negated toggle builder, flag the name as misleading regardless of whether the assertion itself is correct. This happens when tests survive a refactor that moved the toggle check from one class to another, or when a developer renamed a test without updating the fixture state.

- The medium-severity finding is the **naming confusion**, not the correctness of the assertion.
- The recommendation is a rename (remove the toggle qualifier) PLUS a note that the toggle-ON scenario for that behavior may be untested in the new code path.
- Do not mark this High — the assertion is not wrong, only the name. But do explicitly surface it so the developer knows to add the toggle-ON test for the new path.
- Combine this observation with a check of whether the new code path's equivalent guard (e.g., the same predicate check in a different method) has any test at all with the toggle enabled.

---

## Dev-Tool Code Still Warrants Tests for Its Pure Logic Layer

**Category: Process/Model**

When new code lives in a dev-only project (e.g., `Source/DevTools/`), do NOT apply a blanket "low severity" rating to all coverage gaps. Apply the same test-value analysis as for production code, then adjust severity based on runtime risk:

- **Framework-layer APIs that enable the dev tool** (e.g., a new `RunObserved` method on a production `FlowRunner`) remain **High priority** even when the only consumer is a dev tool — the method lives in production code and a regression is production-blast-radius.
- **Pure domain logic in the dev tool** (epsilon comparison, string parsing) rates **Medium** — the logic is non-trivial but runtime risk is dev-only.
- **Rendering code that depends on graphics libraries** (SkiaSharp, GDI+) is **genuinely untestable** in unit tests — accept this explicitly and do not flag it as a gap.
- **Integration test infrastructure changes** (collect-and-continue loops, failure-summary aggregation) are test code, not production code — no unit tests required.

The risk axis to evaluate for each gap: "If this logic were wrong, would the failure be observable during a devtool run?" If yes and the logic is pure (no I/O), the test has value regardless of dev-only runtime path.

---

## `FlowRunner`-Style Generic Step Engines Are Highly Testable With a Builder Pattern

**Category: Process/Model**

When auditing coverage gaps for a generic step-execution engine (`FlowRunner<TKey, TContext>` or similar), note that the engine's own test suite likely already uses a low-dependency `FlowBuilder<string, int>` pattern that constructs minimal flows with integer context. New method variants (e.g., `RunObserved`) should have tests added directly to the existing flow test file using the same builder pattern — not in a new file or with a heavier fixture. The test effort is Small: the observer can be a local `LambdaObserver` record or anonymous implementation; the flow needs only 2–3 steps; the assertions are straightforward invocation counts or context values.

---

## Flow-Level Branch Coverage Is Distinct From Decision-Class Coverage

**Category: Process/Model**

When a codebase uses a flow/pipeline pattern where decisions are unit-tested in isolation and mocked at the flow level, the decision class tests can be thorough while the flow-level wiring of the `ifYes` branch is entirely untested.

**Signal to look for**: In flow test `[SetUp]`, if a decision is always mocked to a single value (e.g., always `false`) and no test overrides it to the opposite value, the alternate branch is not covered at the integration level.

**Recommended check**: For every `flow.Decide(...)` in a flow under test, both `ifYes` and `ifNo` branches should have at least one flow-level test. Rate the absence of one branch as **Medium** (not High) when the decision class itself is thoroughly unit-tested — the risk is wiring inversion, not logic error.

---

## Parametrization Consistency Reveals Coverage Asymmetry

**Category: Process/Model**

When multiple test methods in a parametrized test class use a `[Values] bool sideFlag` to cover left/right or similar asymmetry, but one test method drops that parameter and hard-codes a single case, flag it as a low-priority gap. The inconsistency is a documentation signal: the invariant (that both sides behave identically via `||` logic) is implicit rather than explicit. Recommend adding the parameter for consistency, not correctness.

---

## Test Case Name States a Return Value That Contradicts `.Returns()`

**Category: Process/Model**

When a `[TestCaseSource]` test has a `.SetName("... returns true")` but `.Returns(false)` (or vice versa), flag it as a **Medium** misleading test name. This pattern occurs when the test name describes the filtering intent ("these checks are ignored, and therefore something else returns true") but is then shorthand-corrupted to describe the overall expected result incorrectly.

- The assertion is correct; only the name is wrong.
- The severity is Medium (not Low) because test names are documentation. A future reader inferring the filter's behavior from test names will draw the wrong conclusion.

---

## Cross-Auditor Regression Test Mining: When Correctness Audit + Zero Tests Coincide

**Category: Process/Model**

When a code correctness audit has already run AND the unit test coverage audit finds zero test coverage, the confirmed bugs from the correctness audit should be **directly translated into regression test cases** with exact inputs and expected outputs in the coverage audit report. Do not merely recommend "add tests for the inference engine" — provide concrete `[TestCase]` inputs that reproduce the specific confirmed bugs.

This serves three purposes:
1. The developer can write the regression test immediately, before fixing the bug, to confirm the bug is reproducible
2. The regression test documents the pre-fix behavior (even if wrong) so the fix can be verified
3. The test prevents the bug from being silently re-introduced in future keyword/formula edits

For keyword-array bugs specifically: compute the exact keyword that matches, why it double-counts, and what score the engine produces vs what score is correct. Show both the buggy and correct expected values so the test can be written for the fixed behavior.

---

## Zero-Coverage Codebases: Prioritize by Architecture, Not Just Risk

**Category: Process/Model**

When auditing a codebase with zero test coverage, the instinct is to rank test targets purely by business criticality. However, **testability architecture should co-rank** the priority list. A pure stateless class (no mocks, no DI, no I/O) with confirmed bugs should be ranked HIGHER than a similarly important class that requires database setup — even if the database class has a higher overall risk score.

This is because the pure-function tests:
- Can be written in minutes (not hours)
- Run in <1ms per test
- Have no flakiness risk
- Produce a multiplicative coverage gain per line of code

Practically: mark pure-function engine tests as Critical regardless of the application tier they belong to, if they contain confirmed algorithmic bugs. Mark infrastructure-dependent tests (EF Core, DbContext) as High even for equally important behavior, because the setup cost delays developer adoption.
- The recommendation is a rename that describes what the input contains and what the actual return value is: `"[CheckType] is excluded by filter, returns false"` rather than `"[CheckType] returns true"`.
- Do not conflate this with the toggle-state mismatch lesson — here the fixture state is fine; only the name property on the test case data is wrong.

---

## `[NotifyCanExecuteChangedFor]` Attribute Not Reflected in CanExecute Guard Is a Vestigial Code Signal

**Category: Process/Model**

When auditing CommunityToolkit.Mvvm (or similar MVVM) codebases, check whether every `[NotifyCanExecuteChangedFor(nameof(XCommand))]` attribute on a property is actually referenced inside the corresponding `CanX` method. If the attribute fires `CanExecuteChanged` but the guard doesn't read that property, it is either:

- Vestigial: the property was once part of the guard, removed during a refactor, but the attribute was left behind
- Incomplete: the guard *should* depend on the property but is missing the check (potential bug)

**How to flag it:** Mark as **Medium** — the notification machinery is wasted overhead and could mislead a developer into thinking the property contributes to the command's enabled state. A test that changes the property and asserts `CanExecute` remains unchanged will document the vestigial nature and catch any accidental future dependency.

**Recommended test naming**: `CanX_IsIndependentOf{PropertyName}` — this name serves as living documentation that the attribute is deliberately vestigial (if the test is kept) or triggers an investigation (if a developer sees the test fail after adding a dependency).

Do not silently accept the attribute as "harmless overhead" — always surface it so the developer can decide whether to remove the attribute or add the missing guard check.

---

## Collection-Add Tests That Assert Only Count Are Insufficient for Identity-Critical Logic

**Category: Process/Model**

When auditing a test for a method whose purpose is to add a *specific item* to a collection (e.g., adding a minimum-constraint to a constraint list, adding a key to a set), check whether the assertion verifies only the count:

```csharp
Assert.That(constraints.Count(), Is.EqualTo(1));  // ← count-only
```

A count-only assertion cannot catch a bug that adds the *wrong* item. If the item identity is load-bearing (e.g., "the constraint locks to `Next.Item`, not `Current.Item`"), a regression that uses the wrong source value still produces a collection with exactly one element.

- Flag as **Medium** when the item identity is the correctness-critical invariant (not a cosmetic property).
- The recommended fix is to either (a) assert a meaningful property of the added item (e.g., its minimum material, its key value), or (b) add a complementary negative test using inputs that would produce a different item, proving the assertion would fail with the wrong item.
- When the item type is opaque (no public property to assert on), recommend an `Apply()` / `Filter()` round-trip test: build a list, apply the constraint, and verify the filtered list matches the expected post-constraint state.

---

## Cross-Check Prior Audit Recommendations Against Actual Test Files

**Category: Process/Model**

When requirements-audit or code-correctness-audit reports have already been written, extract their "missing test" and "recommended test" entries explicitly before writing the coverage report. Do not assume those recommendations were implemented — check each one against the actual test files. Prior audits naming untested paths are high-confidence pointers to real gaps.

---

## State Reset Methods Need Tests for Every New Field Added

**Category: Process/Model**

When a class with a `Reset()`, `Clear()`, or `Initialize()` method gains new mutable fields, the test for those methods must be updated. The absence of a test file for the class in the changed test set is the diagnostic signal — if the production class is in the diff but no corresponding test file is, check explicitly whether the reset behavior is covered anywhere. This matters most when the feature's correctness contract depends on the fields being properly cleared (e.g., a null-guard in a downstream step relies on these being null after reset).

---

## Moq Void-Method Defaults Silently Pass `Times.Never` Gaps

**Category: Process/Model**

In tests that verify "method A was called once" (via `Verifiable(Times.Once)`), the absence of a `Times.Never` assertion for a related "method B" is not caught by Moq — void methods default to no-op when called without setup. When two independently guarded code blocks each call a different method (e.g., restore component A vs. restore component B), both the positive assertion (called once) and the negative assertion (other method never called) are needed for the test to be complete. Flag the missing `Times.Never` assertions as Low when the independence is structurally clear in the code but not enforced by the test.

---

## Shared Fixture Helpers That Are Only Used by Sibling Test Classes

**Category: Process/Model**

When a test file contains multiple [TestFixture] classes that share a base class, helpers in the base class may be designed for one fixture but never invoked by another. This is a coverage illusion: you can see a helper that creates alternative input types (e.g., type A, type B), assume those types are tested by the primary fixture, and miss that the helper is only called by a sibling fixture in the same file.

Detection pattern: when a guard is added to a method (e.g., `early return for non-primary input types`), check the primary fixture class in isolation — not the shared base class — for a test that actually invokes the guard path. If the helper that creates the non-primary type appears only in the fixture for a different calculator or component in the same file, the guard is untested.

Flag as **Medium** when:
- The guard is new code added in the PR under review, AND
- The shared helper that could test it exists but isn't called from the primary fixture

---

## Adapter/Mapper Configuration Round-Trip for Newly-Added Nullable Fields

**Category: Process/Model**

When a PR adds a new nullable field to a DTO that is the target of an adapter (Mapster, AutoMapper, or similar) or MessagePack serialization, check whether a round-trip test exists that (a) maps the DTO with a non-null value for the new field, and (b) maps back and asserts the value round-tripped correctly.

The failure mode: the mapper configuration .Map(dest.NewField, ...) is correct at time of writing, but a future refactor of the source expression (e.g., changing the lambda from IfHasValue to direct property access) breaks the mapping silently. Without a round-trip test, this regression is only caught by integration tests.

Flag as **Medium** when:
- The new field uses a non-trivial expression in the mapper config (unit conversion, optional/nullable coercion, extension method call), AND
- No round-trip test for that field exists

Flag as **Low** when:
- The field is a direct property assignment with no transformation

---

## Integration Test Helpers That Manually Construct Objects Bypass Production Factory Code Paths

**Category: Process/Model**

When a refactoring introduces a factory class (e.g., `ComponentFlowFactory`) whose job is to construct objects previously built inline, check whether existing integration tests have a local helper method that also constructs those same objects directly. This helper method is a "parallel construction path" — it was written before the factory existed and was never updated to route through the factory.

The danger: all integration test assertions pass because the objects produced by the helper are correct. But the factory's code path (including any toggle branch, positional argument wiring, or runtime parameter threading) is never executed by any test. A bug in the factory is undetectable.

**Detection pattern**: Look for integration test fixture methods named `Create[Thing]()`, `Build[Thing]()`, or `Setup[Thing]()` that construct the same type the factory produces. If those methods predate the factory, they are bypasses.

**Recommended action**: Flag as **High** when:
- The factory contains branching logic (toggle conditions, conditional assembly) AND
- The integration test helper constructs the same objects manually without using the factory

**Recommended fix**: Update the helper to instantiate the factory (with already-resolved DI services) and call `Build()`. This is typically a direct substitution with no test behavior change.

This pattern is most common in codebases that refactor from "inline construction" to "factory" while leaving legacy integration tests untouched. The work item that introduces the factory often has an acceptance criterion that "test infrastructure is unchanged" — this is true at the mock/interface level, but should not be interpreted as "integration test helpers may keep bypassing the factory."
