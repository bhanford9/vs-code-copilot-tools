# Lessons Learned: REVIEW-TestabilityAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future testability reviews. Skip if the review ran smoothly.

---

### ILogger audit-logging requirements are invisible to exception-only tests
When a security requirement includes "log every access attempt at Warning severity," tests that only assert on thrown exceptions cannot detect if the log call is removed. Verify whether any test asserts on log output. If not, flag Medium — even when the logging behavior is visually correct in the code. The minimal fix is constructing the service with a captured logger backed by a `List<(LogLevel, string)>`.

---

### Wildcard message assertions do not pin non-disclosure requirements
When two code paths are required to produce identical exception messages (preventing information leakage via differential error messages), assertions of the form `.WithMessage("*{id}*")` verify that both contain the ID but NOT that they are identical. A future change can add text to one path and satisfy the wildcard while breaking the non-disclosure requirement. Rate Low when the paths share a format string literal (code is correct, test is imprecise); rate Medium when no structural protection prevents divergence.

---

### OAuth `OnCreatingTicket` lambdas are a recurring service locator trap
Anonymous lambdas in framework authentication callbacks cannot receive constructor-injected dependencies — they must use `httpContext.RequestServices.GetRequiredService<T>()`. When these callbacks contain business logic (claim extraction + service call + branching), the logic is untestable without the full middleware stack. Rate High when a lambda has 3+ distinct operations; rate Low/skip when it is a thin pass-through. The fix is extracting to an injectable service.

---

### `null!` constructor argument as a structural invariant enforcer
Passing `null!` for a dependency in a unit test is a deliberate structural invariant: "this code path must never touch this dependency." A `NullReferenceException` means a code change violated the invariant, not that the test is broken. Rate Low when the intent is documented and the method under test is a guard path; rate Medium when no comment is present and the test is load-bearing for a security invariant. Add a comment: "NULL INVARIANT: deny path must never reach this dependency."

---

### `TimeProvider` partial adoption: look for `DateTime.UtcNow` direct calls in services that don't inject `TimeProvider`
When a codebase partially adopts `TimeProvider` injection, the services added before the pattern was established are the ones that missed it. In any layer that injects `TimeProvider`, check every service that handles time-sensitive operations. A mix of injected and direct calls in the same layer is almost always an oversight. Rate High — the fix is a one-constructor-parameter change.

---

### Static fields initialized from environment at class load time have no injection seam
A `private static readonly string Path = Environment.GetFolderPath(...)` evaluated at class initialization cannot be influenced by any runtime mechanism. Even if the class implements an injectable interface, the concrete value cannot be overridden in tests. Rate High — the minimal fix is a constructor parameter with a default that reads the static field, making the class directly testable by passing an override.

---

### Static pure-function helpers are not a testability issue — severity lives at the call site
A `static` method that takes value inputs, produces outputs, and performs no IO, clock access, or shared-state mutation is fully unit-testable by direct invocation. Do not flag it as "untestable" because it is static. Severity calibration: no external dependencies → Low or no finding; accesses IO/clock/environment → High (same as any hard-coded external dependency); called from service where swap behavior is needed → Low/Medium seam-flexibility concern only.

---

### Entity initializer defaults using the system clock create flaky timestamp assertions
An entity property initialized to `DateTime.UtcNow` in the property initializer creates a non-deterministic default. Tests that construct the entity directly will receive the real clock as the default — making timestamp assertions flaky. Rate Low when the service layer always overwrites the field; rate Medium when paths exist where the entity is saved without the service setting the timestamp. Prefer `= default` for audit timestamp fields on entity classes.

---

### Environment property bypassing an injectable settings object is a hidden dependency masquerading as correct design
When a class correctly accepts a settings object via injection but one method calls `Environment.UserName` (or similar) directly instead of reading from the settings object, the DI structure looks correct but the specific branch bypasses the injection chain. Rate High when the bypassed property is used in a security or correctness decision.

---

### MVVM ViewModel with injectable constructor: fully testable without UI framework infrastructure
In an MVVM codebase that separates business logic into an injectable ViewModel layer, the ViewModel is fully testable with standard unit tests. The component becomes a thin renderer. Do not flag `[Inject]` property injection in views as a testability issue — it is normal idiom. Flag inline business logic in views that lacks a testable ViewModel extraction — that is the real testability gap.

---

### Static pure-function call site: seam-flexibility concern is at the caller, not the helper
A `static` class with no external dependencies is testable by direct invocation. The testability concern is at the call site: when a non-static service hard-codes a call to the static method, it cannot be substituted for error-injection scenarios. Rate Low/Medium for the call site, not for the static helper.

---

### Optional messenger parameter defaulting to a process-wide singleton: cross-test contamination risk
In MVVM frameworks where `IMessenger? messenger = null` resolves to a global singleton, two test ViewModel instances constructed without injecting a fresh messenger share the same singleton and can trigger each other's handlers. Rate Medium. Add a comment: "unit tests must inject `new WeakReferenceMessenger()`." The fix is a constructor default that clearly signals the injection requirement.
