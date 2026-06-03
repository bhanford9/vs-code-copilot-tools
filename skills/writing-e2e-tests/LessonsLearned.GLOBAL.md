# Lessons Learned (Global): writing-e2e-tests

> This file contains process/model observations applicable to any user of the writing-e2e-tests skill, across any C# Playwright project.
> Read it before writing E2E tests. Update it only for `Category: Process/Model` findings.
>
> For codebase-specific discoveries (actual selector strings, timing thresholds, seed helper patterns),
> write to `LessonsLearned.md` (gitignored, local to your workspace).

---

*(No entries yet — append after sessions where a process or workflow gap was discovered.)*

---

## Entry 1 — Blazor Web App (.NET 8+): `Blazor.addEventListener('afterStarted')` Does Not Fire

**Category:** Process / Blazor Circuit Readiness  
**Discovered:** 2026-05

`Blazor.addEventListener('afterStarted', fn)` does NOT reliably fire in the Blazor Web App model (.NET 8+). The inline script executes synchronously, `window.Blazor` is defined, but the callback never fires — because the event names in the new unified model are different (`afterWebStarted`, `afterServerStarted`, etc.) and the timing is not guaranteed relative to the script tag.

**The only reliable pattern:** Create a Blazor component that calls a JS function in `OnAfterRenderAsync(bool firstRender)`. This is guaranteed to run only after the Interactive Server circuit is fully open — never during static SSR prerender.

```razor
@* CircuitReadySignal.razor *@
@inject IJSRuntime JS

@code {
    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (firstRender)
            await JS.InvokeVoidAsync("setCircuitReady");
    }
}
```

```html
<!-- App.razor: add the component alongside Routes and define the JS function -->
<CircuitReadySignal @rendermode="InteractiveServer" />
<script>
    window.setCircuitReady = function () {
        document.body.setAttribute('data-blazor-connected', 'true');
    };
</script>
```

Then in E2E tests, gate on the attribute:
```csharp
await Page.WaitForFunctionAsync(
    "() => document.body.getAttribute('data-blazor-connected') === 'true'",
    null, new PageWaitForFunctionOptions { Timeout = 30_000 });
```

---

## Entry 2 — Playwright Dismisses `confirm()` Dialogs By Default

**Category:** Process / Browser Dialog Handling  
**Discovered:** 2026-05

When a Blazor component calls `JSRuntime.InvokeAsync<bool>("confirm", "...")`, Playwright dismisses the dialog by default (returns `false`). Any action guarded by `confirm()` will silently no-op. The test appears to pass setup but the next assertion ("was the item deleted?") fails with an error that looks like an application bug.

**Fix:** Register a `Page.Dialog` handler BEFORE triggering the action:

```csharp
Page.Dialog += (_, dialog) => _ = dialog.AcceptAsync();
await modal.Locator("[data-testid='delete-btn']").ClickAsync();
```

`RunAndWaitForDialogAsync` does NOT exist in the Playwright .NET API — use the event handler approach.

---

## Entry 3 — Never Wait for `Visible` State on an Already-Visible Element After a Blazor Click

**Category:** Process / Assertion Timing  
**Discovered:** 2026-05

After an interactive Blazor click (e.g., a status transition button), this pattern is WRONG:

```csharp
// WRONG — badge is already Visible, so WaitForAsync resolves instantly
await statusBadge.WaitForAsync(new() { State = WaitForSelectorState.Visible });
var text = await statusBadge.InnerTextAsync(); // reads OLD value
```

Blazor's SignalR round-trip hasn't completed yet. `WaitForAsync(Visible)` resolves immediately because the element is already visible, then you read the stale DOM value.

**Always use auto-retrying Playwright assertions:**

```csharp
// CORRECT — polls until the text changes or timeout
await Expect(statusBadge).ToContainTextAsync("InProgress", new() { Timeout = 10_000 });
```

**Rule:** After any Blazor interactive action, use `Expect(locator).ToXxxAsync()`. Never read a locator's value immediately after a click.

---

## Entry 4 — Write One Smoke Test Before Any Scenario Tests

**Category:** Process / Infrastructure Validation Discipline  
**Discovered:** 2026-05

E2E test infrastructure has multiple independent failure modes: database container, factory startup, static asset serving, Blazor circuit, SignalR, host filtering. If you write scenario tests before proving the infrastructure works end-to-end, every failure is ambiguous — is it an app bug or an infrastructure problem?

