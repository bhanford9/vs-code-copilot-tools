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

## 2026-05-14 — Factory extraction from call-chain threading is a net testability win, even with many parameters

**Pattern**: When a private method (or scattered call-chain threading) is extracted into a factory class with N dependencies, the consuming classes now only need to mock one factory interface — not N individual services. This is a net testability improvement even if the factory itself has a large constructor.

**Assessment heuristic**: Evaluate testability _at the consumer level_, not just at the factory level. A factory with 21 constructor parameters is not a testability concern for its consumers — they receive one mockable interface. The factory's own tests benefit from the single-responsibility boundary.

**False positive avoidance**: Do NOT flag "21 constructor parameters" as a High or Medium issue when those parameters have been relocated from multiple upstream consumers to a single, dedicated class. The complexity has not increased — it has been surfaced and co-located.

**Recommendation**: Flag the factory constructor size as Low if tests for the factory are missing. Flag as Medium only if there is no way to inject a test double at the consumer level (which the `internal` interface prevents being the case when `InternalsVisibleTo` is used).

---

## 2026-05-14 — Positional `new` argument forwarding in factory `Build()` methods creates a specific coverage gap

**Pattern**: When a factory's `Build()` method constructs a leaf object with `new ConcreteType(arg1, arg2, ..., boolFlag, ..., argN)`, the correct forwarding of each positional argument (especially a `bool` flag at an interior position) cannot be verified from unit tests that only assert on the return type or behavior of the outer flow. The positional forwarding is an implementation detail of the factory's construction logic.

**Coverage gap**: A test asserting `result is StandardEndFlow` confirms the toggle branch fires, but does not confirm that `isRightSeat` is at position 11 vs. position 8, or that the correct service is at each position.

**Mitigation**: The gap is inherent to factory-composition patterns and is not unique to the extracted factory — the same gap existed in the private method before extraction. The mitigation is behavioral tests on the leaf object (e.g., `SeatSelectionLogicProvider` tests already cover this), not duplicated structural tests on the factory.

**Recommendation**: Flag as Medium when the leaf constructor has many positional parameters of the same type (e.g., multiple `bool` or multiple `IServiceX` of identical interface). Flag as Low when all positional types are distinct (making transposition a compile error). Do not flag when the leaf object already has dedicated unit tests verifying its constructor behavior.

---

## 2026-05-08 — Collaborator interface coverage matters more than service interface coverage

**Pattern**: When a service class correctly receives its primary dependency via constructor injection (e.g., a `DbContext`), it is tempting to mark DI as "passing." The higher-priority check is whether the service's *internal collaborators* also have interfaces. A service that uses `private readonly SomeEngine _engine = new()` is fully DI-clean at its boundary yet completely unable to have collaborator behavior substituted in tests. Check all field initializers on every service, not just the constructor parameters.

**Recommendation**: Flag as Critical when a field-initialized collaborator performs business logic (inference, scoring, calculation). It is not a blocker when the field-initialized type is a framework primitive (e.g., a serializer, a formatter).

---

## 2026-05-08 — `DateTime.UtcNow` in "pure" calculator classes is a Critical hidden dependency

**Pattern**: Pure, stateless calculator classes appear to score 10/10 on testability until `DateTime.UtcNow` is found inline inside a calculation method (typically for age or elapsed-time formulas). These classes have no injected dependencies, no side effects, and clear return values — yet any test that asserts on a time-variant output will be non-deterministic unless the clock is controlled.

**Recommendation**: Always scan `DateTime.UtcNow` / `DateTime.Now` usage as a dedicated testability check even in classes labeled "pure" or "stateless." In .NET 8+, `TimeProvider` injection with a default `TimeProvider.System` fallback is the zero-friction fix — no production call sites change. Flag as Critical when the time dependency feeds a scoring or classification path that tests need to assert on precisely.

---

## 2026-05-12 — Entity property initializers with DateTime.UtcNow are Low, not Medium/High

**Pattern**: Entity/model classes commonly use `public DateTime CreatedAt { get; set; } = DateTime.UtcNow;` as a default value. This is evaluated once at object construction and remains stable — it is NOT a recurring clock dependency. It is Low severity because test setup can always override the value: `new TaskItem { CreatedAt = specificDate }`. Do not conflate these initializers with `DateTime.UtcNow` calls inside method bodies (which re-evaluate on every invocation).

