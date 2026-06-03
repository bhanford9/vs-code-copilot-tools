---
name: running-stryker
description: Structured workflow for running Stryker.NET mutation testing and reading results in a token-efficient way. Covers glob path syntax, JSON result parsing (not HTML), survivor triage, gap remediation, and the LessonsLearned feedback loop. Use when running mutation testing, checking mutation scores, triaging surviving mutants, or adding gap-coverage tests after a Stryker run.
---

# Running Stryker.NET Mutation Testing

> Mutation testing goes beyond line coverage: it verifies that your tests actually *detect* behavioral changes in the code under test. A surviving mutant means a test suite that would not catch a real bug. This skill drives a full mutation run from setup to remediation to documentation.

---

## Non-Negotiable Rules

- **Always use glob paths for `--mutate`**, not absolute paths. See Section 4.
- **Always read results from JSON**, not from the HTML report. The HTML file is 100+ KB of DOM and wastes context. See Section 6.
- **Triage every survivor** before adding new tests. Not all survivors are meaningful. See Section 7.
- **Record every new pattern discovered** in `LessonsLearned.GLOBAL.md` at session end.

---

## Checklist

Copy when starting a Stryker session:

```
Stryker Checklist:
- [ ] Read LessonsLearned.GLOBAL.md for known gotchas
- [ ] Confirmed --mutate uses glob syntax (not absolute path)
- [ ] Full test suite is green before running Stryker
- [ ] Stryker targeted the correct project
- [ ] Results read from JSON, not HTML
- [ ] Every survivor triaged: meaningful gap or acceptable noise?
- [ ] New tests written for meaningful survivors
- [ ] Full test suite re-run after new tests
- [ ] Score and findings recorded
- [ ] LessonsLearned.GLOBAL.md updated
```

---

## Step 1 — Read Lessons Learned

**Before doing anything else**, read `LessonsLearned.GLOBAL.md` in this skill's directory. Previous sessions have documented:
- Path format traps for `--mutate`
- Classes of survivors that are noise vs. meaningful gaps
- Result parsing patterns that are token-efficient

Apply any "watch out for" notes to this session.

---

## Step 2 — Confirm the Full Test Suite Is Green

Run the test suite for the project(s) you intend to mutate. Stryker runs your tests for every mutant it generates — if the baseline suite already has failures, mutation results will be misleading.

```powershell
dotnet test tests/TaskTracker.Core.Tests/TaskTracker.Core.Tests.csproj
```

If anything is red: stop, fix it, and re-run before proceeding.

---

## Step 3 — Locate the Stryker Config

Look for `stryker-config.json` in the target test project folder. Check:
- `testProjects` — which test project Stryker uses to run mutations
- `thresholds` — what score values are required (`high`, `low`, `break`)
- `mutate` — any existing file filters (may need updating)

Typical location:

```
tests/TaskTracker.Core.Tests/stryker-config.json
```

---

## Step 4 — Use Glob Paths for `--mutate` (Critical)

**The most common error:** passing an absolute path to `--mutate`. Stryker silently produces empty results or mutates nothing when given an absolute path.

**Wrong (absolute path):**
```powershell
dotnet stryker --mutate "d:\Repos_D\TaskTracker\src\TaskTracker.Core\Permissions\PermissionEvaluator.cs"
```

**Correct (glob pattern):**
```powershell
dotnet stryker --mutate "**/Permissions/PermissionEvaluator.cs"
```

The `**` glob must appear at the start if you do not know the exact nesting depth. Stryker resolves these globs relative to the project root, not the filesystem root.

To run against an entire folder:
```powershell
dotnet stryker --mutate "**/Permissions/**"
```

To run without filtering (all files in the project):
```powershell
dotnet stryker
```

**Run Stryker from the test project directory**, not from the solution root:
```powershell
cd tests/TaskTracker.Core.Tests
dotnet stryker --mutate "**/Permissions/PermissionEvaluator.cs"
```

---

## Step 5 — Read the Results from JSON (Not HTML)

After Stryker completes, it writes its output to a timestamped folder under `StrykerOutput/`. The HTML report is large (60–100 KB of DOM). **Do not use `read_page` or open the HTML file.** Use the JSON mutation report instead.

Locate the JSON report:
```powershell
Get-ChildItem -Path StrykerOutput -Recurse -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
```

