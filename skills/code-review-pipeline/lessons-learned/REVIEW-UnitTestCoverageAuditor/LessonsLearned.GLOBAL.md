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

## "Met" in Requirements Audit ≠ "Tested" in Coverage Audit

**Category: Process/Model**

When the requirements auditor marks a requirement as "✅ Met" and cites a production code location as evidence (e.g., a try/catch wrapping a write call), that is a code-inspection finding — not a test finding. The coverage auditor must independently verify that a test would detect a regression at that callsite.

The failure mode: the requirements auditor finds the code, marks it Met, cites the file location, and the coverage auditor (or a subsequent reviewer) treats the Met status as proof of test coverage. It is not. A requirement can be correctly implemented and have zero regression-catching test coverage simultaneously.

Concrete check: for each "✅ Met" requirement in the requirements audit, identify the specific production code line that implements it, then ask: "if I deleted this line or removed the callsite entirely, would any test fail?" If the answer is no, that is a High-priority coverage gap regardless of the Met status.

---

## Filter-Before-Assert Trap: Broad Query Tests Create Silent Blind Spots

**Category: Process/Model**

When an integration test queries a broad result set (e.g., all records written during a multi-step operation) and then applies an in-test filter before asserting, the records excluded by the filter represent untested behavior. The test gives the appearance of exercising the full operation, but the excluded records' fields — and even their existence — are never verified.

This pattern appears most often when a test exercises a multi-step operation: Step A produces records R1..Rk, Step B produces Rk+1..Rn. The test asserts on Rk+1..Rn and silently discards R1..Rk with a filter. A test comment may even list the expected full record breakdown — but listing is not asserting.

Check to apply: when a test filters an aggregate result set before asserting, identify what was filtered out and ask whether those filtered records correspond to a separate requirement. If yes, that requirement's coverage exists only in a code comment, not in a test assertion. Flag as a High gap.

---

## Deleted Guard = Required Replacement Test (High, Not Low)

**Category: Process/Model**

When a filter, guard clause, or conditional block is deleted from production code, the test that verified
the old guard is correctly deleted with it. But the audit must check whether a **replacement test** was
written to document the new inclusive behavior. The absence of such a test is a **High** gap, not Low —
the deletion is the most significant behavioral change in the change set and has no regression net.

Pattern to flag: "deleted test verified old guard; no new test verifies new behavior."

Correct severity: **High** when the deleted guard was the only filter on a production data flow.
Do not soften to Low just because the deletion was intentional — intentional changes need tests too.

---

## Zero-Test Subsystems Require Infrastructure Assessment First

**Category: Process/Model**

When reviewing a zero-test subsystem, lead the report with an infrastructure assessment before any per-requirement coverage table: What test framework/mocking library does the solution use? Are the critical methods `public`, `internal`, or `private static`? Are dependencies interface-typed (trivially mockable) or concrete (testability gap)? Name any access-modifier blocker (e.g., `private static` security methods requiring `InternalsVisibleTo`) as a prerequisite blocker, not a recommendation.

Rate the overall score 0/10 ("Inadequate") — do not soften to "Poor" just because the production code is logically correct.



---

## Security-Critical Private Static Methods Are a Test-Pyramid Blind Spot

**Category: Process/Model**

When a feature introduces `private static` methods for security validation (URL guards, input sanitizers, permission checks), flag missing tests as **Critical** — E2E happy-path coverage is insufficient because (a) adversarial inputs aren't exercised and (b) the `private` modifier physically blocks unit testing without a code change.

Flag as **Critical** when the untested method is the sole CI gate for a known attack vector (open-redirect, injection, path traversal). Always name the structural change required (`internal static` + `[assembly: InternalsVisibleTo(...)]`) as part of the finding.

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

## Prior-Audit Bugs Without Regression Tests Are Always Critical

**Category: Process/Model**

When a requirements audit or correctness audit in the same review pipeline has already identified a specific bug (e.g., a race condition, a counter corruption, a security bypass), and the unit test coverage audit finds no regression test for that bug, classify the missing test as **Critical** — not High or Medium.

Rationale: the prior audit provides proof that the bug exists and specifies its mechanism precisely. The coverage auditor is no longer speculating about risk; they are reporting a known bug with zero test protection. The combination of "confirmed bug" + "no regression test" is the highest-risk test gap that can exist.

Apply this escalation rule automatically when:
1. The correctness or requirements audit has a named, rated issue (e.g., CC-01, GAP-01)
2. The unit test coverage search finds no test that could catch that specific failure mode
3. The bug has a mechanism that a unit or integration test could realistically trigger

---

## Identical-Score Top-N Test Anti-Pattern

**Category: Process/Model**

