# LessonsLearned.GLOBAL.md — running-stryker

Process observations and gotchas that apply across all C# projects using Stryker.NET.
These are written by agents at the end of each session and read at the start of the next.

---

## Entry #1 — Glob Path Syntax for `--mutate` (Critical)

**Date:** 2026-05-28
**Category:** Process/Tooling

**What happened:** Stryker `--mutate` was called with an absolute file path. The run completed with no meaningful output — mutations appeared to have no targets, resulting in a score of 0 or an empty report.

**Root cause:** Stryker resolves `--mutate` paths as glob patterns relative to the project root. An absolute Windows path does not match any glob pattern Stryker knows about, so it silently mutates nothing.

**Correct pattern:**
```powershell
dotnet stryker --mutate "**/YourFolder/YourFile.cs"
```

**Watch out for:** Missing `**` at the start, or using the full filesystem path. Always test that the glob at least matches by verifying that Stryker reports `N source file(s)` in its startup output.

---

## Entry #2 — NullLogger Swallows Logging Statement Mutations

**Date:** 2026-05-28  
**Category:** Process/Testing

**What happened:** A `_logger.LogError(...)` statement in a service class was mutated (statement removed). The mutation survived because `NullLogger<T>.Instance` discards all log calls — there was no assertion that logging occurred.
**Resolution:** For tests where logging IS contractual behavior, use `Mock<ILogger<T>>` and verify the `LogError` call explicitly. For tests where logging is infrastructure noise, `NullLogger` is correct and the surviving mutation should be documented as accepted noise.

**Template for verifying LogError with Moq:**
```csharp
loggerMock.Verify(x => x.Log(
    LogLevel.Error,
    It.IsAny<EventId>(),
    It.Is<It.IsAnyType>((v, _) => v.ToString()!.Contains("expected message fragment")),
    It.IsAny<Exception?>(),
    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
    Times.Once);
```

---

## Entry #3 — Scope Coverage Gaps: Test All Enum Values of a Guardrail Set

**Date:** 2026-05-28  
**Category:** Process/Testing

**What happened:** A guardrail set contained items from multiple scope categories. Initial tests only parameterized items from one category. Items from the other category survived mutation.
**Rule:** Whenever a guardrail, allowlist, or constant set spans multiple enum values or categories, parameterize tests across all categories — not just the obvious or first one. Enumerate the full set during test planning, not mid-mutation-remediation.

---

## Entry #4 — Run Stryker from the Test Project Directory

**Date:** 2026-05-28  
**Category:** Process/Tooling

**What happened:** Running `dotnet stryker` from the solution root produced unexpected behavior or wrong project targeting.

**Resolution:** Always `cd` to the test project directory before running `dotnet stryker`. Stryker reads `stryker-config.json` from the current directory.

```powershell
cd tests/<YourTestProject>
dotnet stryker --mutate "**/YourFolder/YourFile.cs"
