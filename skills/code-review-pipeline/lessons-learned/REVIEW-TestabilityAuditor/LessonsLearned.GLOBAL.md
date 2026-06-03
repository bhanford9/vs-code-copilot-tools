# Lessons Learned: REVIEW-TestabilityAuditor

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

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future testability reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-31 — ILogger Audit-Logging Requirements Are Invisible to Exception-Only Tests

**Pattern**: When a security requirement includes "log every access attempt at Warning severity," standard integration tests that assert only on thrown exceptions cannot detect if the log call is silently removed. The injectable `ILogger<T>` design technically supports capture-sink testing, but tests written as `act.Should().ThrowAsync<KeyNotFoundException>()` exercise only the exception path — not the log statement that precedes it.

**Why this matters**: The log call and the throw often appear in the same `if` block. A reviewer scanning the code sees both. But the test sees only the exception. Deleting the `LogWarning(...)` line leaves all tests green while silently removing the audit trail.

**Testability signal**: When a feature requirement names an audit log, warning, or security event as a distinct deliverable (not a side effect), check whether any test asserts on the log output. If not, flag Medium — even if the logging behavior is visibly correct in the code.

**Recommendation**: Directly construct the service with a captured logger (`ILogger<T>` implementation backed by a `List<(LogLevel, string)>`). This requires no new test infrastructure class if the service has a clean constructor: just `new TheService(existingDb, timeProvider, capturedLogger, otherDep)`. The audit trail requirement becomes a tested contract rather than a reviewed assertion.

---

## 2026-05-31 — Wildcard Message Assertions Do Not Pin Non-Disclosure Requirements

**Pattern**: When two code paths are required to produce **identical** exception messages (a common non-disclosure / non-leaking design), assertions of the form `.WithMessage("*{id}*")` verify that both messages contain the ID — but do NOT verify they are textually identical. A future change that adds " — access denied." to one path satisfies the wildcard while breaking the non-disclosure requirement.

**Severity guidance**:
- **Low**: The two paths use the same format-string literal in the source — the code is correct; the test is just imprecise. Flag Low and recommend adding one exact-string assertion.
- **Medium**: There is no shared constant or obvious structural protection against the messages diverging — the only safeguard is test precision.

**Action**: For requirements stated as "path A and path B must produce the same exception message," at least one test must assert the exact string — not a wildcard containing a variable portion. A good pattern: assert the exact message on the mismatch path, and separately assert the exact message on the not-found path, then compare as strings if a DRY assertion helper is available.

---

## 2026-05-29 — ASP.NET Core OAuth `OnCreatingTicket` Lambdas Are a Recurring Service Locator Trap

**Pattern**: In ASP.NET Core OAuth provider registrations, `options.Events.OnCreatingTicket = async ctx => { ... }` callbacks are anonymous lambdas that cannot receive constructor-injected dependencies. The only way to access scoped services (e.g., a user management service) is `ctx.HttpContext.RequestServices.GetRequiredService<T>()` — the service locator pattern. When this callback contains more than one or two lines of business logic (claim extraction, service call, result branching), the entire logic block is untestable without standing up the full OAuth middleware stack.

**Severity guidance**:
- **High**: The lambda contains multiple operations (claim extraction + service call + conditional failure handling + three provider copies). Extracting to an `IOAuthCallbackService` is the right mitigation.
- **Low/skip**: The lambda is a thin pass-through (one service call, one conditional). The E2E tests cover it adequately.

**Testability signal**: Count the distinct operations in each `OnCreatingTicket` lambda. If it's > 2 and duplicated across providers, flag High and recommend extraction to an injectable service.

---

## 2026-05-31 — `null!` Constructor Argument as a Structural Invariant Enforcer

**Pattern**: Passing `null!` for a dependency in a unit test is a deliberate structural invariant — it encodes: "this code path must never touch this dependency." A `NullReferenceException` means a code change violated the invariant, not that the test is broken. Rate **Low** when the intent is documented and the method under test is a guard path; rate **Medium** if the comment is absent and the test is load-bearing for a security invariant.

**Recommended documentation comment** (drop into the SetUp or construction site):
> `// NULL DB INVARIANT: passing null! enforces that the deny/guard path never touches the DbContext.`
> `// If this test fails with NullReferenceException, the guard no longer fires before a DB access — fix the guard, not the test.`

---

## 2026-06-02 — Blazor `NavigationManager` Redirect Components Are bUnit-Testable But Routinely Covered Only by E2E

**Pattern**: A Blazor component that injects only `NavigationManager` and calls `NavigateTo(...)` from `OnInitialized()` is trivially testable with bUnit — the framework's `FakeNavigationManager` is registered automatically, and `ctx.NavigationManager.History` exposes every `NavigateTo` call including options like `ReplaceHistoryEntry`. Despite this, these components are frequently covered only by E2E tests, leaving the redirect URI format, encoding correctness, and navigation options (e.g. `replace: true`) as reviewed assertions rather than tested contracts.

**Why this matters**: E2E tests for redirect behavior require a running browser, add seconds per test, and cannot directly assert `NavigationOptions.ReplaceHistoryEntry`. Negative-assertion tests ("no redirect should occur") in E2E are especially problematic — they use `Task.Delay` as a timing proxy, adding arbitrary wait time and creating flakiness under CI load. The same assertions take milliseconds in bUnit and require no timing.

