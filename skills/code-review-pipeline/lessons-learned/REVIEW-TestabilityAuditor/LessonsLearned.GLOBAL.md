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

## 2026-04-22 — Default interface members (DIMs) that `new` concrete types are NOT a testability blocker when mocked

**Pattern**: An interface may declare default members whose bodies `new` real concrete types (e.g., `IFlowDecision EstimateX => new EstimateX()`). When Moq mocks the interface and explicitly `.Setup()` these members, Moq intercepts the property getter and the `new` is never invoked in tests.

**Risk**: If a test forgets to `.Setup()` a DIM, Moq's default behavior is to return `null` (for strict) or invoke the real default (for loose mocks). Use `MockBehavior.Strict` on such mocks to force an immediate, clear failure instead of silent execution of real production code.

**Recommendation**: Flag the absence of `MockBehavior.Strict` as a low/medium issue when an interface has DIMs that construct real types.
