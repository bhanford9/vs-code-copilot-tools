# Lessons Learned: REVIEW-UnitTestCoverageAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed a non-obvious coverage gap pattern, a false-positive risk, or a calibration heuristic not derivable from reading the code. Skip if the review ran cleanly.

---

### "Met" ≠ "Tested": a requirement documented as passing does not mean the behavior is mechanically asserted
Before closing a requirement as covered, verify that a test specifically exercises the stated condition and asserts on the outcome. A test that implicitly covers a behavior through a side-effect chain is not the same as a test that targets the behavior directly. When a requirement names a security invariant (e.g., "log every access attempt"), search for a test that asserts on the log output, not just on the thrown exception.

---

### Filter-before-assert trap: `.Where(...).Should().NotBeEmpty()` does not verify the filter
When a test filters a result set and then asserts the filtered set is non-empty, the test passes even when the underlying behavior is wrong — as long as at least one item passes the filter. The test must assert the original collection contains a specific item, not that the filtered view is non-empty.

---

### Deleted guard requires a replacement test documenting the new inclusive behavior
When a guard (`.Where()`, condition check) is removed from a code path, the previously-excluded case is by definition untested — the old tests never exercised it. Before the merge, a test must document what the previously-excluded inputs now produce. The absence of such a test means the new inclusive behavior has no regression guard.

---

### Zero-test subsystems: start with infrastructure assessment before itemizing gaps
Before flagging 20 individual missing tests in a zero-test subsystem, assess whether a test project exists. If no test project exists, the primary finding is "no test infrastructure." All specific missing tests are secondary findings under that blocker. Prioritize: (1) test project creation, (2) access-modifier changes for pure logic methods, (3) highest-regression-risk paths.

---

### Security-critical private methods locked behind a class boundary: Critical testability gap
When a security-critical guard method is private on a class that makes it inaccessible for direct unit testing, and the correctness of that logic has not been verified by other means, rate the gap Critical. The structural home of the method is the barrier to testing — the method must be extracted to an internal static class with `InternalsVisibleTo` before tests can be written.

---

### Known-gap requirements need a test that formally documents the gap as a planned future behavior
When a requirement was explicitly flagged as a known gap in the work item or design doc, a test should exist that documents the expected behavior as `Ignore`d or pending. An absence of any test means the gap is invisible to future developers running the suite.

---

### Bounded assertions are red flags: `items.Should().HaveCountGreaterThan(0)` doesn't pin behavior
Non-specific assertions (count > 0, contains at least one, not-null) verify only that something happened, not what happened. When a new code path must produce a specific outcome, the test must assert the exact output. Flag loose assertions on newly-delivered behavior as Medium.

---

### Prior-audit bugs without regression tests: Critical, not Medium
When a bug was identified in a prior review cycle, documented, and fixed — but no regression test was added — the same bug can be silently reintroduced. Rate the missing regression test Critical when the bug was security-relevant or data-impacting.

---

### `Assert.DoesNotThrow` with a non-throwing mock is a hollow assertion
A test that asserts `Should().NotThrow()` when the mock is configured to return a valid value (never throws by construction) verifies nothing. The assertion will pass even if the method under test is never called. Replace with a specific outcome assertion or a `Times.Once` verification on the mock.

---

### `Times.AtLeastOnce` is almost always too permissive — prefer `Times.Once` or `Times.Exactly(N)`
When a method is expected to be called exactly once per trigger, `Times.AtLeastOnce` will pass even if the method is called 5 times in a loop due to a regression. Use `Times.Once` when the call count is part of the behavioral contract.

---

### Test names that reference toggle states must match the fixture's actual toggle configuration
When a test is named "...WithToggleEnabled" or "...WhenFeatureIsOff," verify that the fixture actually sets the toggle to the named state. A misnamed test that runs with the opposite toggle state passes for the wrong reason and fails to detect regressions.

---

### Cross-fixture gap check: methods tested in fixture A but missing from fixture B covering a related scenario
When two test fixtures cover related scenarios (e.g., one for insert, one for update), verify symmetrically that both fixtures cover the same critical methods. A method tested in the insert fixture but absent from the update fixture is a gap, not just a style issue.

---

### Dev-tool code warrants tests for all pure logic, even if side-effect-heavy code is integration-tested only
Pure computation methods in a dev tool (parsing, formatting, transformations) are fully testable without any infrastructure. The fact that other methods in the same class require file I/O does not justify skipping tests for the pure methods.

---

### Flow-level engines: branch coverage at the flow step level is distinct from decision-class coverage
When an engine executes a series of flow steps that each contain conditional logic, covering all decision paths within a step does not guarantee all step-selection paths are exercised. The step-selection logic (which steps run) and the within-step logic (what each step does) are independent coverage dimensions.

---

### Parametrization consistency: all equivalence classes must be represented across parametrized test cases
When a parametrized test covers N scenarios but a new equivalence class (e.g., empty input, null input, boundary value) is missing, rate the gap based on what the missing input would produce. Boundary and null cases are the most regression-prone.

---

### Test case name contradicts the `.Returns()` mock configuration: gap in test author intent
When a test is named "ShouldReturnXWhenConditionY" but the mock is configured to return a value that contradicts condition Y, the test is either testing the wrong condition or the mock is misconfigured. Both require investigation before calling the behavior covered.

---

### DI module changesets: assess coverage per module, not per class
When a changeset reorganizes DI registrations across multiple modules, the coverage question is "does at least one integration test exercise the composition root for each new module?" not "does a unit test exist for each extension method?" DI registration correctness is a composition-root concern.

---

### Identical-score top-N test: seeded identical inputs produce identical outputs by construction
When a test verifies that N top-ranked items are returned but all test inputs have identical scores, the test does not verify that the ranking algorithm's ordering logic is correct. The test verifies that N items are returned. Add a test case with differentiated scores to verify the ordering logic specifically.

---

### Command handler output-write coverage: verify write path is tested, not just read path
When a command handler writes output to a destination (file, stream, channel) and the test asserts only on the return value, the write path is untested. A regression that silently stops writing output will not be caught. Always include an assertion on the write destination in addition to the return value assertion.

---

### Fallthrough tests with degenerate outcomes: no-op input returns no-op output — doesn't test the happy path
When a test passes an input that triggers a no-op branch (empty list, zero-count collection, already-complete state), the test verifies the degenerate path only. The happy path — where a real transformation occurs — must have its own test case.

---

### Flow-runner style engines: testable with a builder pattern that assembles a controlled step sequence
When an engine composes and executes a sequence of steps at runtime, a test builder that constructs a controlled subset of steps (including substituted test doubles for infrastructure steps) makes the engine directly testable without standing up the full production dependency chain. Flag the absence of such a builder as High when the engine contains core business logic.