When auditing a "take top N, ordered by X" feature, check whether the N-cap test uses identical X values for all items. If all items share the same ordering value, the test only verifies that `.Take(N)` limits the count — it does NOT verify that the correct N items are selected. With equal values, any N items could be returned and the test would pass.

The definitive test for this feature requires:
1. Seed **more than N** items with **distinct** ordering values.
2. Assert that the returned set contains **specifically the highest-N** ordering values (not just any N).

A test that seeds 8 equal-score items and asserts `count == 5` is a false-confidence test. Recommend adding the district-score variant as High priority (or Critical if the feature is also missing the descending-order test).

---

## Command Handler Output-Write Coverage Is Systematically Under-Tested

**Category: Process/Model**

When reviewing a suite of command handlers that all follow a two-step pattern (service call + output write), check each handler's test for **both** assertions separately. A handler test that only verifies the service call but omits the output-write assertion is a very common gap — developers tend to write the "important" assertion first and ship without the second.

Audit strategy: for each handler class, explicitly verify that at least one test calls `mock.Output.Verify(o => o.WriteJson(...))` (or the equivalent for the output abstraction in use). Do not assume that "the service call was verified" implies "the output was verified." These are independent operations that can each fail independently.

Rate missing output-write assertions as **Medium** for each handler. If the group of handlers with missing output assertions also includes the only destructive/irreversible handler in the suite (e.g., delete), raise that specific handler to **High**.

Do not apply this rule to speculative issues or "could potentially" scenarios from the prior audits — only to findings rated High or Critical by the prior auditor.

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

## Cross-Fixture Gap Checks: Prior-Audit Gaps May Be Covered by a Different Test Fixture

**Category: Process/Model**

When a prior audit (requirements or correctness) lists a named coverage gap, always search for the test across ALL test fixtures before confirming the gap is open. Developers frequently place a behavioral test in the semantically closest fixture (e.g., a feature-level test rather than a view-level test), which causes the gap to appear uncovered when scanning only the "expected" file.

Concrete check:
1. For each gap in the prior audit, extract the assertion it would make (e.g., "assert X does not appear in view Y when condition Z").
2. Search all test files for that assertion pattern — not just the fixture named in the gap description.
3. If found in any fixture, mark the gap as **Closed** in your report and note the actual file.

Omitting this cross-fixture search is the primary cause of false-positive "gap" findings in coverage audits.

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

---

## DI Module Change Sets Require Per-Module Coverage Assessment

**Category: Process/Model**

When a change set's primary deliverable is N new DI extension method files (one per layer), audit each module individually for test coverage — do not stop at the first layer that has tests.

The failure pattern: the "core" or "data" layer gets an integration test suite, so the DI graph is exercised implicitly. The developer (and the reviewer) feel the wiring is verified. But the other layer modules (UI/ViewModel, Web host, CLI dispatch) have zero test coverage and any misconfiguration in them is invisible until the host starts.

Key check: count the new DI extension methods introduced by the change set, then verify each has at least one test that calls `BuildServiceProvider()` and resolves a registered service. A smoke test is sufficient — it just needs to confirm the container builds and the key interfaces resolve without exception.

Rate each untested DI module as **Critical** if it is a new file added by this PR (the PR author chose to create it; not testing it is a deliberate omission) and **High** if it is an existing file with new registrations added.

---

## Optional Test Infrastructure Parameters Should Be Exercised by At Least One Test

**Category: Process/Model**

When reviewing test infrastructure that accepts optional injection parameters (e.g., a factory method with a nullable `TimeProvider`, `LoggerFactory`, or similar), always check whether any test actually passes a non-null value.

The failure pattern: a developer adds `Create(TimeProvider? timeProvider = null)` to the test helper to enable controlled-clock testing. All time-sensitive assertions in the suite use a tolerance window (`BeCloseTo(..., precision: Xs)`) rather than exact equality. The parameter is present but serves no test. The infrastructure investment produces no test quality benefit.

Flag this as **High** when the time-tolerance window causes genuine flakiness risk (e.g., 5-second windows under slow CI). Flag as **Medium** when tests pass reliably in practice.

Recommend: Add one test that exercises the injection path with a fixed value and asserts exact equality. This establishes the pattern for future contributors and eliminates the tolerance window for that assertion.

---

## Behavioral Tests Do Not Substitute for DI Aliasing Identity Assertions

**Category: Process/Model**

When a DI registration uses an aliasing pattern (multiple interfaces → single instance, via factory lambdas that call `GetRequiredService<ConcreteType>()`), always check whether any test explicitly asserts object identity across the interface lookups.

The failure pattern: integration tests exercise the service via two different interface handles in the same scope. The tests pass. But the aliasing invariant — that both handles return the same object reference — is never explicitly asserted. A refactor that replaces `sp.GetRequiredService<ConcreteType>()` with `new ConcreteType()` (double-instantiation) would satisfy all behavioral tests while silently breaking the invariant.