The JSON report has a structure like:
```json
{
  "schemaVersion": "...",
  "thresholds": { "high": 69, "low": 59 },
  "files": {
    "path/to/File.cs": {
      "mutants": [
        {
          "id": "...",
          "mutatorName": "...",
          "replacement": "...",
          "location": { "start": { "line": 12 }, "end": { "line": 12 } },
          "status": "Survived" | "Killed" | "NoCoverage" | "Ignored" | "Timeout"
        }
      ]
    }
  }
}
```

**To extract survivors efficiently:**
```powershell
$report = Get-ChildItem -Path StrykerOutput -Recurse -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$json = Get-Content $report.FullName | ConvertFrom-Json
$json.files.PSObject.Properties | ForEach-Object {
    $file = $_.Name
    $_.Value.mutants | Where-Object { $_.status -eq "Survived" } | ForEach-Object {
        [PSCustomObject]@{
            File = $file
            Line = $_.location.start.line
            Mutator = $_.mutatorName
            Replacement = $_.replacement
        }
    }
} | Format-Table -AutoSize
```

This gives a compact table of surviving mutants without parsing HTML.

---

## Step 6 — Read the Score Summary

The mutation score appears in the terminal output when Stryker finishes. It also appears in the JSON:

```powershell
$json.files.PSObject.Properties | ForEach-Object { $_.Value.mutants } | 
  Group-Object status | Select-Object Name, Count
```

Compute the score manually if needed:
```
Score = Killed / (Killed + Survived + NoCoverage) * 100
```

Compare against the thresholds in `stryker-config.json`. If the score is below `break`, the workflow is blocked.

---

## Step 7 — Triage Surviving Mutants

Not all survivors require new tests. For each surviving mutant, ask:

| Question | If Yes | If No |
|----------|--------|-------|
| Does this mutant represent a behavior the code is contractually required to have? | Write a test that kills it | Consider accepting |
| Is this path reachable in practice? | Kill it | Document as noise |
| Is this a logging, trace, or diagnostic statement (no observable effect on logic)? | No test needed — document | Kill it |
| Is this already covered at a higher test level (integration/E2E)? | Document the coverage level | Kill it |

**Common noise categories that don't require new tests:**
- `_logger.LogError(...)` / `_logger.LogWarning(...)` statement mutations — logging is infrastructure, not logic. Use a `Mock<ILogger<T>>` if the logging behavior is itself a contract.
- Compiler-generated equality in record types that are never compared in tests
- Unreachable guard clauses that exist as defensive programming against future bugs

**Common survivors that DO require tests:**
- Conditional boundary flips (e.g., `>=` → `>`) when the boundary value has a distinct meaning
- Removed null checks that would cause `NullReferenceException` on real inputs
- Alternative implementations that produce observably different outputs on a reachable path

---

## Step 8 — Remediate Meaningful Gaps

For each survivor identified as a meaningful gap:

1. Write a new test that exercises the surviving path with an assertion that would fail on the mutant.
2. Verify the test is RED when you manually apply the mutation to the production code (optional but educational).
3. Run the full test suite to confirm GREEN.
4. Re-run Stryker to confirm the mutant is now killed.

---

## Step 9 — Record the Result

In the commit message or delivery artifact, record:
- Final mutation score
- Number of survivors triaged vs. killed
- Any survivors accepted as noise with their rationale

Format used in spec-driven-delivery:
```
Mutation: 82.50% (10 killed, 2 survived — workflow scope guardrail strings accepted as noise)
```

---

## Step 10 — Update Lessons Learned

Run the lessons-learned reflection:

- Did Stryker produce unexpected empty results? (Check glob format — see LessonsLearned entry #1)
- Did a `NullLogger` swallow a meaningful mutation? (See LessonsLearned entry #2)
- Was there a coverage scope gap (e.g., only tested one enum value of a multi-value guardrail)?
- Did a new JSON parsing pattern emerge that should be documented?

Write any new findings to **`LessonsLearned.GLOBAL.md`** in this skill's directory.

---

## Open Spike: Token-Efficient Result Parsing

> **Status: deferred — follow-up spike needed**

The current approach (PowerShell JSON parsing) is functional but has not been benchmarked against the Stryker HTML viewer or a purpose-built JSON extraction pattern. A dedicated spike should:

1. Measure token cost of current JSON approach vs. targeted PowerShell extraction vs. targeted `grep`/`jq` extraction
2. Determine whether the JSON schema is stable across Stryker versions
3. Consider whether a small helper script (checked into `scripts/` or `tools/`) would reduce per-session setup cost
4. Evaluate whether `StrykerOutput/**/*.json` nesting depth varies and whether the `Get-ChildItem` approach is robust

This spike should be tracked as a follow-up task on the board before closing any session that runs mutation testing for the first time on a new project.
