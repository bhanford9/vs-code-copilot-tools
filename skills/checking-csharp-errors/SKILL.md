---
name: checking-csharp-errors
description: Check C# files for errors, warnings, and diagnostics using VS Code language server task instead of compilation. Use when checking C# files, when user mentions C# errors or compilation issues, instead of get_errors tool, or when user references the "Check Changed Files" task.
---

# Checking C# Errors

> The core rules (use Check Changed Files, never get_errors, don't run dotnet build) are enforced automatically via [`csharp-diagnostics.instructions.md`](~/Repos/vs-code-copilot-tools/instructions/csharp-diagnostics.instructions.md) on all `*.cs` files. This skill provides the detailed workflow and step-by-step checklist.

## Workflow

Copy this checklist and track progress:

```
C# Diagnostics Check:
- [ ] Run "Check Changed Files" task
- [ ] Wait for csharp-diagnostics-report.tmp to exist
- [ ] Read report from workspace root
- [ ] Address errors and warnings
- [ ] Re-run to verify fixes
```

### Run the Task
Execute the task named exactly **"Check Changed Files"** (don't search by other names).

### Wait for Completion Signal
The file `csharp-diagnostics-report.tmp` is **deleted at task start** and **created when complete**. Wait for this file to exist before reading.

### Read Results
Read `csharp-diagnostics-report.tmp` in workspace root. Contains errors, warnings, and info messages with error codes (e.g., CS0103).

## Key Rules

**✅ DO:**
- Read [LessonsLearned.md](LessonsLearned.md) before the session for known error patterns
- Wait for report file creation before reading
- Check after every C# file modification; re-run after every fix (not just at session end)
- Filter to **`error` and `warning` severity only** — info-level messages also appear but are rarely actionable
- Use **CS error codes** as the authoritative signal when message text is ambiguous
- Verify fixes before marking tasks complete

**❌ DON'T:**
- Read report before task completes
- Run `dotnet build` or `msbuild` as a substitute

## Multi-Root Workspaces

In multi-root workspaces, `csharp-diagnostics-report.tmp` is written to the **root of the workspace folder that was opened**, not necessarily the folder containing the `.sln` file. If the report isn't found, check sibling workspace folder roots.

## Known Failure Modes

- **Task not found**: If the task is missing from `.vscode/tasks.json`, the workflow breaks silently — the agent may fall back to `get_errors` or `dotnet build`. Verify the task exists before starting.
- **Stale report**: If the task was interrupted, the `.tmp` file may reflect a prior run. Always verify the last-modified timestamp before trusting content.
- **Errors in generated files** (`*.g.cs`, `*.Designer.cs`): These are downstream of a source file error. Fix the source error first; generated file errors typically resolve themselves.

## Common CS Error Codes

| Code | Meaning | Common Cause |
|---|---|---|
| CS0246 / CS0234 | Type or namespace not found | Missing `using` directive or renamed namespace — check the fully qualified name first |
| CS1061 | Member not found on type | Often caused by mocking a concrete type — use an interface or support helper instead |
| CS1503 | Argument type mismatch | Wrong type passed to a method — verify the method signature |

## Feedback Loop

Before starting, read `~/Repos/vs-code-copilot-tools/skills/checking-csharp-errors/LessonsLearned.GLOBAL.md` and, if it exists on disk, `~/Repos/vs-code-copilot-tools/skills/checking-csharp-errors/LessonsLearned.md`. Apply any recorded error patterns.

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, follow the two-tier feedback loop from `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md`:
- **Codebase findings** (error patterns specific to this codebase, task paths, project-specific CS errors) → write to `LessonsLearned.md`
- **Process findings** (general C# diagnostic workflow improvements) → write to `LessonsLearned.GLOBAL.md`

Both files are at `~/Repos/vs-code-copilot-tools/skills/checking-csharp-errors/`.