Rate a missing identity test as **Critical** when:
- The aliased service has stateful infrastructure (e.g., an ORM change tracker) where two instances per scope produce inconsistent-read or lost-update bugs.
- The aliasing is the mechanism for enforcing that constraint.

Recommended test shape: resolve the concrete type directly, then resolve each interface. Assert each interface result `IsSameAs` the concrete instance. This is a 5-line test that permanently nails the invariant.

- The assertion is correct; only the name is wrong.
- The severity is Medium (not Low) because test names are documentation. A future reader inferring the filter's behavior from test names will draw the wrong conclusion.

---

## E2E Tests That Verify Encoding Are Not the Same as Tests That Verify Filtering

**Category: Process/Model**

When reviewing a feature that redirects users with a parameter (e.g., a post-auth return URL, a callback path), look for two distinct test requirements:

1. **Encoding test** — verifies that the parameter appears in the redirect URL when it should. (The "happy path" — valid input is preserved.)
2. **Filtering test** — verifies that invalid or dangerous input is rejected or sanitized. (The "security path" — bad input is blocked.)

The failure pattern: the test suite has a well-written encoding test that confirms the parameter survives the redirect. The developer and reviewer both feel "the ReturnUrl is tested." But the filtering step lives in a different method — often a private helper — and no test passes a malicious value to assert the filter actually fires.

This is especially common for open-redirect guards, where the "allowed" path is tested by E2E scenarios that exercise normal navigation, but the "blocked" path (an absolute URL or protocol-relative URL passed as the parameter) is never tested at any level.

**Detection signal**: Search for the filter method. If it is `private static`, it is only reachable through the enclosing class and typically only via E2E tests. Ask: "Does any E2E test pass a value that should be rejected?" If no, the security invariant is untested.

**Recommended action**: Rate the missing filter test as **Critical** when the feature has an explicit security requirement (open-redirect, injection, SSRF) and the filter method has no tests. Suggest either: (a) make the method `internal static` with `InternalsVisibleTo` for pure-logic unit tests, or (b) add a dedicated E2E test that supplies a rejected value and asserts the safe fallback behavior.

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

---

## Contract Error Table Rows Must Each Have a Corresponding Test

**Category: Process/Model**

When a contract document contains an explicit table of "verified error message patterns," treat each row as a test requirement. Developers frequently write the error table after writing the tests — and occasionally document a pattern that was planned but never actually verified. During audit:

1. Enumerate every row in the error pattern table.
2. For each row, search all test files for a test that (a) triggers the documented condition and (b) asserts the documented stderr substring.
3. If any row has no matching test, rate it **Critical** — the contract claims the test exists.

A row with no test is not merely a coverage gap; it is a false assertion in a document that is consumed by agent frameworks as ground truth.

---

## Soft-Delete Contracts Have Two Testable Halves — Both Required

**Category: Process/Model**

When a CLI or API has a soft-delete pattern, the contract typically documents two behaviors: (1) the deleted item does NOT appear in the default list, and (2) the deleted item DOES appear when an explicit "include all" flag is used. Coverage audits consistently find the first half tested and the second half absent.

Flag the missing second half as **High** — it is a distinct clause that agent consumers rely on for auditing task history, and it is easily verified with a 5-line test. Never accept "the delete test covers soft-delete behavior" without explicitly checking that `--status all` (or the equivalent) is also exercised.

---

## Exit Code Precision Is a Separate Assertion From Exit Code Existence

**Category: Process/Model**

A test that asserts `.ExitCode.Should().NotBe(0)` and a test that asserts `.ExitCode.Should().Be(1)` are not equivalent when the contract specifies exact exit codes. In any CLI contract suite, distinguish between:

- **Presence tests** (`.NotBe(0)`) — confirm something went wrong; accept any non-zero code
- **Precision tests** (`.Be(1)`) — enforce the documented contract value; catch both silence bugs AND wrong-code bugs

When the contract document explicitly states "Exit code 1", every error-case test should use `.Be(1)`. An unhandled exception that produces exit 2 passes all `.NotBe(0)` tests — silently, with no diagnostic. Flag the pattern as **Critical** when it covers all error cases in the suite; flag as **Medium** when mixed usage exists.

---

## "All Fields Present" Tests Prevent Silent Rename/Removal Regressions

**Category: Process/Model**

Contract suites for JSON APIs commonly verify the values of commonly-used fields while leaving 30–50% of the documented schema fields unasserted. A single test that walks the complete documented field list (using a string array of expected property names) provides permanent regression protection for the entire schema at near-zero ongoing maintenance cost.

Recommend this test whenever:
- The contract document specifies a complete object shape (e.g., "every task-returning command outputs this full object")
- At least half the documented fields are never asserted in any test