**Testability signal**: When a Blazor component's only injectable is `NavigationManager`, flag any absence of bUnit component tests as **Medium** — the component is testable today, the infrastructure is available, and the gap means redirect contracts are not mechanically enforced. The severity drops to **Low** if the component's guard predicate is a pure static method that IS unit-tested (the redirect encoding and options are still missing but the path classification is covered).

**Recommended bUnit pattern** (drop into any `TestContext`-based test):
```csharp
ctx.NavigationManager.NavigateTo("http://localhost/protected-path");
ctx.RenderComponent<TheRedirectComponent>();
ctx.NavigationManager.History.Should().ContainSingle()
    .Which.NavigationOptions.ReplaceHistoryEntry.Should().BeTrue();
```
The `FakeNavigationManager` is registered for free — no mock setup needed.

**Negative assertion pattern** (replaces `Task.Delay`):
```csharp
ctx.NavigationManager.NavigateTo("http://localhost/auth");
ctx.RenderComponent<TheRedirectComponent>();
ctx.NavigationManager.History.Should().BeEmpty(
    because: "navigating to an auth path must not trigger a redirect");
```

**Pattern**: A `static class` housing a pure transformation function may be highly testable in isolation (call the method directly in unit tests). The real testability concern is whether any **caller** hard-codes a static method call to it. If so, the caller cannot be tested independently of the concrete implementation, and any future dependency the pure function acquires forces a non-trivial refactor.

**DO**: Rate the static class itself as testable if it has no external dependencies and is a pure function. Rate the caller as having a missing seam.
**DON'T**: Mark the static class as "untestable" merely because it is static — the severity lives at the call site.

**Trigger**: When you see a static class call inside a non-static method that has other responsibilities (e.g., database access + projection), flag the call site as Medium — "no seam between X and its caller."

---

## 2026-05-19 — EF Core Bulk Operations (`ExecuteUpdateAsync` / `ExecuteDeleteAsync`) Are In-Memory Provider Killers

**Pattern**: In EF Core projects, `ExecuteUpdateAsync` and `ExecuteDeleteAsync` (EF Core 7+ bulk-update APIs) translate directly to SQL `UPDATE`/`DELETE` statements. The EF Core in-memory database provider does **not** support these methods and throws `InvalidOperationException` at runtime. Any service that uses them cannot be unit-tested with the standard in-memory provider.

**Testability signal**: When auditing EF Core codebases, search for `ExecuteUpdateAsync` and `ExecuteDeleteAsync` calls — they are Critical testability blockers if unit testing is a goal. The affected methods require either a SQLite provider or a real database engine to test at any layer.

**Recommendation**: Flag as Critical. The mitigation options are: (1) accept integration-test-only for those methods and document it explicitly; (2) extract the bulk operation into an injectable repository method that can be mocked; (3) switch to EF Core tracked-entity updates for the testable path (at some performance cost).

---

## 2026-05-23 — Optional Messenger Parameter Defaulting to Global Singleton Is a Recurring Unit-Test Trap

**Pattern**: In CommunityToolkit.Mvvm and similar MVVM frameworks, ViewModel constructors often accept `IMessenger? messenger = null` and resolve `null` to the framework's global singleton (e.g., `WeakReferenceMessenger.Default`). This is safe in production but creates latent cross-test interference in unit test suites: if two ViewModel instances are constructed without injecting a fresh messenger, they both register with the same singleton. Messages sent by one ViewModel can unexpectedly trigger handlers in another.

**Testability signal**: When auditing MVVM codebases, check the messenger constructor parameter — specifically whether the default resolves to a *process-wide singleton* rather than a *new instance*. Flag as Medium if so, because test authors can easily forget to inject a fresh messenger.

**Recommendation**: Add a code comment on the messenger parameter noting that unit tests must inject `new WeakReferenceMessenger()`. If stricter enforcement is needed, provide an internal factory method that always passes a fresh messenger.

---

## 2026-05-19 — Partial `TimeProvider` Adoption Is a Reliable Source of Clock-Non-Determinism Bugs

**Pattern**: When a codebase partially adopts `TimeProvider` injection (some services inject it, others still call `DateTime.UtcNow` directly), the services that were added *before* the pattern was established are the ones that missed it. These missed cases cluster around simpler or older services, not the complex ones.

**Testability signal**: In any C# codebase that uses `TimeProvider`, check every service that handles time-sensitive operations (expiry, timestamps, audit records). If the class constructor does not have a `TimeProvider` parameter, search the method bodies for `DateTime.UtcNow` / `DateTime.Now`. A mix of injected and direct calls in the same layer is almost always an oversight.

**Recommendation**: Flag each `DateTime.UtcNow` in a service without `TimeProvider` injection as High priority. The fix is a one-constructor-parameter change plus a `_time.GetUtcNow().UtcDateTime` substitution. The fix is low-cost and high-value.

---

## 2026-05-16 — Static fields initialized from environment at class load time are harder than instance calls

**Pattern**: When a class computes an environment-dependent value (file path, environment variable, machine name) as a `private static readonly` field at class initialization time, there is absolutely no injection seam — not even a protected virtual method or constructor parameter. Even if the class implements an interface that callers mock, the *concrete implementation* cannot be tested in isolation.

