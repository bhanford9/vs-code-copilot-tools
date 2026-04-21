---
name: CSharp Test Conventions
description: Conventions for writing NUnit unit tests in C# codebases
applyTo: "**/*Tests.cs"
---

# C# Test Conventions

- Name test methods: `Should<Behavior>When<Condition>` or `Should<Behavior>`
- NEVER include comments in test code — code must be self-documenting through naming and structure
- Mock dependencies via Moq; use the Verifiable pattern for mocked calls with expectations: `.Setup(x => x.M()).Verifiable()` ... act ... `mock.Verify()`
- For simple parameter variations (true/false, enum permutations where setup and assertions are identical per case), use `[TestCase]` or `[Values]` instead of separate methods

> Before writing tests, load the `writing-csharp-tests` skill — it reads `LessonsLearned.GLOBAL.md` (cross-codebase patterns) and `LessonsLearned.md` (codebase-specific discoveries: enum disambiguation, non-mockable types, support helpers) from `~/Repos/copilot-configs/skills/writing-csharp-tests/`
