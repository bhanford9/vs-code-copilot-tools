# Unit Test Writer

An agent workflow that prevents a common AI failure mode: jumping straight to writing tests before understanding the code, the existing patterns, or the types involved. This workflow enforces a staged process that eliminates unknowns before any code is written.

## The Problem It Solves

AI-generated tests often look plausible but fail to compile or test the wrong thing — because the model assumed rather than verified. This workflow inverts that pattern: **spend most of the session understanding, then write with confidence**.

## How It Works

The flow moves through four stages of increasing confidence before writing begins:

```
Understand the code → Find existing patterns → Plan and clarify → Write
```

1. **Understand** — Read the target code deeply, map all dependencies, and identify everything that will need to appear in a test.

2. **Find patterns** — Search the existing test suite in the same area. Every decision about naming, mocking style, and structure is grounded in what already exists — not model assumptions.

3. **Plan and clarify** — Produce a written test plan (names and descriptions, no code) and surface ambiguities. The agent asks questions rather than guesses. A confidence gate blocks implementation until there's ≥ 90% certainty.

4. **Write** — Re-read the skill's reference files immediately before implementing. Verify every type explicitly before use.

The `LessonsLearned.md` file accumulates project-specific discoveries across sessions so the same research doesn't repeat.

## Two Layers of Convention Enforcement

**`csharp-tests.instructions.md`** (always-on) handles basic conventions across every `*Tests.cs` file automatically — naming pattern, no comments, `TestCase` usage. No agent invocation needed.

**`@UnitTestWriter` + `writing-csharp-tests` skill** enforce the full workflow on top: the staged process, confidence gates, type verification, and the feedback loop. Use the agent for any test-writing session where correctness matters.

## Reference Files

| File | Role |
|------|------|
| [`skills/writing-csharp-tests/SKILL.md`](../../skills/writing-csharp-tests/SKILL.md) | Conventions, mocking patterns, checklist |
| [`skills/writing-csharp-tests/COMMON-PITFALLS.md`](../../skills/writing-csharp-tests/COMMON-PITFALLS.md) | Type verification requirements and known failure patterns |
| [`skills/writing-csharp-tests/PROJECT-HELPERS.md`](../../skills/writing-csharp-tests/PROJECT-HELPERS.md) | Project-specific non-mockable types and support helpers |
| [`skills/writing-csharp-tests/LessonsLearned.md`](../../skills/writing-csharp-tests/LessonsLearned.md) | Accumulated discoveries from past sessions |
| [`agents/UnitTestWriter.agent.md`](../../agents/UnitTestWriter.agent.md) | Full agent definition and phase-by-phase workflow |