**Key distinction**: A method that calls `Environment.GetFolderPath(...)` inline can be overridden in a subclass or wrapped behind a virtual method with low effort. A `private static readonly` field evaluated once at class startup cannot be influenced by any runtime mechanism available to a test.

**Testability signal**: Search for `private static readonly string SomePath = Path.Combine(Environment.GetFolderPath(...), ...)` or similar patterns. These are High priority because the implementation is untestable even when the interface is mocked.

**Recommendation**: The minimal fix is a constructor parameter with a default (`string? settingsPath = null`). The static readonly field can remain as the default source, but tests can pass an override. This is a three-line change that unlocks full isolation.

---

## 2026-05-30 — Static Pure-Function Helpers Are Not a Testability Issue — Severity Calibration

**Pattern**: A `public static` class whose methods take only value/collection inputs, produce outputs, and perform no IO, no time access, and no mutation of shared state is fully unit-testable via direct invocation. It cannot be mocked, but it does not need to be. Flagging such a class as High or Critical because it is "not injectable" is a false positive.

**Correct severity assignment**:
- Static helper with no external dependencies → Low (or no finding if the method is trivially testable)
- Static helper that calls IO, clock, network, or global state → Critical/High (same as any hard-coded external dependency)
- Static helper called from a service where callers legitimately need to swap the behavior for error injection → Low/Medium (lack of injection seam limits test flexibility, but basic correctness is testable)

**Testability signal**: Before flagging a static method call, ask: "Does this method have any path that reaches outside the process boundary (IO, network, time, environment)?" If no, the testability concern is seam-flexibility only, not correctness. Calibrate accordingly.

---

## 2026-05-30 — Entity Initializer Defaults Using `DateTime.UtcNow` Are a Low-Visibility Clock Dependency

**Pattern**: In ORM-backed entity classes, property initializers of the form `public DateTime CreatedAt { get; set; } = DateTime.UtcNow;` create a non-deterministic default. If a service injects `TimeProvider` and overwrites these fields before saving, the initializer default is harmless in production. But tests that construct the entity directly (e.g., to set up projector or evaluator test data) will receive the real clock as the default value — making timestamp assertions flaky.

**Why this is subtle**: The `TimeProvider` injection looks correct at the service level. The entity looks fine in isolation. The problem only surfaces when a test builds an entity directly, asserts on a timestamp, and forgets to supply an explicit value.

**Testability signal**: In any codebase that uses injected `TimeProvider`, check whether entity classes have `= DateTime.UtcNow` or `= DateTime.Now` initializer defaults. Flag as Low if the service layer always overwrites them. Flag as Medium if there are paths where the entity is saved without the timestamp being set by the service.

**Recommendation**: Prefer `= default` (or `DateTime.MinValue`) as the initializer for audit timestamp fields on entity classes. This makes the non-default requirement visible at construction time and eliminates a class of flaky test assertion.

---

## 2026-05-16 — Environment property bypassing an injectable settings object is a hidden dependency masquerading as correct design

**Pattern**: A class correctly accepts a settings object via injection (e.g., `ISettingsService`). The settings object has a property (e.g., `WindowsUsername`) that callers set and rely on. But inside the class, one method calls `Environment.UserName` directly instead of reading from the settings object — effectively ignoring the injectable value.

**Why this is insidious**: The DI structure looks correct at a glance. The interface is mocked, the settings object is returned from the mock. But the specific branch that reads `Environment.UserName` bypasses the entire injection chain. Tests that mock `ISettingsService` to return a controlled username will see different behavior than they expect.

**Testability signal**: When a class has an injectable settings/config object with a user-identity field, check every method body for direct `Environment.UserName`, `Environment.MachineName`, `WindowsIdentity.GetCurrent()`, or similar calls. Flag any that shadow an already-injectable alternative.

**Recommendation**: Replace the direct environment call with the settings property. This is a one-line fix that (a) improves testability, (b) improves correctness (the injectable value is the source of truth), and (c) eliminates the inconsistency.

---

## 2026-05-20 — Blazor Components with an Injectable ViewModel Layer Are Much More Testable Than the Default Pattern

**Pattern**: In Blazor codebases that separate rendering from business logic via an injectable ViewModel (MVVM), the testability story splits cleanly. The ViewModel is fully testable with standard unit tests — no Blazor infrastructure needed. The component itself becomes a thin renderer and rarely requires bUnit coverage. The naive "Blazor is hard to test" heuristic overstates the difficulty in MVVM-structured codebases.

**Testability signal**: When auditing Blazor testability, the first question should be "is there an injectable ViewModel layer, and is all state-mutation logic in it?" If yes, most of the perceived complexity disappears. If no — if logic is inline in code-behind methods that access `IJSRuntime`, `NavigationManager`, or other Blazor services directly — then component testing becomes genuinely hard.

**Recommendation**: Do not flag `[Inject]` property injection in Blazor components as a High or Critical issue. It is normal Blazor idiom and bUnit handles it natively. Flag inline business logic in components that lacks a testable ViewModel extraction — that is the real problem.

---

## 2026-05-28 — Catch-Block Property Accesses Create Latent NPE Re-Throw in "Never Throws" Methods

