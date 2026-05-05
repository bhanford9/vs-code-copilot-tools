# Lessons Learned: REVIEW-UnitTestCoverageAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future unit test coverage reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## Dead Toggle Assertions in Test Fixtures

**Category: Process/Model**

When reviewing tests that gate assertions on a feature toggle, check whether the toggle instance used in the fixture (`_toggles = ToggleBuilder.AllDisabled().Build()`) makes any `if (_toggles.IsEnabled(...))` assertion branches permanently dead code. This pattern is common when a developer adds toggle-aware test branching but forgets to create a second toggle instance with the toggle enabled.

- Rating this as **Critical** is correct when the dead branch is the primary behavior change under test (not just a parallel path).
- Do NOT downgrade to Medium just because the developer has written the expected-log arrays — the arrays being present means they thought about it, but the code never executes.
- Recommend: extract to parameterized `[TestCase(true/false)]` pattern OR add a parallel `_togglesOn` fixture field. Both are valid; mention both so developer can choose.

---

## Check Test Geometry for Degenerate Cases When Auditing Numeric Fixes

**Category: Process/Model**

When reviewing a fix that changes a distance calculation (e.g., Euclidean → chord-parallel, absolute → projected), always check whether the test geometry is degenerate for that distinction. Horizontal edges, perpendicular projections, and axis-aligned scenarios often produce identical values under both the old and new calculation. If the only test geometry is degenerate, the core fix is untestable and the test provides false confidence. Look for an explicitly non-degenerate geometry (e.g., a sloped chord, an angled projection) before concluding the fix is tested.

---

## Known-Gap Requirements Should Always Have a Test — Even a Documenting One

**Category: Process/Model**

When a requirements audit or correctness audit identifies a known implementation gap (e.g., missing `Math.Max` floor), always check whether the test suite has a test that documents the current incorrect behavior. If not, this is a coverage gap regardless of whether the gap is "acknowledged." A test that asserts the current (wrong) behavior prevents silent fixes and regression in either direction. Flag the absence of such a test as High priority even when the gap itself was flagged by a prior audit.

---

## Bounded Assertions (`Is.GreaterThan`) Are Red Flags for Core Fix Tests

**Category: Process/Model**

When a test uses `Is.GreaterThan(x)` or `Is.LessThan(x)` for the single test case that exercises the feature's core correctness (e.g., "sloped joist produces longer distance"), flag it as a weak assertion. The test proves the direction of change but not the magnitude. Any implementation that produces a result in the right direction (but wrong magnitude) passes. Recommend replacing with an exact expected value derived from the test geometry.

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
- Combine this observation with a check of whether the new code path's equivalent guard (e.g., same `EffectiveDepth` check in a different method) has any test at all with the toggle enabled.

---

## Test Case Name States a Return Value That Contradicts `.Returns()`

**Category: Process/Model**

When a `[TestCaseSource]` test has a `.SetName("... returns true")` but `.Returns(false)` (or vice versa), flag it as a **Medium** misleading test name. This pattern occurs when the test name describes the filtering intent ("these checks are ignored, and therefore something else returns true") but is then shorthand-corrupted to describe the overall expected result incorrectly.

- The assertion is correct; only the name is wrong.
- The severity is Medium (not Low) because test names are documentation. A future reader inferring the filter's behavior from test names will draw the wrong conclusion.
- The recommendation is a rename that describes what the input contains and what the actual return value is: `"[CheckType] is excluded by filter, returns false"` rather than `"[CheckType] returns true"`.
- Do not conflate this with the toggle-state mismatch lesson — here the fixture state is fine; only the name property on the test case data is wrong.

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
