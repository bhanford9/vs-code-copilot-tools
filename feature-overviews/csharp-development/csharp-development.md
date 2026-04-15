# C# Development Assistance

Two layers of automatically-applied guidance that improve C# workflows without requiring any explicit invocation — one for error checking, one for test conventions.

## The Problem It Solves

C# agents in VS Code tend to reach for `dotnet build` or the `get_errors` tool when checking for errors, and tend to write tests with comments, wrong naming patterns, or incorrect mocking styles. Neither problem requires a full agent workflow to solve — they just need the right rules injected whenever C# or test files are in scope.

## How It Works

Both layers use `applyTo` instructions files that VS Code attaches automatically when the active files match the glob. No invocation needed.

### Error Checking (`applyTo: "**/*.cs"`)

Whenever a `.cs` file is in context, the agent is told to use the **"Check Changed Files"** VS Code task instead of `dotnet build` or `get_errors`. The task writes a `csharp-diagnostics-report.tmp` file when complete — the agent waits for that file before reading results.

The reason this matters: `get_errors` and `dotnet build` both produce incomplete or misleading results compared to the language server task. Enforcing the correct mechanism as a rule means it happens consistently without the user needing to remind the agent.

The `checking-csharp-errors` skill provides the step-by-step checklist and known failure mode details for sessions that need deeper guidance.

### Test Conventions (`applyTo: "**/*Tests.cs"`)

Whenever a `*Tests.cs` file is in context, core test conventions are injected: naming pattern (`Should<Behavior>When<Condition>`), no comments in test code, Moq Verifiable pattern for mocked expectations, and `[TestCase]` for simple variations.

These are the baseline rules that apply to every test edit. The `writing-csharp-tests` skill and `@UnitTestWriter` agent layer on top for full test-writing sessions requiring pattern research and type verification.

## Two Layers, Same Topic

The instructions files enforce the baseline automatically. The skills extend with workflow depth. For quick edits and single-file changes, the instructions are sufficient. For dedicated test-writing or diagnosing complex error patterns, invoke the corresponding skill.

| Layer | When | What |
|-------|------|------|
| `csharp-diagnostics.instructions.md` | Any `.cs` file in context | Error checking method enforcement |
| `csharp-tests.instructions.md` | Any `*Tests.cs` file in context | Baseline test conventions |
| `checking-csharp-errors` skill | Complex diagnostic sessions | Step-by-step workflow and failure modes |
| `writing-csharp-tests` skill / `@UnitTestWriter` | Full test-writing sessions | Pattern research, type verification, full workflow |

## Reference Files

| File | Role |
|------|------|
| [`instructions/csharp-diagnostics.instructions.md`](../../instructions/csharp-diagnostics.instructions.md) | Auto-applied error checking rules for `.cs` files |
| [`instructions/csharp-tests.instructions.md`](../../instructions/csharp-tests.instructions.md) | Auto-applied test conventions for `*Tests.cs` files |
| [`skills/checking-csharp-errors/SKILL.md`](../../skills/checking-csharp-errors/SKILL.md) | Detailed diagnostic workflow and checklist |
| [`skills/writing-csharp-tests/SKILL.md`](../../skills/writing-csharp-tests/SKILL.md) | Full test-writing conventions and patterns |