**Pattern**: A method with a `try/catch(Exception)` wrapper promises it never throws — a common pattern in engine entry points (authorization evaluators, event dispatchers, validators). The catch block logs the error using properties from the method's input object (e.g., `context.Permission`, `context.PrincipalId`). If the input object itself is `null`, the `catch` block catches the initial `NullReferenceException` but immediately throws a *second* `NullReferenceException` when it accesses the null input's properties. The outer method then propagates the exception — violating its own contract.

**Testability signal**: When reviewing any method whose XML doc or interface contract says "never throws" or "always returns a result", check the catch block. If it accesses properties on the method's primary input parameter, ask: "Can this input be null?" If yes, the never-throws guarantee has a gap. The fix is a one-line null guard before the `try` block.

**Recommendation**: Flag as Medium. The fix is: `if (inputParam is null) return FailClosed("null input — fail closed");` placed before the `try`. This makes the null-input case testable (a test can now call with `null!` and assert the fail-closed result instead of observing an exception) and closes the contract gap.

---

## 2026-05-28 — `virtual` Property on an Input Object Is a Deliberate Testability Seam — Recognize and Preserve It

**Pattern**: In C# codebases with complex domain-logic engines, input data objects (POCOs, contexts, parameters) sometimes have one or more properties marked `virtual`. This is almost always intentional — it creates a testability seam that allows test subclasses to override the property getter to throw exceptions, simulate lazy-load failures, or inject controlled state. These `virtual` declarations are easily overlooked in code review and can be accidentally removed during "cleanup" refactors.

**Testability signal**: When reviewing input/context objects in a domain-logic or evaluation engine, note any `virtual` property declarations. If the codebase has test-double subclasses that override those properties, this is a deliberate design decision. If not all analogous properties are virtual, check whether future error-path tests could benefit from the same treatment.

**Recommendation**: Do not treat `virtual` on a DTO property as a design smell. Flag it as ℹ️ Info with a note that it is a testability seam. Recommend extending the same pattern (`virtual`) to sibling properties where the engine reads them later in the same evaluation flow, to allow future error-path tests to target those steps.

---

## 2026-05-28 — Private Static Security-Guard Methods in Blazor Partial Classes Are Silently Untestable

**Pattern**: In Blazor component code-behind (`partial class` files), pure-logic helper methods like URL validators or input sanitizers are commonly written as `private static`. Because the Blazor component host is required to instantiate the class, and bUnit is often absent from Web test projects, these methods end up with zero unit-test coverage — even when they contain security-critical logic (open-redirect guards, input validators).

**Why this matters beyond normal `private` concerns**: A `private static` method in a standard class can be tested indirectly through the class's public API. In a Blazor component, the "public API" is the rendered DOM — which requires a browser, a Blazor test host (bUnit), or a full Playwright E2E run. The method may be four lines with cyclomatic complexity of 2, and still be completely unreachable by fast unit tests.

**Testability signal**: When auditing Blazor components with `private static` methods that perform security-sensitive validation (URL safety, input sanitization, auth checks), flag the method as Critical if bUnit is absent from the test project *and* the method contains any security logic. The combination of "no bUnit" + "private security method" creates a gap where bugs survive code review and CI.

**Recommendation**: Extract the security-guard method to an `internal static` helper class (e.g., `UrlSafetyGuard`). Add `InternalsVisibleTo` on the web project. Write parametrized unit tests directly against the extracted class. The component calls the extracted method — same behavior, full coverage without bUnit.

---

## 2026-05-28 — Stringly-Typed Configuration Overrides in Test Setup Are Silent Rename Traps

**Pattern**: When test fixtures override strongly-typed options classes using raw `IConfiguration` string keys (e.g., `builder.Configuration["Auth:EmailEnabled"] = "false"`), the override is invisible to the compiler. If the bound options class is refactored — a property rename, a section rename, a nested-class restructure — the test setup silently stops working. The affected scenario passes for the wrong reason (default values are used instead of the intended override), producing a false-passing test.

**Testability signal**: In test setup delegates that configure `WebApplicationBuilder` or `IConfigurationBuilder`, search for `builder.Configuration["..."]` string-key assignments that correspond to a known strongly-typed options class. Each one is a potential silent-failure trap. Flag as Medium.

**Recommendation**: Replace string-key assignments with `PostConfigure<TOptions>` delegates. `PostConfigure` runs after the production `Configure` call, so it correctly overrides production values. It is fully type-safe: property renames are compile errors in the test setup, not silent misconfigurations.

---

## 2026-05-20 — SignalR Hub Subclasses Are Integration-Test-Only By Construction

**Pattern**: Any class that inherits from the SignalR `Hub` base class has `Context`, `Groups`, and `Clients` set by the framework at connection time. These cannot be injected, swapped, or mocked from outside the class. Any business logic in hub overrides (`OnConnectedAsync`, etc.) is only reachable via a real SignalR connection or the framework's test harness — there is no seam for unit testing.

**Testability signal**: When a hub method does more than call one or two injected service methods, flag it as High priority. The logic should be extracted to an injectable helper class that the hub calls. The hub itself stays as a thin orchestrator — the injectable helper is fully unit-testable.

**Recommendation**: Flag as High (not Critical) because the fix is straightforward: extract the logic, keep the hub thin. It is not a fundamental design flaw, just a placement error.

---

## 2026-05-20 — Browser Confirmation Dialogs via JS Interop Are a Recurring Blazor Test Friction Point

