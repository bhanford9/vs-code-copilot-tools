# Hooks

Scripts that run automatically at specific points in an agent session — before or after tool calls, when a subagent stops, at session end. Hooks enforce binary rules deterministically without relying on the model to remember them.

## The Problem They Solve

Some rules can't be trusted to model instructions alone. The model might skip a check under pressure, forget a convention mid-session, or simply not notice a violation. Hooks move enforcement out of the model's reasoning loop and into the execution environment — the script runs regardless of what the model decided.

## Global vs. Agent-Scoped Hooks

**Global hooks** (`hooks/*.json`) fire for every agent session. They enforce workspace-wide behaviors that apply universally.

**Agent-scoped hooks** are defined inline in a specific agent's frontmatter. They only fire during sessions with that agent, which makes them appropriate for rules that are meaningful only in that agent's context.

## The Four Hooks

### `ensure-freeform` — Global, PreToolUse

Runs before every tool call in any session. Prevents the agent from locking into a rigid tool-use loop and preserves its ability to reason freely. Addresses a failure mode where agents over-commit to a mechanical sequence of tool calls and stop adapting to results.

### `test-no-comments` — Global, PostToolUse

Runs after every tool call. Checks that any test code written in the session doesn't contain comments. Enforces the test convention that test methods must be self-documenting through naming — if a test needs a comment to be understood, the name should be improved instead.

### `block-devops-fetch` — Agent-scoped, PreToolUse (`REVIEW-RequirementsAuditor`)

Prevents the Requirements Auditor from making external API or DevOps fetch calls during a review. The auditor's job is to analyze what's in the code, not pull live data from external systems mid-review. Keeps review context clean and reproducible.

### `check-auditor-output` — Agent-scoped, SubagentStop (`REVIEW-ParallelAuditCoordinator`)

Fires each time a parallel auditor sub-agent finishes. Verifies that the auditor produced its expected output file before the coordinator moves on. Catches silent failures — a sub-agent that exits without writing output — immediately rather than at final synthesis.

## Reference Files

| File | Role |
|------|------|
| [`hooks/ensure-freeform.json`](../../hooks/ensure-freeform.json) | Global PreToolUse hook definition |
| [`hooks/test-no-comments.json`](../../hooks/test-no-comments.json) | Global PostToolUse hook definition |
| [`hooks/scripts/ensure-freeform.ps1`](../../hooks/scripts/ensure-freeform.ps1) | Script invoked by ensure-freeform |
| [`hooks/scripts/check-test-comments.ps1`](../../hooks/scripts/check-test-comments.ps1) | Script invoked by test-no-comments |
| [`hooks/scripts/block-devops-fetch.ps1`](../../hooks/scripts/block-devops-fetch.ps1) | Script invoked by block-devops-fetch |
| [`hooks/scripts/check-auditor-output.ps1`](../../hooks/scripts/check-auditor-output.ps1) | Script invoked by check-auditor-output |