**Required sequence:**
1. Write one smoke test that only navigates and checks a heading element
2. Run it in isolation — confirm it passes
3. Only then write scenario tests

Keep the smoke test minimal. Do not add business logic to it. If it fails, investigate the infrastructure (factory startup, port binding, AllowedHosts, static assets, Blazor loading) before writing other tests.

**Diagnostic approach when the smoke test fails:**
- Add `Console.WriteLine(await Page.ContentAsync())` to see the actual HTML
- Check `typeof window.Blazor !== 'undefined'` via `Page.EvaluateAsync<bool>` to test JS loading
- Check network requests for 4xx or 5xx on static assets
- Check server logs for startup exceptions




## 2026-05-23 — Circuit-Open Signals in Blazor Do Not Guarantee ViewModel Data Loaded

**Pattern**: In Blazor Interactive Server applications, `OnAfterRenderAsync(firstRender: true)` on a component with `@rendermode="InteractiveServer"` fires reliably after the SignalR circuit is established. It does NOT mean async ViewModel initialization (e.g., database calls triggered in `OnInitializedAsync`) has completed. E2E tests that gate on a circuit-open DOM attribute are safe to click interactive elements but may still race against data loading.

**Testability signal**: When reviewing Blazor E2E infrastructure, look for a circuit-ready DOM attribute/signal. If tests use it as the sole readiness gate without also waiting for specific data elements (e.g., `WaitForSelectorAsync`), flag as Low — the signal is not wrong, but test authors need an explicit convention to also wait for loaded content.

---

## 2026-05-23 — List-Item `data-testid` Without Entity Identity Attribute Warrants Medium Severity

**Pattern**: When a list/grid view renders items with a `data-testid` container attribute but no entity identity attribute (e.g., `data-[entity]-id`), asserting on a *specific* item requires text-matching the display content. This is fragile — titles change, localization changes them, test data naming changes them.

**Testability signal**: Audit each `data-testid` that appears on a repeated item (inside a `@foreach`). If none of them include an identity attribute pointing to the entity's ID, flag as Medium. The fix is one attribute addition per template.

---

## 2026-05-23 — Private Seeding Helper in a Concrete Subclass: Reliable Medium Finding

**Finding**: When a test base class provides protected seeding helpers for common entities, but a concrete subclass introduces a *new* seeding helper as `private` that encodes non-obvious setup requirements (e.g., a specific configuration field required to bypass a specific gate), that helper is a reliable **Medium** extensibility finding. The helper will be duplicated on the first new test class that shares the same domain area, and the non-obvious requirement it encodes (the pitfall comment) will either be re-discovered or silently violated.

**Heuristic**: When reviewing a test project with a base-class seeding infrastructure, enumerate all `private` methods in concrete subclasses that: (a) return a domain entity type, (b) call DI services or the database directly, and (c) have a comment explaining a non-obvious constraint. Each is a candidate for promotion to a `protected` method on the base class.

**Severity calibration**: Elevate to High only if the fixture's seeding logic is the *only* way to exercise a critical code path and there is already a second test class that needs it. Medium is correct when the duplication is anticipated but not yet occurring.

**Corollary**: The recommendation is always the same: move to the base class with the original docstring preserved. Parameters should be optional with the current values as defaults so existing call sites change minimally.

---

## 2026-05-23 — Undocumented data-testid Convention: Reliable Medium Finding in UI Test Infrastructure

**Finding**: When a UI component library uses `data-testid` attributes for test targeting (Playwright, Cypress, etc.) but the naming convention is only implicit — inferred by reading 10+ component files — this is a reliable **Medium** extensibility finding. The convention typically contains 3–5 distinct sub-patterns (component root, action buttons, status-keyed containers, view-specific items) that diverge without documentation. Internal inconsistencies in the existing components (e.g., hardcoded values in one view vs. interpolated values in another) are confirming evidence that the convention has already begun to drift.

**Heuristic**: Search for `data-testid` in all component files. Cluster the values by structural pattern. If there are 3+ structurally distinct clusters and no documentation file that defines the convention, this is a Medium finding. Check for internal inconsistencies (same view type using two different formats) to confirm.

**Severity calibration**: Medium is appropriate when the convention is recoverable by observation and existing tests are not broken. Elevate to High only if the inconsistency is actively causing test failures or if a documented naming standard was established and then violated.

**Corollary**: The fix is always documentation, not code. A table in the architecture docs covering each sub-pattern with an example is sufficient. No code changes are needed unless existing attributes need normalization.

---