The test effort is Small (5–10 minutes). The gap it closes is High — any field rename, removal, or JSON serialization attribute change is instantly caught without requiring the tester to know which command returns which field.
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

---

## Fixed-Time Wait for Negative Assertions Is a Test Quality Anti-Pattern in Browser Tests

**Category: Process/Model**

When reviewing UI or browser tests (Playwright, Selenium, etc.) that verify a redirect or navigation did NOT occur, check whether the test uses a fixed-time wait (e.g., `Task.Delay(N)`) before asserting the current URL. This pattern is fundamentally fragile:

1. **False positives on slow machines / loaded CI:** If the page hasn't fully settled within the fixed delay, the assertion fires before the application has had a chance to redirect. The test "passes" even though the redirect might still arrive a fraction of a second later.
2. **Wasteful on fast machines:** A 2-second wait is unnecessary overhead when the page settles in under 200ms on a local developer machine.

**Correct approach for negative assertions in browser tests:** Use the framework's network-idle or DOM-stable signals instead of fixed delays. For Playwright, `WaitForLoadStateAsync(LoadState.NetworkIdle)` waits until there are no in-flight network requests for at least 500ms — a semantically correct signal that the page has settled. Alternatively, assert on the presence of a DOM element that only appears in the expected final state; this both waits for page settlement and provides a stronger positive assertion.

**Severity guideline:** Flag as **Medium** — the test exists and covers the scenario, but the assertion mechanism can produce non-deterministic results under load. It is a quality issue, not a coverage gap.

---

## Test Strategy's Explicit "Code Review" Designation Lowers Coverage Gap Severity to Low

**Category: Process/Model**

When a formal test strategy document (e.g., a `test-strategy.md` file in a feature packet) explicitly designates a scenario as "code review only" rather than an automated test, flagging the absence of an automated test for that scenario as a **High** or **Critical** gap is a false positive. The strategy document is an intentional, authored decision — it reflects an engineering judgment that automation adds insufficient value to justify the cost for a particular structural or review-time constraint.

**Correct handling:**
- Record the absence as **Low** severity
- Note that the designation was deliberate and reference the strategy document
- Recommend either (a) honoring the designation with a written code-inspection statement in the traceability file, or (b) optionally upgrading to a structural automated test if future maintainability is a concern

**When to escalate anyway:** If the "code review" designation covers a security-critical behavior (not just a structural/formatting constraint), escalate to **Medium** and explain why automation would provide meaningful protection that code review alone cannot. Do not accept "code review" as a blanket excuse for skipping tests on security guards.

**The primary false-positive pattern to avoid:** Reading a test strategy that says "SCEN-X: code review" and then flagging "SCEN-X has no automated test — High gap." The strategy was read; it said code review; that is the answer.
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

---

## Security-Requirement Message Identity Tests Require Exact Assertions, Not Wildcards

**Category: Process/Model**

When a requirement states that two error paths MUST produce identical messages to prevent information leakage
(e.g., "resource not found" and "resource exists but belongs to another tenant" must look the same to
callers), tests for each path are commonly written with wildcard matchers (e.g., `*{id}*`) rather than
exact string assertions. The wildcard correctly verifies the exception type and the presence of an ID, but
does NOT verify message identity between the two paths.

Pattern to flag: a security requirement states "messages must be identical," and the IDOR/mismatch test
uses `.WithMessage("*{id}*")` or equivalent. The gap: a future change that adds distinguishing text to
one path (e.g., "access denied" suffix on the mismatch path) will still pass all tests.

**Concrete check**: for every pair of (not-found, mismatch) tests, verify both paths are asserted against
the **same exact format string**, not wildcards. If not, flag as Medium.

**Recommended fix**: Replace wildcard assertions with the exact expected message string. This is a trivial
one-line change per test that directly encodes the security requirement as an executable assertion.

Severity: **Medium** — the code is typically correct at review time, but the test cannot protect against
future regression that violates the non-existence-leak guarantee.

---

## 2026-05-31 — Throw-Swallow Tests Must Verify the Attempt, Not Just the Swallow

**Pattern**: A test that validates resilience behavior ("primary action must succeed even when dependency throws") sets up a mock with `ThrowsAsync(...)` but never calls `Verify(...)`. The test only asserts `NotThrowAsync()` or that the primary side-effect persisted. If the entire try block (including the call to the dependency) is deleted, the mock never fires, the primary action still succeeds, and the test remains green.

**Why this matters**: The test describes a two-part contract: (1) the dependency must be attempted, and (2) its failure must be swallowed. The `ThrowsAsync` setup exercises part 2 only if part 1 also holds. Without a `Verify(Times.AtLeastOnce())`, part 1 is untested. The `ThrowsAsync` setup becomes theater — it proves nothing about the call being made.

