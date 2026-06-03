---
name: writing-e2e-tests
description: Structured workflow for writing C# Playwright E2E tests. Covers reading lessons learned, goal formation, app observation, test planning, implementation, failure diagnosis, and lessons learned. Use when writing browser-level end-to-end tests against a running application in any C# codebase using Microsoft.Playwright.NUnit.
---

# Writing C# Playwright E2E Tests

> This skill governs the full E2E test-writing workflow: from understanding what behavior to verify, through observing the live UI, writing and running tests, diagnosing failures at the right level, and capturing what was learned.
>
> E2E tests are fundamentally different from unit and integration tests. They operate a real browser against a real (or factory-hosted) application, which means: timing, selectors, and async rendering behavior matter as much as the test logic itself. This skill treats those concerns as first-class.

---

## Non-Negotiable Rules

- **Never assert immediately after a user interaction.** Blazor Server (and most SPA frameworks) update the DOM asynchronously via a round-trip. Always use auto-retrying assertions or explicit wait patterns.
- **Verify every selector in the live app before using it in an assertion.** HTML structure does not always match component documentation. Use `Page.ContentAsync()` or Playwright codegen to inspect real structure.
- **A failing test is not automatically a bug in production code.** Always diagnose the failure level first (test setup, environment, or source code) before changing anything.
- **Record harvest candidates during the observation step**, not at the end. UI behavior that isn't documented anywhere is a documentation gap — surface it before writing the test.

---

## Checklist

Copy when starting a new E2E test session:

```
E2E Test Checklist:
- [ ] Read LessonsLearned.GLOBAL.md
- [ ] Read LessonsLearned.md (if it exists — codebase-specific selectors, timing patterns)
- [ ] Stated the goal: which user behavior am I proving works?
- [ ] Observed the live app — identified the controls, routes, and assertions needed
- [ ] Planned the test(s) before writing any code
- [ ] Infrastructure compiles and one smoke test passes before writing scenario tests
- [ ] Every assertion uses auto-retry or WaitFor pattern
- [ ] Tests pass in headless AND headed mode
- [ ] Updated LessonsLearned files at the end
```

---

## Step 1 — Read Lessons Learned

**Before doing anything else**, read both lessons learned files:

