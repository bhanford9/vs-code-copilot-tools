# Azure DevOps Story Creation

An agent workflow that produces properly structured Azure DevOps work items by researching the codebase first and collaborating with the user to fill gaps — rather than generating stories from the description alone.

## The Problem It Solves

Work items written without codebase context tend to be vague, miss dependencies, or describe implementation steps instead of outcomes. This workflow grounds every story in actual research: what the code looks like, what patterns exist, what the likely blockers are — before a single word of the story is written.

## How It Works

The flow moves through three stages before generating output:

```
Discover scope → Research the codebase → Clarify with user → Generate story
```

1. **Discover scope** — Establish which areas of the codebase are touched and what integration points are involved.

2. **Research** — Search for existing patterns, constraints, and related implementations. Subagents are used for broad discovery in complex codebases. Findings are grounded in specific file locations and code evidence.

3. **Clarify** — Present findings to the user and ask targeted questions to fill gaps. Blockers, business justification, dependencies, and success criteria are confirmed before proceeding. An 85% confidence gate blocks generation until ambiguities are resolved.

4. **Generate** — Read the full skill reference (format rules, template, examples, lessons learned) immediately before writing. The story structure is defined entirely by the skill — not model assumptions.

The `LessonsLearned.md` file accumulates project-specific patterns across sessions so research doesn't repeat.

## Story Structure

Every generated story follows a fixed structure enforced by the skill:

- **Title** — 5-10 word summary
- **Blocked By** — upstream dependencies or "None identified"
- **Backing Content** — context and justification for the work
- **Goal** — 1-2 sentence outcome-focused description
- **Details** — technical specifics: where and what the work is
- **Acceptance Criteria** — 3-7 testable business requirements

The skill enforces the distinction between outcome-focused language (Goal/Acceptance Criteria) and implementation details (Details only).

## Entry Points

| Invoke | When |
|--------|------|
| `@AzureStoryCreation` | Start a story from a description of work needed |
| `/CreateWorkItems` | Run after completing a planning pipeline work plan |

## Reference Files

| File | Role |
|------|------|
| [`skills/creating-azure-stories/SKILL.md`](../../skills/creating-azure-stories/SKILL.md) | Workflow checklist and required structure overview |
| [`skills/creating-azure-stories/FORMAT_RULES.md`](../../skills/creating-azure-stories/FORMAT_RULES.md) | Detailed formatting requirements per section |
| [`skills/creating-azure-stories/TEMPLATE.md`](../../skills/creating-azure-stories/TEMPLATE.md) | Canonical story template |
| [`skills/creating-azure-stories/EXAMPLES.md`](../../skills/creating-azure-stories/EXAMPLES.md) | Good and bad story examples |
| [`skills/creating-azure-stories/LessonsLearned.md`](../../skills/creating-azure-stories/LessonsLearned.md) | Accumulated patterns from past sessions |
| [`agents/AzureStoryCreation.agent.md`](../../agents/AzureStoryCreation.agent.md) | Full agent definition and phase-by-phase workflow |
