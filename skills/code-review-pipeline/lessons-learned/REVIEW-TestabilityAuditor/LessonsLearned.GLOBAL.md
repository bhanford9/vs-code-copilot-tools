# Lessons Learned: REVIEW-TestabilityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future testability reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-04-22 — Toggle-always-disabled makes ON branches dead code

**Pattern**: When a test fixture uses `ToggleBuilder.AllDisabled().Build()` as the sole `IToggles` instance, any `if (_toggles.IsEnabled(...))` branch in the test assertions is unreachable dead code — tests appear green while the toggle-ON path is completely uncovered.

**Testability signal**: Look for `if/else` blocks inside test methods that condition on a toggle state where the toggle instance is always `AllDisabled()`. The enabled branch will never execute.

**Recommendation**: Flag as medium-priority. The fix is to introduce a second `IToggles` instance built with `.Enable(FeatureToggle.X)`, or use `[TestCase(true), TestCase(false)]` parameterization.

---

## 2026-04-23 — Fallthrough tests that assert `Is.False` cannot distinguish fell-through from prematurely-returned

**Pattern**: When a test's stated intent is "verify that code falls through block X to reach block Y," but the test arranges block Y to return `false` and asserts `Is.False`, the assertion is satisfied by two structurally different outcomes: (a) correctly fell through and Y returned false; or (b) X returned false prematurely before reaching Y. The test's structural validity depends on the code having no false-returning path inside block X — a future refactor could silently break the contract without failing the test.

**Testability signal**: Look for fallthrough-intent tests that only assert `Is.False` with a non-discriminating downstream scenario. The fix is always to add a companion case where block Y returns `true` (i.e., arrange Y's preconditions for a true result) and assert `Is.True` — this result is unreachable unless block X fell through.

**Recommendation**: Flag as medium-priority. The code may be logically sound today, but the test does not serve as a long-term regression guard for the fallthrough contract.

---

## 2026-04-28 — Passthrough constructor parameters in DI-heavy logic-provider trees are Low, not Medium

**Pattern**: In codebases that use layered "logic provider" objects (classes that hold injected services and propagate them to nested providers), a new injectable service added at a leaf class will thread its way up through several provider constructors that never directly use the parameter. This is a structural smell but not a testability blocker.

**False positive risk**: Flagging this as Medium or High overstates the testability impact. The parameter is still interface-typed and mockable; the only cost is extra mock setup in tests of the intermediate providers. Since those providers are typically exercised via integration tests (not unit tests), the practical friction is minimal.

**Recommendation**: Flag as Low. Note the pattern as a future architecture discussion point if constructor parameter lists grow further, but do not require a fix before merge.

---

## 2026-04-28 — Private static helper methods are a testability signal of GOOD design, not a gap

**Pattern**: When a class extracts complex logic into `private static` helper methods (no captured state, all inputs as parameters), those methods are tested through the public API. This is correct — private methods are implementation details and should not be directly accessible. They have no hidden dependencies, so test setup for the public API exercises them fully.

**False positive risk**: Do NOT flag `private static` helpers as an "untestable" concern. The correct observation is: "tested through public API, which is the intended design." Only flag if the private method is so complex it warrants extraction into a separate testable class — cyclomatic > 10 or multiple external calls.

---

## 2026-05-06 — Round-trip tests that verify state but not dependent side effects leave a regression gap

**Pattern**: A "round-trip" test (save then restore, or serialize then deserialize) may correctly verify that intermediate state is set to the right value after the restore step, while using a loose mock for the service that consumes that state. If the consuming service call (e.g., a `FitChord` call that uses the restored position) is not verified, the test is green even if the side effect is silently removed.

**Testability signal**: Look for round-trip or lifecycle tests that use `new Mock<IService>().Object` (no name, no setup, no verify) when the step under test is supposed to call that service. The test verifies "the right value was reached" but not "the downstream action that depends on that value was taken."

**Recommendation**: Flag as medium-priority. The fix is straightforward: promote the anonymous mock to a named variable, add `.Setup(...).Verifiable(Times.Once)`, and call `.Verify()` after execution. The round-trip test should serve as a complete specification of the operation — not just state, but also the observable outputs of the operation.

**False positive avoidance**: Only flag this when the side effect is part of the behavioral contract of the operation being tested. Do not flag loose mocks used to satisfy constructor parameters when the test is explicitly focused on a different behavior.

---

## 2026-04-22 — Default interface members (DIMs) that `new` concrete types are NOT a testability blocker when mocked

**Pattern**: An interface may declare default members whose bodies `new` real concrete types (e.g., `IFlowDecision EstimateX => new EstimateX()`). When Moq mocks the interface and explicitly `.Setup()` these members, Moq intercepts the property getter and the `new` is never invoked in tests.

**Risk**: If a test forgets to `.Setup()` a DIM, Moq's default behavior is to return `null` (for strict) or invoke the real default (for loose mocks). Use `MockBehavior.Strict` on such mocks to force an immediate, clear failure instead of silent execution of real production code.

**Recommendation**: Flag the absence of `MockBehavior.Strict` as a low/medium issue when an interface has DIMs that construct real types.

---

## 2026-05-08 — Collaborator interface coverage matters more than service interface coverage

**Pattern**: When a service class correctly receives its primary dependency via constructor injection (e.g., a `DbContext`), it is tempting to mark DI as "passing." The higher-priority check is whether the service's *internal collaborators* also have interfaces. A service that uses `private readonly SomeEngine _engine = new()` is fully DI-clean at its boundary yet completely unable to have collaborator behavior substituted in tests. Check all field initializers on every service, not just the constructor parameters.

**Recommendation**: Flag as Critical when a field-initialized collaborator performs business logic (inference, scoring, calculation). It is not a blocker when the field-initialized type is a framework primitive (e.g., a serializer, a formatter).

---

## 2026-05-08 — `DateTime.UtcNow` in "pure" calculator classes is a Critical hidden dependency

**Pattern**: Pure, stateless calculator classes appear to score 10/10 on testability until `DateTime.UtcNow` is found inline inside a calculation method (typically for age or elapsed-time formulas). These classes have no injected dependencies, no side effects, and clear return values — yet any test that asserts on a time-variant output will be non-deterministic unless the clock is controlled.

**Recommendation**: Always scan `DateTime.UtcNow` / `DateTime.Now` usage as a dedicated testability check even in classes labeled "pure" or "stateless." In .NET 8+, `TimeProvider` injection with a default `TimeProvider.System` fallback is the zero-friction fix — no production call sites change. Flag as Critical when the time dependency feeds a scoring or classification path that tests need to assert on precisely.

---

## 2026-05-08 — Zero-test codebases have 2–3 concrete blockers, not wholesale untestable architecture

**Pattern**: A green-field codebase with zero test projects often has a structurally sound DI architecture and well-separated concerns. The testability gaps tend to cluster into 2–4 concrete fixes (missing interfaces, hidden time dependencies, one missing method on an interface). Resist framing the audit as "this codebase is untestable" — instead, produce an ordered remediation roadmap that shows exactly which fixes unlock which test categories. An estimate of "one day to unlock core tests" is far more actionable than a broad warning.