**False positive risk**: Flagging entity initializers at Medium or High overstates the testability impact. The only realistic friction is: forgetting to set `CreatedAt` in a test that cares about age-dependent behavior. The fix is a one-line override in test setup, not an architecture change.

**Recommendation**: Flag as Low. Note in findings that tests should explicitly set timestamp properties when age-dependent behavior is under test. Do not recommend removing the initializer defaults — they are the correct production default.

---

## 2026-05-12 — Dual-constructor "with/without optional services" is a Medium testability smell

**Pattern**: When a class has two constructors — one that omits optional services (making those fields null) for a simplified usage context (e.g., CLI) and one that accepts all dependencies for the full context (e.g., Web) — the class has hidden behavioral branching based on constructor choice. Tests that call the wrong constructor will silently exercise a code path that never runs in production.

**Testability signal**: Look for `private readonly ILogger? _logger;` (nullable optional field) combined with `_logger?.LogWarning(...)` guards throughout the class. This is the signature of the dual-constructor pattern.

**Recommendation**: Flag as Medium. The correct fix is: use `NullLogger<T>.Instance` and a null-object `IConfiguration` in the simplified context, keeping a single full-parameter constructor. This eliminates the conditional null behavior and makes both code paths testable through the same constructor.

---

## 2026-05-12 — Missing flow-branch test is Low, not High, when the branch predicate is directly unit-tested

**Pattern**: A `flow.Decide()` wiring has two branches (`ifYes`/`ifNo`). All flow tests hold the decision at one value in `[SetUp]`, leaving the alternate branch dark at the flow level. This might appear High (an entire execution path is unexercised) — but the severity depends on whether the *predicate* deciding which branch runs is directly tested elsewhere.

**Calibration rule**: If the `IFlowDecision` implementation class is separately unit-tested via its `Predicate()` method, and the flow graph itself is a declarative wiring (no logic), the missing alternate-branch flow test is **Low**, not High. The predicate logic is covered; only the routing contract is unverified.

**Recommendation**: Flag as Low. Suggest a single dedicated test that sets the mock to the alternate return value and asserts only the alternate step name(s) appear in `_log`. Do not upgrade to High/Medium just because a flow path is dark — check whether the predicate is covered independently first.

---

## 2026-05-08 — Zero-test codebases have 2–3 concrete blockers, not wholesale untestable architecture

**Pattern**: A green-field codebase with zero test projects often has a structurally sound DI architecture and well-separated concerns. The testability gaps tend to cluster into 2–4 concrete fixes (missing interfaces, hidden time dependencies, one missing method on an interface). Resist framing the audit as "this codebase is untestable" — instead, produce an ordered remediation roadmap that shows exactly which fixes unlock which test categories. An estimate of "one day to unlock core tests" is far more actionable than a broad warning.

---

## 2026-05-13 — File I/O in a DevTools class is Medium, not High/Critical

**Pattern**: A class whose entire purpose is to write output files (PNG, text, etc.) lives in a `DevTools` or `Tools` project and is never invoked in production. Its constructor calls `Directory.CreateDirectory` and its methods call `File.OpenWrite`. There is no `IFileSystem` abstraction.

**Calibration rule**: This is **Medium**, not High or Critical. The class IS the I/O — abstracting the filesystem away would remove the feature. Tests using `Path.GetTempPath()` and `[TearDown]` cleanup are the pragmatic path. Flag it as Medium to document the constraint, but do not recommend architecture changes for a dev tool.

**False positive risk**: Flagging this as High or Critical overstates the urgency and implies a blocking design flaw. The correct framing is: "tests require real disk; use temp directory pattern."

---

## 2026-05-13 — Optional `= null` constructor parameter is the cleanest seam for a dev-only feature

**Pattern**: A production service has a long constructor list of required dependencies. A new optional dev-only feature is introduced via `IOptionalFeature? feature = null` as the last parameter. Existing DI registrations and tests compile unchanged. Tests that want to exercise the new path explicitly pass a mock.

**Testability signal**: This is a positive signal — it is the correct design for an optional dev feature. The seam is clean, backward-compatible, and Moq-friendly. The only testability concern is: does any test *actually use the seam*? If no test passes a non-null value, the new path is untested even though the seam is excellent.

**Recommendation**: When you see `= null` optional injection on a new feature, check whether the `RunObserved`/`if (feature != null)` branch has test coverage. The seam being good does not mean the path is exercised.

