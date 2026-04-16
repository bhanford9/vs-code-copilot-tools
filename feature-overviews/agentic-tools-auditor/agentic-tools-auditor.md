# Agentic Tools Auditor

A multi-agent workflow that audits every VS Code Copilot configuration file in a workspace — skills, agents, instructions, prompts, hooks — and produces a synthesis report covering what's wrong, what's redundant, what conflicts, and what architectural improvements are available.

## The Problem It Solves

As a workspace accumulates agentic configurations, quality drifts: frontmatter becomes stale, tool type choices become suboptimal, hooks and skills go missing their LessonsLearned loops, and related items start contradicting each other. No single file review catches cross-cutting problems. This workflow treats the entire configuration as a system and audits it that way.

## How It Works

The orchestrator runs a six-phase pipeline:

```
Fetch docs → Discover all configs → Plan batches → Audit in parallel → Synthesize → Update LessonsLearned
```

1. **Fetch current documentation** — Pulls the live VS Code Copilot customization docs before touching anything. This ensures audit judgments are grounded in the current platform, not stale training data.

2. **Discover all configurations** — Scans the workspace for every config file: skills, agents, instructions, prompts, hooks, existing audits. Produces an inventory snapshot (`AUDIT-BEFORE-STATE.md`) before changes are made.

3. **Plan batches** — Items with a recent existing `AUDIT.md` are skipped. The rest are grouped into batches of up to 8. Each item gets an `AUDIT-TASK-{name}.md` file that contains the full context the individual auditor will need — no truncated prompts.

4. **Parallel individual audits** — The `individual-auditor` sub-agent runs simultaneously for every item in a batch. Each auditor evaluates its item against the skill's audit dimensions and writes an `AUDIT.md` alongside the file.

5. **Synthesize** — The orchestrator reads all `AUDIT.md` outputs and produces `AUDIT-SYNTHESIS.md`: an executive summary, cross-cutting themes, conflicts between items, shared abstractions worth extracting, architectural improvement proposals, and a phased implementation roadmap. Redundant recommendations are collapsed before sequencing.

6. **LessonsLearned** — Any notable process/model findings are appended to `LessonsLearned.GLOBAL.md`. Codebase-specific findings go to the local `LessonsLearned.md` (gitignored).

## Why Parallel Sub-Agents and a Synthesis Phase

Individual item audits are independent — each one only needs its own file plus the shared documentation context. Running them in parallel cuts total audit time significantly for large workspaces. The task-file pattern (writing `AUDIT-TASK-{name}.md` instead of embedding full context in invocation prompts) keeps each sub-agent invocation short and avoids truncation.

The separation also enables a stronger synthesis phase. Because each sub-agent focuses narrowly on one item, the orchestrator's synthesis phase can read all findings together with fresh eyes — looking across the entire workspace rather than inside any single file. This is where the highest-value insights emerge: the same rule stated differently in three agents, a convention that should be extracted into a shared instruction file, an architectural pattern that would eliminate a class of failure across all skills. A single-agent sequential review buries these connections in a long chain of context; the parallel-then-synthesize structure surfaces them explicitly.

## Output Files

| File | What It Contains |
|------|-----------------|
| `AUDIT-CONTEXT.md` | Documentation summary fetched in Phase 1 |
| `AUDIT-BEFORE-STATE.md` | Inventory snapshot of all discovered config items |
| `AUDIT-TASK-{name}.md` | Per-item task context for each individual auditor |
| `{item}/AUDIT.md` | Per-item audit findings written by individual auditors |
| `AUDIT-SYNTHESIS.md` | Final cross-workspace synthesis and prioritized roadmap |

## Reference Files

| File | Role |
|------|------|
| [`skills/agentic-tools-auditor/SKILL.md`](../../skills/agentic-tools-auditor/SKILL.md) | Audit framework, dimension definitions, tool type reference table, output formats |
| [`skills/agentic-tools-auditor/LessonsLearned.GLOBAL.md`](../../skills/agentic-tools-auditor/LessonsLearned.GLOBAL.md) | Accumulated watch-outs from past audit sessions (process/model, tracked in git) |
| [`agents/agentic-tools-auditor.agent.md`](../../agents/agentic-tools-auditor.agent.md) | Orchestrator agent — full six-phase workflow |
| [`agents/individual-auditor.agent.md`](../../agents/individual-auditor.agent.md) | Sub-agent — per-item audit execution |
