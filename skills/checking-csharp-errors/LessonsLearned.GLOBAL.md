# Lessons Learned: checking-csharp-errors

> This file is updated at the end of sessions that involve C# error checking.
> Read it before running diagnostics to apply accumulated knowledge.

---

## Seeded Knowledge

### Task Availability

- **The "Check Changed Files" task must exist in the workspace's `.vscode/tasks.json`.** If the task is not found, the workflow breaks silently — the agent may fall back to `get_errors` or `dotnet build` without flagging the issue. Verify the task exists before starting any C# edit session.
- **In multi-root workspaces**, the `csharp-diagnostics-report.tmp` file is written to the **root of the workspace folder that was opened**, not necessarily the folder containing the `.sln` file. If the report isn't found at the workspace root, check sibling workspace folder roots.

### Report Reading

- **The report is deleted at task start.** Attempting to read a stale report from a previous run will produce misleading results. Always verify the file's last-modified timestamp before trusting its content.
- **Info-level messages (not just errors and warnings) appear in the report.** Filter to `error` and `warning` severity unless investigating a specific info message.
- **CS error codes are the authoritative signal.** When the message text is ambiguous, look up the CS code directly (e.g., CS0246 = type not found, CS1503 = argument type mismatch).

### Common Error Patterns in This Codebase

- **CS0246 / CS0234**: Usually a missing `using` directive or a namespace was renamed. Check the fully qualified name first before adding a using.
- **CS1061**: Member not found on type — often caused by mocking a concrete type (use an interface or a support helper instead).
- **Errors in generated files** (e.g., `*.g.cs`, `*.Designer.cs`): These are usually downstream of an error in the source file. Fix the source error first; the generated file errors typically resolve themselves.

### Workflow Notes

- **Re-run after every fix**, not just at the end of a session. Fixing one error sometimes reveals a previously hidden error that the compiler skipped.
- **Do not run `dotnet build` or `msbuild` as a substitute.** The "Check Changed Files" task uses the language server and reports faster, scoped to changed files only, without requiring a full build.

---

## When to Append an Entry

Only append if something was harder than expected or revealed a behavior not already documented in this skill. If the workflow ran smoothly, skip the update.

Write a short descriptive heading, then free-form notes. Consider: new CS error codes or patterns, task availability issues, unexpected report path behavior, downstream error chains.