**Detection heuristic**: In any fault-injection test that uses `ThrowsAsync` or `ReturnsAsync(throw-equivalent)`, check whether the test also asserts that the mock method was called (via `Verify`, `VerifyAll`, or equivalent). If not, flag Medium.

**Recommendation**: Add a `Verify(a => a.TargetMethod(It.IsAny<...>()), Times.AtLeastOnce())` call before the primary-persist assertion. This pins both halves of the resilience contract in one test.

---

## `Async` Suffix in Test Names for Synchronous Methods

**Pattern**: Test method names using an `Async` suffix when the method under test is synchronous — e.g., a test named `MethodAsync_Condition_Result` that actually calls `Method()`. These tests are invisible to `Method_*` coverage searches and create naming ambiguity if a true async overload is added later.

**Action**: Always verify the test method name prefix matches the production API (sync vs async). Flag as Medium if the mismatch exists, especially when multiple tests share the pattern — it suggests a copy-paste origin.

---

## Implicit Enum Default in Test Object Initializers Is a Hidden Contract

**Pattern**: When a test initializes a data-transfer object (e.g., a grant, an override, a configuration entry) and omits an enum property, the C# default value `0` is silently used. Tests pass when the test context's corresponding filter field also defaults to `0` — but this is coincidence of enum ordering, not intent. If the enum is ever extended or reordered, or if the pattern is copy-pasted for a different enum variant (e.g., initializing a Workflow-scope test from a Board-scope template), the omitted property causes the test to silently exercise the wrong branch.

**Severity guidance**:
- **Medium**: The omission is systemic across multiple test methods, the enum is likely to be extended, or the filter that consumes the field is a load-bearing correctness path (e.g., scope isolation in an authorization engine).
- **Low**: Single occurrence, enum is unlikely to change, and the omission is obvious from context.

**Action**: When reviewing test initializers for value objects that participate in filtering or matching logic, check whether all semantically relevant enum properties are set explicitly. Flag any case where the correct behavior relies on `0` being the right enum value rather than an explicit assignment.

---

## 2026-05-29 — bUnit Installed But Zero Component Tests Is a Distinct Medium Finding

**Pattern**: When a project adds bUnit to the test project (often as part of a feature that introduces Razor components with testable logic), but no bUnit component tests are written, the infrastructure investment delivers no value. This is a distinct Medium finding — not "bUnit is missing" (a different problem) but "bUnit is present but unused despite the auth/UI components having logic worth testing."

**Testability signal**: Check the test project `.csproj` for a `bunit` package reference. If present, check whether any `TestContext`-based component tests exist for the changed Razor components. If the components have `@code` blocks with lifecycle methods (`OnParametersSet`, `OnInitializedAsync`) that contain branching logic, and no bUnit tests exist for them, flag as Medium.

**Why this matters**: Component lifecycle logic tested only via E2E has no fast feedback path. A bUnit test for `OnParametersSet()` error parsing runs in milliseconds vs. seconds for an E2E test. The finding should call out specific component methods that benefit from bUnit coverage.

---

## 2026-04-23 — Fallthrough tests that assert `Is.False` cannot distinguish fell-through from prematurely-returned

**Pattern**: When a test's stated intent is "verify that code falls through block X to reach block Y," but the test arranges block Y to return `false` and asserts `Is.False`, the assertion is satisfied by two structurally different outcomes: (a) correctly fell through and Y returned false; or (b) X returned false prematurely before reaching Y. The test's structural validity depends on the code having no false-returning path inside block X — a future refactor could silently break the contract without failing the test.