1. **`LessonsLearned.GLOBAL.md`** (in this skill's directory) — cross-project process observations: timing pitfalls, selector patterns that break, infrastructure gotchas
2. **`LessonsLearned.md`** (in this skill's directory, if it exists on disk) — codebase-specific notes: real selector strings that work, known timing thresholds, factory setup quirks

Apply any "watch out for" notes to this session before touching any code.

---

## Step 2 — Form the High-Level Goal

Write a single, concrete statement of what user-observable behavior this session will prove. Be specific enough that a failing test gives a clear signal.

**Useful framing questions:**
- *What can a user do in the application that must always work?*
- *What does the user see after a specific action?*
- *What must NOT appear after an action (negative assertions)?*
- *Is this a happy-path flow, an error path, or a boundary condition?*

**Examples of well-formed goals:**
- "Prove that creating a task places it on the board in the correct quadrant, with the correct status badge."
- "Prove that clicking Start on a task transitions its status badge from Pending to InProgress without a page reload."
- "Prove that the History tab shows a Completed event after a task is completed."

**Anti-patterns to avoid:**
- "Test the task lifecycle" — too vague, leads to a test that asserts nothing meaningful
- "Make sure it works" — not an observable goal

Write the goal into session memory before proceeding.

---

## Step 3 — Observe the Live Application

**Do not write any test code until you have observed the live application first.**

The purpose of this step is to collect the raw facts a test needs: the exact URL routes, the exact HTML selectors, and the exact DOM states that correspond to the behaviors you want to assert.

> **You have access to the VS Code integrated browser and the Playwright extension.** Use `run_playwright_code` to execute Playwright snippets directly against the running application — navigate pages, dump the DOM, click controls, and observe state changes — before writing a single test. This is your primary observation tool. Use it freely; it does not affect any test infrastructure.

### 3.0 — Open the Application in the Integrated Browser

Before doing anything else, open the application's base URL in the VS Code integrated browser (via `open_browser_page`) so you can see it visually while running Playwright code. Confirm the page loads and you're looking at the right feature area.

### 3.1 — Identify the Entry Point

Navigate to the feature's starting URL using `run_playwright_code`:

```js
await page.goto('/board');
console.log(await page.title());
```

Note:
- The full path (e.g. `/board`, `/tasks/{id}`)
- Any query parameters or route segments required
- Any pre-conditions that must be true before the URL is navigable (auth, seeded data)

### 3.2 — Identify the Controls

For each user interaction in your goal, use `run_playwright_code` to probe the real DOM. Do not guess selectors from reading component code — verify them live:

```js
// Dump all elements matching a candidate selector
const elements = await page.$$('[data-testid]');
for (const el of elements) {
    const testId = await el.getAttribute('data-testid');
    const text = await el.textContent();
    console.log(`testId=${testId}  text=${text?.trim()}`);
}
```

```js
// Verify a specific selector exists and is unique
const count = await page.locator('[data-testid="start-button"]').count();
console.log('count:', count); // should be 1 for the target element
```

Record the **most stable selector** available for each control (in priority order):
  1. `data-testid` attribute (most stable — add one if missing)
  2. `aria-label` or `role` (semantic, stable)
  3. Text content via `:has-text()` (stable if text doesn't change)
  4. CSS class (fragile — avoid unless the class is semantically meaningful and unlikely to change)
  5. DOM position selectors like `nth-child` (never use — breaks on layout changes)

> ⚠️ **If the element lacks a stable selector**, add a `data-testid` attribute to the source component before writing the test. Do not write tests that depend on fragile structural selectors — they create maintenance debt.

### 3.3 — Identify the Observable State Changes

For each expected outcome in your goal, use `run_playwright_code` to trigger the action and observe what the DOM actually does:

```js
// Click a control and observe the resulting DOM state
await page.click('[data-testid="start-button"]');
await page.waitForTimeout(500); // brief settle for async updates
const badgeText = await page.locator('[data-testid="status-badge"]').textContent();
console.log('badge after click:', badgeText);
```

Record:
- The DOM state that proves the outcome occurred (element present, element text, element class, element count)
- Whether the state change happens synchronously (rare) or after an async round-trip (usual)
- The maximum time the application takes to reach that state — measure it here rather than guessing in the test

> `waitForTimeout` is acceptable during observation to understand timing. It must NOT appear in the final test — replace it with `waitForSelector` or a locator assertion.

### 3.4 — Record as Harvest Candidates

Any behavior you observe during this step that is not documented in the project's architecture docs is a harvest candidate. Note it:
- Which feature/view/control this covers
- What it does that you didn't know before observing it
- Whether it contradicts existing documentation

---

## Step 4 — Plan the Tests

Before writing code, write the test plan as prose or pseudocode. Each test should be expressible in three parts:

```
Given: [preconditions — what data exists, what state the app is in]
When:  [user actions — what the user does in the browser]
Then:  [assertions — what is verifiably true afterward]
```

**Guidance:**
- One behavior per test. A test that navigates, creates a task, starts it, completes it, and checks history is five tests wearing one coat — split it.
- Seed the minimum data required. If the test only needs one task, seed one task.
- Name tests using the `Should<Behavior>When<Condition>` NUnit convention.
- Decide upfront which assertions are **load-bearing** (the test fails without them) vs **informational** (nice to assert but not the point). Informational assertions belong in separate tests.
- Consider negative tests alongside positive ones: what should NOT appear? what should NOT change?

---

## Step 5 — Write the Tests

### Infrastructure Checklist Before Writing Scenarios

Before writing any scenario tests, confirm:
- [ ] The test project compiles with `dotnet build`
- [ ] Playwright browser binaries are installed (`playwright install chromium` / `playwright install`)
- [ ] The server or factory under test is reachable at the base URL
- [ ] A smoke test passes (navigate to home, assert page title or a known element)

If any of the above fails, fix it before writing scenario tests. Do not mix infrastructure debugging with scenario test writing — they are different failure modes.

### Playwright Patterns for C#

#### Wait for DOM State, Not Time

```csharp
// ❌ Never — arbitrary sleep hides real problems
await Task.Delay(1000);

// ✅ Wait for a specific element to appear
await Page.WaitForSelectorAsync("[data-testid='status-badge'][data-status='InProgress']");

// ✅ Playwright's auto-retrying locator assertions (preferred)
await Expect(Page.Locator("[data-testid='status-badge']")).ToHaveTextAsync("InProgress");

// ✅ Wait for a URL to match (after navigation)
await Page.WaitForURLAsync("**/board/**");
```

#### Use Locators, Not Selectors, for Assertions

`Locator` objects are lazy and auto-retry on assertions. Raw selectors from `QuerySelectorAsync` do not retry.

```csharp
// ❌ Fragile — snapshot of DOM at call time
var el = await Page.QuerySelectorAsync(".status-badge");
var text = await el!.TextContentAsync();
text.Should().Be("InProgress");

// ✅ Resilient — retries until timeout
var badge = Page.Locator("[data-testid='status-badge']");
await Expect(badge).ToHaveTextAsync("InProgress");
```

#### Fill Forms

```csharp
await Page.FillAsync("[data-testid='task-title-input']", "My test task");
await Page.SelectOptionAsync("[data-testid='horizon-select']", "Today");
await Page.ClickAsync("[data-testid='save-task-button']");
```

#### Scoped Locators (Within a Card/Row)

When multiple instances of the same element exist (e.g., one card per task), scope the locator:

```csharp
// Find the card for a specific task, then interact within it
var card = Page.Locator("[data-testid='task-card']").Filter(new() { HasText = "My test task" });
await card.Locator("[data-testid='start-button']").ClickAsync();
await Expect(card.Locator("[data-testid='status-badge']")).ToHaveTextAsync("InProgress");
```

#### Negative Assertions

```csharp
// Assert element does NOT exist
await Expect(Page.Locator("[data-testid='task-card']").Filter(new() { HasText = "Deleted task" }))
    .ToBeHiddenAsync();

// Assert count is zero
await Expect(Page.Locator("[data-testid='task-card']")).ToHaveCountAsync(0);
```

#### Keyboard and Accessibility

```csharp
// Tab through form; submit with Enter
await Page.FocusAsync("[data-testid='task-title-input']");
await Page.Keyboard.TypeAsync("Task via keyboard");
await Page.Keyboard.PressAsync("Tab");
await Page.Keyboard.PressAsync("Enter");
```

#### Screenshot on Failure (Attach to NUnit)

```csharp
[TearDown]
public async Task TearDown()
{
    if (TestContext.CurrentContext.Result.Outcome.Status == TestStatus.Failed)
    {
        var screenshot = await Page.ScreenshotAsync(new() { FullPage = true });
        TestContext.AddTestAttachment(
            Path.Combine(TestContext.CurrentContext.WorkDirectory, "failure.png"),
            "Failure screenshot");
        await File.WriteAllBytesAsync(
            Path.Combine(TestContext.CurrentContext.WorkDirectory, "failure.png"),
            screenshot);
    }
    await Page.CloseAsync();
}
```

### Base Class Pattern

Inherit from a shared base that handles browser lifecycle, base URL configuration, and seeding:

```csharp
[Category("E2E")]
public abstract class E2ETestBase : PageTest
{
    // Override base URL from env or config
    public override BrowserNewContextOptions ContextOptions() => new()
    {
        BaseURL = Environment.GetEnvironmentVariable("E2E_BASE_URL") ?? "http://localhost:5254"
    };

    [SetUp]    public virtual async Task SetUpData() => await SeedAsync();

    [TearDown]
    public virtual async Task TearDownData()
    {
        await CleanupAsync();
        if (TestContext.CurrentContext.Result.Outcome.Status == TestStatus.Failed)
            await Page.ScreenshotAsync(new() { Path = $"failure-{TestContext.CurrentContext.Test.Name}.png", FullPage = true });
    }

    protected virtual Task SeedAsync() => Task.CompletedTask;
    protected virtual Task CleanupAsync() => Task.CompletedTask;
}
```

---

## Step 6 — Run the Tests

```bash
# Run only E2E tests (use Category filter to avoid running API/unit tests)
dotnet test tests/YourProject.Tests.E2E --filter "Category=E2E" -v minimal

# Run headed (with browser window visible) for local debugging
PLAYWRIGHT_HEADED=true dotnet test tests/YourProject.Tests.E2E --filter "Category=E2E"

# Run a single test by name
dotnet test tests/YourProject.Tests.E2E --filter "FullyQualifiedName~ShouldShowTaskAsPendingWhenCreated"
```

**What to look for in the output:**
- Exit code 0 = all passed
- Exit code 1 = one or more failed — read the output carefully before acting
- `TimeoutException: Timeout 30000ms exceeded` — a Wait pattern didn't resolve; likely a selector mismatch or Blazor update didn't fire
- `ElementNotFound` / `StrictModeViolation` — selector matched zero or more than one element

---

## Step 7 — Diagnose and Fix Failures

When a test fails, **diagnose the failure level before changing anything**. There are three distinct failure causes; each requires a different fix.

### Decision Tree

```
Test failed?
│
├── Is the server/factory not responding, or the page not loading at all?
│   └── ENVIRONMENT SETUP issue → Fix: server not running, wrong port, missing DB seed
│
├── Did the right page load but the selector found nothing / wrong element?
│   └── TEST SETUP issue → Fix: wrong selector, wrong timing, wrong seed data
│       Specifically:
│       ├── Timeout waiting for selector → add WaitForSelectorAsync or increase timeout
│       ├── StrictModeViolation (>1 match) → make selector more specific
│       └── Element found but wrong text → seed data doesn't match assertion
│
└── Did the test set up correctly but the application behaved unexpectedly?
    └── SOURCE CODE BUG → Fix: this is what E2E tests exist to catch
        Specifically:
        ├── Status badge didn't update → UI not re-rendering after state change
        ├── Wrong count in stat bar → service logic error
        └── Navigation didn't complete → routing issue
```

### 7.1 — Environment Setup Issues

Signs:
- `ERR_CONNECTION_REFUSED` or `net::ERR_EMPTY_RESPONSE`
- Factory fails to start (check `OneTimeSetUp` logs)
- All tests fail on the same assertion (sign of missing seed data or cache state)

Fixes:
- Confirm the app / factory is running and listening on the expected port
- Check that `OneTimeSetUp` completed successfully (Testcontainers started, factory initialized)
- Check that `IBoardStateCache` (or equivalent singleton) was refreshed after seeding (see Pitfall 6 in phase-3.md)

### 7.2 — Test Setup Issues

Signs:
- `TimeoutException: Timeout 30000ms exceeded waiting for selector ...`
- `ElementNotFoundError`
- Assertion on text content fails even though the behavior looks correct in the browser

Fixes:
1. Use `run_playwright_code` in the integrated browser to navigate to the failing page and inspect the live DOM at the moment of failure
2. Run the test in **headed mode** (`Headless = false`) to watch what the browser actually does
3. Add `await Page.PauseAsync()` before the failing assertion to enter Playwright's interactive inspector
4. Use `Page.ContentAsync()` to dump the current DOM and find the real selector
5. Check if the element exists but is hidden — use `ToBeVisibleAsync()` instead of `ToHaveTextAsync()`
6. If a SignalR/Blazor update is slow: increase the `Expect` timeout with `new LocatorAssertionsToHaveTextOptions { Timeout = 5000 }`

### 7.3 — Source Code Bugs

Signs:
- Headed mode shows the behavior is wrong (not just "selector not found")
- The assertion accurately describes what should happen, but the UI doesn't do it
- The same scenario passes in unit/integration tests but not E2E (plumbing/wiring issue)

Actions:
1. Add the bug to a separate task — do not fix it inside the test-writing session unless it is trivial
2. Document the bug in session memory: what the test expected, what the app actually did, where the bug likely lives
3. Mark the test as `[Ignore("Bug: <description> — tracked as <task-id>")]` so the suite stays green
4. Fix the bug, remove the `[Ignore]`, re-run

> **Do not change the test assertion to match wrong behavior.** The test is correct; the application is wrong. Changing the assertion silently encodes the bug as accepted behavior.

---

## Step 8 — Update Lessons Learned

After all tests pass (or are appropriately ignored with tracked issues), run the two-tier LessonsLearned reflection:

### What to write to `LessonsLearned.GLOBAL.md` (process/model):
- Selector patterns that proved stable vs fragile across this codebase type
- Wait strategy that worked for a specific framework (Blazor, React, etc.)
- Diagnosis patterns that saved time
- Infrastructure pitfalls (factory setup, browser install, port assignment)
- Any deviation from this skill's guidance that produced a better outcome (candidate for promoting into the skill body)

### What to write to `LessonsLearned.md` (codebase-specific, local only):
- Actual `data-testid` values that work in the project
- Known slow UI transitions and their appropriate timeout thresholds
- Which seed helpers produce reliable state for which test scenarios
- Selectors that look right but break (and why)
- The correct base URL and any factory configuration quirks

Follow the two-tier feedback loop from the `lessons-learned` skill: codebase discoveries → `LessonsLearned.md`; process findings → `LessonsLearned.GLOBAL.md`.

---

## Feedback Loop

When this workflow is complete, **proceed directly into the lessons learned reflection** — do not ask for permission first. Follow the two-tier feedback loop from the `lessons-learned` skill:
- **Codebase findings** (selector strings, timing thresholds, seed helpers) → write to `LessonsLearned.md`
- **Process/Model findings** (wait patterns, diagnosis strategies, infrastructure pitfalls) → write to `LessonsLearned.GLOBAL.md`
