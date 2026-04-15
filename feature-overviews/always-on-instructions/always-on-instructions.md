# Always-On Instructions

Instruction files that inject behavior into relevant chat sessions automatically — no invocation required. The agent receives the rules as part of its context whenever the file's `applyTo` scope matches.

## The Mechanism

VS Code Copilot instructions files use an `applyTo` glob in their frontmatter to determine when they activate. Files matching `**` apply to every session. Files matching a narrower glob apply only when files matching that pattern are in context.

This makes instructions files the right tool for rules that should be ambient — things the agent should always do or always know, not things the user has to remember to ask for.

## The Three Instruction Files

### General Agent Behavior (`applyTo: "**"`)

Applies to every chat session without exception. Contains a single rule: output an **Ambiguity Scan** table before acting on any non-trivial request.

The Ambiguity Scan requires the agent to enumerate every unclear assumption or unknown before proceeding. Each row is resolved as either ✅ (safe to assume and why) or ❓ (must ask before proceeding). If any ❓ rows exist, the agent stops and asks all questions before doing any work. This replaces an older confidence-threshold model that allowed the agent to silently assume rather than surface ambiguities explicitly.

### C# Diagnostics (`applyTo: "**/*.cs"`)

Applies whenever a `.cs` file is in context. Enforces the correct error-checking mechanism: the agent must use the **"Check Changed Files"** VS Code task rather than `dotnet build` or `get_errors`. This matters because those alternatives produce incomplete or misleading results compared to the language server task.

### C# Test Conventions (`applyTo: "**/*Tests.cs"`)

Applies whenever a `*Tests.cs` file is in context. Injects baseline NUnit test conventions: naming pattern (`Should<Behavior>When<Condition>`), no comments in test code, Moq Verifiable pattern for mocked expectations, and `[TestCase]` for simple variations.

These are the minimum rules that apply to every test edit. The `writing-csharp-tests` skill and `@UnitTestWriter` agent layer on top for full test-writing sessions requiring pattern research and type verification.

## Reference Files

| File | Role |
|------|------|
| [`instructions/general-agent-behavior.instructions.md`](../../instructions/general-agent-behavior.instructions.md) | Ambiguity Scan rule — applies to every session |
| [`instructions/csharp-diagnostics.instructions.md`](../../instructions/csharp-diagnostics.instructions.md) | Error checking enforcement — applies to `*.cs` files |
| [`instructions/csharp-tests.instructions.md`](../../instructions/csharp-tests.instructions.md) | Baseline test conventions — applies to `*Tests.cs` files |