**Testability signal**: Look for fallthrough-intent tests that only assert `Is.False` with a non-discriminating downstream scenario. The fix is always to add a companion case where block Y returns `true` (i.e., arrange Y's preconditions for a true result) and assert `Is.True` — this result is unreachable unless block X fell through.

**Recommendation**: Flag as medium-priority. The code may be logically sound today, but the test does not serve as a long-term regression guard for the fallthrough contract.

---

## 2026-05-31 — Parallel Test-Cleanup SQL Is a Multi-Way Co-Evolution Target

**Pattern**: When a codebase has multiple test base classes (integration, API, E2E), each often maintains its own TRUNCATE or DELETE SQL block for database cleanup between tests. When a new table is introduced, the author updates the test base class used by the new feature's own tests but omits the parallel implementations in other test base classes. The omitted bases don't fail immediately — either no tests in those suites exercise the new table yet, or they exercise it through the UI without asserting record counts — so the gap is silent.

**Why it persists**: The author updates the base that makes the new tests pass. The other bases appear unrelated because their current tests don't touch the new table. The absence looks harmless until a future test asserts record isolation.

**Heuristic**: When a diff introduces a new database table, grep for every occurrence of `TRUNCATE`, `DELETE FROM`, or equivalent cleanup SQL across ALL test files — not just the ones in the same project as the new tests. Enumerate the table lists in each occurrence and compare them against each other. Any table present in one implementation but absent in another is a gap candidate. Classify as High if the test base already covers the feature whose operations write to the new table (records will definitely accumulate); Medium if the base is currently out of scope for those operations (records could accumulate when a future test exercises the feature).

---

## A count-based test assertion on a derived set does not guard against omissions from the source

**Date**: 2026-05-30
**Category**: Process/Model

When a codebase maintains two parallel structures — a set of named constants (the source) and a manually-populated aggregate collection derived from them (e.g., a validation set, an "all items" catalog) — a test that only asserts `derivedSet.Count == N` is **not a complete safety net**. The count assertion catches: extra entries in the set (count goes up) and accidentally removed entries (count goes down). It does NOT catch: adding to the source but forgetting to add to the derived set, because in that case the derived set count remains N and the test passes. When this pattern appears (source grows by one, derived set omission, count unchanged), the failure mode is typically a silent security-relevant regression — the new constant is treated as unknown and produces a blanket deny without any test failure or compile error. **Rule:** When reviewing a manually-maintained aggregate that is tested only by count, rate the sync gap as **High** (not Medium) if the omission scenario would cause a silent security or authorization regression. Recommend a reflection-based membership test as the fix — enumerate all source values and assert each one is present in the derived collection. The count test can remain as a secondary assertion against duplicates; it is not sufficient as the primary guard.

---

## Action Loop and Audit Loop Divergence

**Category**: Process/Model

When a service method contains two separate iteration loops — one that filters a collection at the action stage (e.g., "skip this item because of a race condition") and a second that iterates the original *input* collection at the audit stage — the two loops can diverge. Items that were skipped by the action loop are still processed by the audit loop, producing phantom audit records that claim an action occurred when no change was actually made.

The coverage auditor should check: when a "no-op / skip" path is tested at the action layer, is the same scenario run through the audit layer? The test for "item skipped, no change made" does not automatically cover "no audit record written for the skipped item."

Concrete check: in any method where an action loop and an audit write loop iterate over different collections (or where one loop contains a `continue` that the other does not), verify that a test exercises the skip path and asserts the audit output, not just the action output.

Severity of this gap: Medium when the action is non-destructive; High when the audit trail is a compliance-grade append-only ledger, because phantom records produce false positives in forensic queries.

---

## Scenario Coverage ≠ Branch Coverage in Decision Tables

**Category**: Process/Model

When a multi-outcome decision table (e.g., a truth table with Allow/Deny branches) is tested via BDD scenarios, all scenarios can be mapped 1:1 and all tests can pass while a primary branch remains unexercised. This happens when scenarios were authored to cover corner cases (conflict, filter-out, error) rather than the happy path.

Pattern to flag: "seven scenarios all have tests; the primary Allow branch of a four-row truth table has zero tests." The correctness audit may surface this as a logic finding (branch unreachable by tests), but the coverage auditor must independently verify that every branch *outcome* — not just every scenario — has at least one test.

Concrete check: build the full truth table for the decision block, enumerate every reachable row, and trace which test (if any) produces that row's output. A scenario that reaches the code but exits via a neighboring row does not count as coverage for the missed row.

---

## Step-Ordering Invariants Require Adversarial Inputs to Test

**Category**: Process/Model

When a multi-step precedence engine defines "Step N always executes before Step M" as a security guarantee, tests for Step N alone do not verify the ordering invariant. The invariant requires an adversarial test where:
- Step M *would* produce a different result if it executed first
- The correct output is driven by Step N

Pattern to flag: existing tests for Step N use inputs that trivially fall through Step M (e.g., empty list for Step M's data source), so the ordering is never challenged. A test must supply a live conflict between the two steps to prove the ordering holds.

Severity of this gap: High when the invariant is a documented security or lockout-prevention guarantee, not merely an implementation detail.

---

## STABLE CONTRACT Constants Require Structural Tests for Non-Emptiness and Uniqueness

**Category**: Process/Model

When a class of string constants is designated as a stable external contract — for example, because the values are written into API responses, audit logs, or client-parseable trace fields — the coverage auditor should check for two structural tests that are almost always missing:

1. **Non-emptiness test**: every constant value must be a non-null, non-whitespace string.
2. **Uniqueness test**: no two constants may share the same value, since duplicate labels in an audit log produce ambiguous records.

These tests are easy to write (enumerate all constants into an array, assert both properties) and have high diagnostic value. They are nearly universally omitted because developers assume string constants are self-evidently correct at write time.

Pattern to flag: a static class of string constants carries XML doc comments describing stable-contract obligations (e.g., "renaming requires a versioned migration plan"), and no test in the suite exercises the class at all. The gap is especially risky when the constants flow into log aggregators or API consumers that pattern-match on string values — a duplicate or empty label silently breaks downstream parsing with no compile error and no test failure.

Concrete check: search for any STABLE CONTRACT comment in the codebase, identify the owning class, and verify both structural tests exist.

---

## Optional Parameters With Defaults Are a Systematic Blind Spot

**Category**: Process/Model

When a method signature includes optional parameters with defaults (e.g., `IReadOnlyList<T>? items = null`), integration tests almost always call the method without supplying the optional argument. The non-default path — passing a non-null list — is rarely exercised. This is systematic: the convenience of a default encourages callers (including test authors) to omit the argument entirely.

Pattern to flag: a method has been called dozens of times across the test suite, all with the default. The non-default path may have untested persistence behavior (e.g., the value is written to the DB incorrectly or the returned object carries the wrong value).

Concrete check: scan the method's call sites in tests using `vscode_listCodeUsages`. If every call omits the optional parameter, flag the non-default path as a gap.

---

## Guard Clauses Introduced Without Tests Are a Systematic Blind Spot

**Category**: Process/Model

When a method receives new `ArgumentException` / bounds-checking guard clauses (`if count > N throw`, `if length > N throw`), test authors frequently omit tests for the guards entirely. The reasoning is usually implicit: "the guards are defensive infrastructure, not feature behavior." But from a coverage perspective, they are untested branches just like any other.

Pattern to flag: a method has N new `throw new ArgumentException(...)` statements added in this slice, and zero tests supply inputs that trigger those throws. The guards protect a non-functional invariant (e.g., JSONB payload size) but there is no regression protection if they are accidentally deleted or weakened.

Concrete check: for every new `throw new ArgumentException` in the changed files, search the test suite for a test that passes the boundary-violating input (e.g., `Count == limit + 1`, `Length == limit + 1`). Flag any guard that has no such test.

Additional check: when the same guard exists in one method (e.g., `CreateAsync`) but was identified as missing from a parallel method (e.g., `ApplyEditAsync`), the coverage auditor should flag both: the missing guard AND the absence of tests — they are two separate findings that often appear together.

---

## Shared Static Test Identifiers Are Safe Under Sequential Execution, Fragile Under Parallelism

**Category**: Process/Model

Integration test fixtures that declare identifiers (GUIDs, strings, integers) as `static readonly` class fields are safe when a TearDown phase truncates or rolls back the database between tests, and NUnit runs the fixture sequentially by default. However, the static nature means that if `[Parallelizable]` is ever applied, two tests writing to the same identifier will produce non-deterministic results in count-based assertions.

Pattern to flag: `static readonly Guid` fields for resource IDs in an integration test fixture that asserts exact counts (e.g., `HaveCount(1)`). Recommend promoting to per-test `[SetUp]`-initialized instance fields regardless of current execution model, to make the intent explicit.

Severity: Medium — not currently broken, but a maintenance trap that is easy to add to and hard to notice.

---

## Injected Test-Controllable Utilities That Are Never Asserted Are Dead Weight

**Category**: Process/Model

When a service under test accepts a controllable test utility (e.g., a `TimeProvider` or fake clock), the injection only adds value if at least one test asserts the controlled value (e.g., a timestamp written to the database equals the injected time). If no test ever asserts the controlled output, the injection is invisible infrastructure — it adds complexity and DI wiring with no test-coverage benefit.

Pattern to flag: `TimeProvider`, fake clocks, or deterministic random sources are injected into a service, but no test anywhere asserts the fields those utilities influence (e.g., `CreatedAt`, `UpdatedAt`).

Recommendation: add one test per service that injects a fixed time and asserts the timestamp field. If the timestamp is considered unimportant, remove the injection and use `DateTime.UtcNow` directly.

---

## New Tables Missing from Integration Teardown → Tests Pass by Accident

**Category**: Process/Model

When a data migration adds new tables and the shared integration test teardown (TRUNCATE list or equivalent) is not updated, tests that write to those tables can pass by coincidence rather than by genuine isolation. The pattern:

- Test A creates a row with identifier X and password/value Y (teardown doesn't clean it)
- Test B tries to create the same identifier X with the same value Y, gets a "duplicate" result, but the pre-existing row from Test A serves as sufficient fixture state for Test B's assertion to pass
- All tests appear green, but isolation is broken — any new test with identifier X and a different Y will fail non-deterministically

Detection check: for every table with a unique constraint introduced in this change set, verify it appears in the test teardown cleanup list. If a test's `[SetUp]` or seed logic can write to a table that isn't in teardown, the tests have latent state contamination.

Severity: High — tests pass today by coincidence; fails when new tests use the same identifier with different data, or when test execution order changes.

---

## Inner-Loop Test Strategy Targets Are the First Audit Check

**Category**: Process/Model

When a feature has a formal `test-strategy.md` or equivalent specification that enumerates inner-loop test targets (unit/integration), those targets are the **highest-priority coverage check** in the audit. They represent a signed-off agreement on what must be tested at the unit/integration level, distinct from what the E2E scenarios cover. The most common failure mode is: all E2E scenarios pass, but 2 of 4 inner-loop targets were simply never written.

Pattern: read the test strategy file first, enumerate its inner-loop targets, and verify each one has a corresponding test before doing any broader analysis. Missing inner-loop targets that appear in the strategy are automatic Medium+ findings regardless of E2E coverage.

---

## Per-Class Test Contract: Missing New Methods = High When Peers Are Covered

**Category**: Process/Model

When a class has an established pattern of "every method has at least one dedicated test" (visible in the test file — angle variant, plate variant, unsupported-type exception for each method), adding new methods without tests is a **High** gap, not Low. The class-level contract makes the absence more conspicuous and the fix more obvious (the pattern to follow is right there in the same file).

Signal: test file has `Angle`, `Plate`, and `Unsupported` test cases for every peer method except the new ones. Severity escalates from Low to High in this pattern.

---

## Tests Naming Private Methods Are a Naming Contract Violation

**Category**: Process/Model

**Pattern**: Test method names that reference a `private` method of the production class (e.g., `InternalHelper_WhenX_DoesY`) couple the test to implementation structure. The test still exercises the public API, but the name implies that the private method is the contract, discouraging legitimate refactoring.

**Action**: Flag as Medium when a test name contains a word or phrase that is also a private method or private field name in the class under test. Recommend renaming to describe the observable behavior.

---

## Defensive Guard Paths in Pure Functions: Pin with a Test

**Category**: Process/Model

**Pattern**: Pure transformation functions often contain defensive `continue` / early-return guards for data integrity (e.g., skipping an item whose referenced key is absent from a lookup map). These guards represent behavioral contracts. If the guard is silently removed, callers may receive incorrect results with no exception raised.

**Action**: Scan pure function bodies for any guard that has a `continue`, `return`, or `break` that silently discards input. If no test exercises that path, flag as Low — "missing sad-path test for defensive guard."

---

## Test Name Mismatch: Inverted Assertion Is Worse Than Missing Test

**Category**: Process/Model

**Pattern**: A test method that asserts the **negative** of what its name states (e.g., a name says "X causes Y" but the body asserts "X does not cause Y") is more harmful than a missing test. It creates false coverage signal: reviewers, agents, and grep-based audits believe the behavior named in the method is covered, when in fact the opposite behavior is tested.

**This extends the Async suffix lesson**: the inversion problem is not limited to `Async` suffixes. Any case where the method name describes a positive outcome but the assertion uses `.NotBe()` or `.Should().NotX()` warrants a rename check.

**Action**: For any test that contains a `.NotBe`, `.NotContain`, `.NotThrow`, or similar negation assertion, verify that the method name reflects the negation. If the name implies a positive assertion (e.g., "SomethingDeniesWithTrace") but the body asserts the negative ("must NOT produce this trace"), flag as Medium and recommend a rename.

---

## 2026-05-23 — Unawaited `ThrowAsync` in Void Tests Makes Security Assertions Vacuous

**Category**: Process/Model

**Pattern**: In C# NUnit test projects using FluentAssertions, `act.Should().ThrowAsync<T>()` returns a `Task` that must be awaited to execute the assertion. When called in a `void` test method without `await`, the returned task is fire-and-forget — the test runner marks the test as passed immediately without evaluating whether the expected exception was thrown. This silently invalidates any security regression test that verifies exception-based guards.

**Security significance**: The most dangerous form of this pattern is a path-traversal protection test — if the test `void WriteAsync_Traversal_Throws()` calls `act.Should().ThrowAsync<Exception>()` without `await`, removing the traversal guard entirely will not cause CI to fail. A security property is being tested, but the test cannot catch regressions.

**Heuristic**: When auditing test files that verify security-critical exception behavior (path traversal, auth checks, bounds checks), always look for:
1. Is the test method `void` rather than `async Task`?
2. Does the assertion call end with `ThrowAsync<T>()` without a leading `await`?

If both are true, classify as **High** — the security test is a no-op and provides false confidence. The production code may be correct at the time of review, but the safety net does not function.

**Note**: The same pattern applies to `NotThrowAsync` — though the security implication is lower (a passing false-positive rather than a missed regression). Always check for `await` on both.

**Recommendation**: Convert `void` methods using `ThrowAsync` / `NotThrowAsync` to `async Task` and prefix the assertion with `await`. No other change needed.

---
