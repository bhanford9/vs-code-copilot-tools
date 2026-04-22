# Lessons Learned: REVIEW-UnitTestCoverageAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

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