**Pattern**: Calling `IJSRuntime.InvokeAsync<bool>("confirm", message)` for confirmation prompts in Blazor components (common on delete/destructive-action buttons) creates a testing obstacle. Tests must mock `IJSRuntime`, match the string argument `"confirm"`, and return a controlled boolean. The string matching is fragile and non-obvious to first-time test writers.

---

## 2026-05-26 — Public Interface Expansion with Struct-Type Properties Creates Silent Moq Default-Value Trap

**Pattern**: When a public interface gains new properties whose type is a struct (e.g., a units-of-measure value type, `decimal`, `int`, `bool`), all existing `Mock<TInterface>` usages that do not configure the new property will return the struct's zero value (`default(T)`). Moq's loose mock behavior does not warn about this. If the zero value is numerically valid in the calculation context (e.g., a length of zero), the test passes silently but produces a wrong result.

**Why this is insidious**: The scenario where this is hardest to catch is when zero is a plausible answer — e.g., a centroid at zero, a zero-length offset, or a zero probability. There is no exception thrown, no test failure, and no Moq warning. The test appears correct but asserts against a wrong intermediate value.

**Testability signal**: When auditing a change set that adds struct-type properties to an existing public interface, count the mock sites for that interface across the test suite. If there are many (>10), flag as Medium: the new property will silently return zero in all unupdated tests. The risk scales with (a) how many mock sites exist and (b) whether zero is arithmetically meaningful in the affected code paths.

**Recommendation**: Flag as Medium severity. The mitigation options are: (1) add XML doc comments to the new interface property noting that mocks must supply explicit values and zero is numerically valid; (2) provide a test builder that defaults the new properties to a sentinel non-zero value; (3) use `MockBehavior.Strict` in the affected tests so any unexpected property call throws. Options 1 and 2 are lower friction for existing test suites.

---

## 2026-05-20 — Dual-Hosting Blazor Libraries (Web + Native) May Use Static Mutable Flags — Flag for Test Isolation Risk

**Pattern**: Blazor component libraries that target both a web hosting model (Blazor Server / WebAssembly) and a native hybrid model (e.g., MAUI BlazorWebView) sometimes use `public static` settable properties as a configuration mechanism. The native host calls a startup method that nulls out these properties to suppress web-specific behavior (e.g., render mode directives that throw in MAUI). This is a pragmatic cross-hosting solution.

**Testability signal**: When auditing a Blazor shared component library that supports multiple hosting models, search for `static` classes or fields initialized from `RenderMode.*` constants that also expose public setters or a `ConfigureXxx()` method. If the method modifies static state permanently and provides no reset, it is a test isolation risk — calling it in one test poisons all subsequent tests in the same process.

**Recommendation**: Flag as Medium. The minimal fix is adding a `Reset()` method that restores the original values — a three-line change. The flag is genuinely optional for production (MAUI always calls it before any component renders) but essential for parallel test execution. Do not flag as Low just because the workaround is simple; the blast radius across the entire test suite is non-trivial.

---

## 2026-05-20 — CommunityToolkit.Mvvm Source-Generated Commands Are Non-Mockable Without an Interface

**Pattern**: When a ViewModel uses `[RelayCommand]` from CommunityToolkit.Mvvm, the source generator emits the command as a non-virtual property. If the ViewModel class is injected as a concrete type (no interface), Moq cannot create a proxy for it — the command property cannot be swapped out. This is distinct from a virtual method override situation; it is a structural limitation of source-generated code.

**Testability signal**: In any Blazor or MVVM codebase using CommunityToolkit.Mvvm, scan for components that inject a concrete ViewModel class rather than an interface. If the class has `[RelayCommand]`-decorated methods, the component is not independently mockable — tests must use a real ViewModel instance with mocked service dependencies, which forces the full load path to execute.

**Recommendation**: Flag as High when an interface is absent. Extracting an interface is a low-effort, high-value change. The interface only needs to expose the properties and commands that the component uses — it does not need to replicate the full `ObservableObject` surface. Tests then mock the interface normally.

**Testability signal**: Search for `InvokeAsync<bool>("confirm"` in component code-behind files. Any occurrence is a test friction point.

**Recommendation**: Extract to a small `IConfirmationService` abstraction with a JS-backed production implementation. Tests inject a mock that returns `true` or `false` without string matching. This is a 10–15 line change that eliminates the friction entirely.

---

## 2026-05-18 — CLI Tools: Anonymous Lambda Handlers Are Untestable By Construction

**Pattern**: In CLI tools built on command-parsing frameworks (System.CommandLine, Spectre.Console, etc.), command handlers implemented as anonymous lambdas inside the entry point have no public surface and cannot be targeted by unit tests. The framework-level `SetAction(lambda)` registers a closure that captures local factory functions — there is no way to instantiate or invoke it from a test assembly.

**Testability signal**: If all command logic lives in anonymous lambdas in `Program.cs` (or equivalent), the entire command layer is untestable by construction, even if all underlying services are well-abstracted behind interfaces. This is a structural problem, not an injection problem.

**Recommendation**: Flag as Critical. The minimal fix is to extract each command's handler logic into a dedicated class with constructor-injected service dependencies. The entry point becomes a thin wiring layer.

---

## 2026-05-18 — "Partial Bypass" Pattern in Strategy Implementations

**Pattern**: A class correctly injects an abstraction for its primary execution path (e.g., `IExecutor`) but a secondary path — verification, health-check, or pre-flight — creates the same external dependency directly (e.g., `new Process()`), bypassing the injected abstraction. The class appears well-designed on inspection but the secondary path is untestable with any mock of the primary interface.

**Testability signal**: When reviewing strategy or adapter classes, check every method body — not just `Execute*`. Look for private static methods that launch processes, open network connections, or read the file system without going through the injected abstraction.

**Recommendation**: Route all side-effectful calls through the injected abstraction. If the secondary path needs different invocation semantics, either extend the interface or introduce a second injected dependency.

---

## 2026-05-18 — `Environment.Exit()` in CLI Helper Methods Is a Test-Killer

**Pattern**: CLI tools often place `Environment.Exit(1)` inside a shared error-formatting helper called from every command's error path. This makes every error path untestable — calling any command that hits an error will kill the entire test runner process, not propagate a testable exception.

**Testability signal**: Search for `Environment.Exit` in methods that are not the entry point itself. Any helper or utility method that calls `Environment.Exit` poisons all callers.

**Recommendation**: Flag as Critical. Replace with a typed exception pattern at the handler level; let only the CLI entry point catch and convert to `Environment.Exit`. This unlocks testing of all error paths.

---

## 2026-04-22 — Toggle-always-disabled makes ON branches dead code

**Pattern**: When a test fixture uses `ToggleBuilder.AllDisabled().Build()` as the sole `IToggles` instance, any `if (_toggles.IsEnabled(...))` branch in the test assertions is unreachable dead code — tests appear green while the toggle-ON path is completely uncovered.

**Testability signal**: Look for `if/else` blocks inside test methods that condition on a toggle state where the toggle instance is always `AllDisabled()`. The enabled branch will never execute.

**Recommendation**: Flag as medium-priority. The fix is to introduce a second `IToggles` instance built with `.Enable(FeatureToggle.X)`, or use `[TestCase(true), TestCase(false)]` parameterization.

---

## 2026-04-28 — Passthrough constructor parameters in DI-heavy logic-provider trees are Low, not Medium

**Pattern**: In codebases that use layered "logic provider" objects (classes that hold injected services and propagate them to nested providers), a new injectable service added at a leaf class will thread its way up through several provider constructors that never directly use the parameter. This is a structural smell but not a testability blocker.

**False positive risk**: Flagging this as Medium or High overstates the testability impact. The parameter is still interface-typed and mockable; the only cost is extra mock setup in tests of the intermediate providers. Since those providers are typically exercised via integration tests (not unit tests), the practical friction is minimal.

**Recommendation**: Flag as Low. Note the pattern as a future architecture discussion point if constructor parameter lists grow further, but do not require a fix before merge.

---

## 2026-05-18 — CommunityToolkit.Mvvm `ObservableRecipient` + `IsActive = true` in constructor is a hidden messenger-registration side effect

**Pattern**: When a ViewModel inherits from `ObservableRecipient` and sets `IsActive = true` in its constructor, the messenger registration fires immediately at instantiation. If the derived class does not forward an `IMessenger` to the base constructor (i.e., it omits the `base(messenger)` call), the class silently registers with `WeakReferenceMessenger.Default` — a static singleton. Tests that instantiate the ViewModel will pollute the shared messenger and can interfere with each other.

**Key distinction**: The `ObservableRecipient` base class fully supports injectable messaging via `ObservableRecipient(IMessenger)`. The gap is exclusively in derived classes that don't expose this parameter to their callers.

**Testability signal**: In any codebase using CommunityToolkit.Mvvm, search for classes that: (a) inherit `ObservableRecipient`, (b) set `IsActive = true` in the constructor, and (c) do NOT call `base(messenger)` with an injected instance. These classes are silently coupled to the static messenger.

**Recommendation**: Add an optional `IMessenger? messenger = null` constructor parameter and call `: base(messenger ?? WeakReferenceMessenger.Default)`. This is a one-line change to the constructor signature and one `base()` call that unlocks full test isolation without breaking existing production DI registrations.

---

## 2026-05-18 — `IRecipient<T>.Receive()` forces fire-and-forget async; tests should bypass the message path for async-outcome assertions

**Pattern**: `IRecipient<T>.Receive()` returns `void` by interface contract (CommunityToolkit.Mvvm). Any async work triggered inside `Receive()` must be fire-and-forget (`_ = DoWorkAsync()`). Tests that send a message and then immediately assert on state created by `DoWorkAsync` will race against the background task.

**Testability signal**: Look for `_ = MethodAsync(...)` or `Task.Run(...)` inside any `Receive()` implementation. The discarded task means assertion timing is non-deterministic from a test perspective.

**Recommendation**: Tests should call the underlying `async Task` method directly (if it is on the public interface) rather than triggering it via message. This avoids the timing concern entirely. For production code, consider adding exception logging via a continuation — silent task discard hides failures.

---

## 2026-04-28 — Private static helper methods are a testability signal of GOOD design, not a gap

**Pattern**: When a class extracts complex logic into `private static` helper methods (no captured state, all inputs as parameters), those methods are tested through the public API. This is correct — private methods are implementation details and should not be directly accessible. They have no hidden dependencies, so test setup for the public API exercises them fully.

**False positive risk**: Do NOT flag `private static` helpers as an "untestable" concern. The correct observation is: "tested through public API, which is the intended design." Only flag if the private method is so complex it warrants extraction into a separate testable class — cyclomatic > 10 or multiple external calls.

---

## 2026-05-23 — Mock Wrappers Discarded as Locals in `[SetUp]` Block Future Interaction-Based Verification

**Pattern**: In NUnit + Moq test fixtures, `[SetUp]` methods that create mock wrappers as local variables and pass only `.Object` to the system under test discard the wrappers when `SetUp` returns. The test class has no reference to the `Mock<T>` object and cannot call `Verify(...)` on it. Tests that only assert observable state (output collection contents, computed properties) work fine — but any future test requiring interaction verification (`DidCallX`, `WasCalledWithY`) needs to refactor `SetUp` before the test can be written, not just add a test method.

**Testability signal**: When reviewing a test fixture's `[SetUp]`, check whether any `Mock<T>` is declared as a `var` local rather than a private field. If the SUT's constructor receives `.Object` but the wrapper is not stored, flag as Medium. Look at sibling test fixtures in the same project for comparison — if they correctly store mock wrappers as fields, the inconsistency is clear evidence of a gap.

**Recommendation**: Promote all mock wrappers to private fields (`private Mock<IFoo> _foo = null!;`) and initialize them in `[SetUp]`. This is a mechanical 2–3 line change per mock. The SUT constructor call changes from `new Sut(foo.Object)` to `new Sut(_foo.Object)`. No logic changes.

---

## 2026-05-23 — C# `file`-Scoped Test Helpers Are Invisible Across Project Boundaries — Leads to Silent Duplication

**Pattern**: C# 11's `file` access modifier scopes a type to its declaring file. When a test helper (e.g., a `TimeProvider` subclass, a fake clock, a stub implementation) is declared as `file sealed class FakeX` inside a test method file, it is invisible to: (a) other test files in the same project, and (b) all files in all other test projects. The helper exists in the codebase, but a developer in a different project who needs the same capability cannot find it. They will either write a non-deterministic test or silently redeclare the helper locally — creating undiscoverable duplication.

**Testability signal**: When a test helper (clock, time provider, fake service) is `file`-scoped and the codebase has multiple test projects that exercise time-dependent code, flag as Medium. The signal is strongest when a shared test utilities project already exists (e.g., `Tests.Common`) — the helper belongs there.

**Recommendation**: Move the helper to the shared test utilities project as `internal` (or `public` if cross-assembly references are configured). Delete the `file`-scoped declaration. Add project references from consumer test projects to the utilities project. This is a 3-file change.

---

## 2026-05-06 — Round-trip tests that verify state but not dependent side effects leave a regression gap

**Pattern**: A "round-trip" test (save then restore, or serialize then deserialize) may correctly verify that intermediate state is set to the right value after the restore step, while using a loose mock for the service that consumes that state. If the consuming service call (e.g., a downstream fit or transform call that uses the restored state) is not verified, the test is green even if the side effect is silently removed.

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

**Coverage gap**: A test asserting `result is ExpectedFlowType` confirms the toggle branch fires, but does not confirm that a flag or dependency is at the correct positional argument slot in a multi-parameter constructor.

**Mitigation**: The gap is inherent to factory-composition patterns and is not unique to the extracted factory — the same gap existed in the private method before extraction. The mitigation is behavioral tests on the leaf object (which should already exist if the object has its own test file), not duplicated structural tests on the factory.

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


---

## 2026-05-19 — `private static` Helpers Are High Priority When Their Only Test Path Requires External I/O

**Pattern**: The 2026-04-28 entry correctly notes that `private static` helpers are NOT a testability gap — they are tested through the public API. However, this holds only when the public API itself is testable. When the *only accessible path* to the private helper requires traversing a method that calls an external I/O system (filesystem, network, database) with no injection seam, the helper is effectively untestable even though its implementation is pure.

**Key distinction**:
- `private static int Compute(int a, int b)` where the public API is directly testable: Low/not-a-gap (2026-04-28 rule applies)
- `private static bool IsMoreRecent(...)` inside a class where reaching it requires real filesystem I/O with no abstraction seam: **High** (this rule applies)

**Testability signal**: When auditing a private static helper, trace the call chain UP. Ask: "Can I reach this helper from a test without touching real I/O?" If the answer is no, flag High regardless of the helper's own complexity.

**Recommendation**: Minimum fix is access modifier change to `internal` + `[assembly: InternalsVisibleTo(...)]` (3-line change). Longer fix: extract to a public static class decoupled from the owning service.

---

## 2026-05-19 — Abstraction Interface Names Must Signal Scope Precisely, or Tests Will Miss the Real Gap

**Pattern**: When a project contains an interface named `IFileSystemService` but that interface only covers UI operations (tree browsing, shell-open), a developer auditing the data service will discover the interface, assume file I/O is abstracted, and move on — without noticing that the actual data-reading code calls `System.IO` directly. The misleading name causes a false-negative testability assessment.

**Testability signal**: When you see a file-system-sounding interface in a project, check its methods immediately. If they are UI/navigation operations, flag the naming mismatch and look for raw `System.IO` calls in data services as a separate High priority item.

**Recommendation**: Rename the UI-scoped interface to reflect its actual purpose (`IFileNavigationService`, `IShellFileService`). Add a separate interface for data-layer I/O when it is needed. The naming gap is Medium — but it masks a potentially High gap in the data layer.


---

## 2026-05-22 — Test Seed Helpers Are a Hidden Source of Clock Divergence When `FakeTimeProvider` Is Active

**Pattern**: Integration test base classes often include seed helper methods (e.g., `SeedEntity(...)`) that hardcode `DateTime.UtcNow` for time-sensitive fields (heartbeat timestamps, expiry windows, last-seen times). When the DI container under test uses an injected `FakeTimeProvider`, the seeded entity data is stamped with real wall-clock time while the container's services observe fake clock time. The two clocks diverge from the moment the seed runs.

**Why this is subtle**: The `TimeProvider` injection in the DI container looks correct. The test infrastructure appears to support deterministic time. But the seed helper bypasses the injected clock entirely, producing entity timestamps that cannot be controlled from the test.

**Testability signal**: When a codebase uses `FakeTimeProvider` and has an integration test base class with seed helpers, inspect every seed helper for `DateTime.UtcNow`, `DateTime.Now`, or `DateTimeOffset.UtcNow` direct calls on time-sensitive fields. Any such field that a test might later assert against (e.g., "this entity should be stale because its timestamp is X minutes in the past") is a latent test-nondeterminism bug.

**Recommendation**: Seed helpers that set time-sensitive fields should accept an optional `DateTime?` or `DateTimeOffset?` parameter with a default of `DateTime.UtcNow` / the wall clock. This lets tests that care about time control the seeded timestamp while existing callers get the current behavior unchanged. The fix is low-cost and unlocks the full value of the injected `FakeTimeProvider`.

---

## 2026-05-30 — Pre-Evaluated Boolean Flags in a Context Object: The Optimal DI Boundary for Pure Evaluators

**Pattern**: A service that evaluates authorization or business rules sometimes needs the results of external queries (e.g., "does this principal hold permission X?"). One design routes those queries through injected dependencies inside the evaluator — but this forces tests to mock those dependencies. A better design pre-evaluates all external lookups at the call site and passes the boolean results in a purpose-built context object. The evaluator receives only plain data and performs only logic.

**Why it is optimal for testability**: (1) The evaluator has zero constructor parameters, so tests instantiate it with `new` — no DI setup required. (2) The context object is a simple record with `init`-only properties; tests construct scenario-specific instances inline without factories. (3) The service is pure — identical inputs always produce identical outputs — which makes parametric test cases trivially expressible.

**How to recognize the opportunity**: When an evaluator's dependencies are exclusively read-only lookups that produce a boolean answer (e.g., "does the user hold role X?", "is this entity in state Y?"), the lookup can be pushed to the caller and the result passed as a flag. The evaluator's job is then solely to combine those flags under the domain rules — no I/O required.

**Assessment signal**: When auditing an authorization or rule-evaluation service, check whether its injected dependencies exist purely to produce `bool` answers. If so, the service is a candidate for the context-object pattern. Conversely, if the service needs to query mutable state or perform I/O as part of evaluation (not just for lookup), injection remains the correct approach.

**False positive avoidance**: Do not apply this pattern when the evaluation itself must query a changing store (e.g., "count how many times this user has acted today" — a query that cannot be pre-evaluated without reading the full execution context at call time).




## Sole `virtual` member in a namespace is a test-infrastructure-bleed diagnostic
**Category**: Process/Model

When scanning a namespace where every type is `sealed` or non-`virtual` except for exactly one property on a plain data model class, treat that lone `virtual` as a test-infrastructure smell and investigate before rating it Low. The pattern arises when a test subclasses a domain model to inject failure behavior (e.g., throwing from a property to simulate an engine error), and the `virtual` modifier is the only structural concession made to that test. Severity is **Medium**, not Low, because:
- The `virtual` declaration opens the class to unintended extension in production contexts
- It creates asymmetry within the type that future maintainers must explain
- Each new property added to the class will face a "should this also be virtual?" question, and the precedent pulls toward yes
- **Resolution rule:** check whether the `virtual` exists solely for test subclassing; if so, it's Medium with a recommendation to use mocking or a factory instead

---

## In-process test harness DI preamble: severity scales with extension-method delegation depth

**Date**: 2026-05-24
**Category**: Process/Model

When a test harness builds a service container by inlining registrations copied from the production entry point (e.g., a `Program.cs` startup sequence), rate the DRY violation based on how much of the sequence the harness delegates through the same extension methods versus hardcodes inline:

- **High** — if the harness hardcodes all registrations inline with no link to the production entry point and no enforcement mechanism (comment, shared method, or test that would fail on drift).
- **High, mitigated** — if the harness calls the same extension methods as production for the bulk of registrations, but hardcodes the "preamble" (e.g., `AddDbContext`, `AddSingleton<TimeProvider>`) directly. The drift scope is narrower (only new top-level calls would be missed), but still unguarded. **Recommend:** a prominent sync comment or a shared registration helper that both the entry point and the harness call.

The recommendation in both cases is the same: add a `// ⚠️ Keep in sync with [entry point file]` comment above the preamble, or extract the shared portion to a static helper that eliminates the copy. The failure mode is that a new extension call is added to the entry point and the harness silently tests a different container — tests pass, production fails.

---

