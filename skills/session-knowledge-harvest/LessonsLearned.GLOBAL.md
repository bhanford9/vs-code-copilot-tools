# LessonsLearned.GLOBAL.md — session-knowledge-harvest

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## Seeded Knowledge

### The Scope Gate Is the Hardest Step to Apply Consistently

Category: Process/Model

The most common failure mode of this skill will be documenting too much — adding HOW content, implementation details, or things obvious from the code. The scope gate question ("Would a coding agent benefit from this AND be unlikely to find it from the code?") must be applied item by item, not as a general sentiment.

When in doubt, err toward discarding. A knowledge base that grows with low-value entries degrades faster than one that stays lean.

### The ⚠️ Coding Agent Trap Callout Is the Highest-Value Output

Category: Process/Model

The most useful thing this skill can produce is a specific, actionable warning callout in the right place. Generic warnings ("be careful with equality") have low value. Specific warnings ("do not use hash-code comparison as the final Equals answer; always follow with field comparison — see sibling classes LoadCategoryKey and ControllingLoadCombinationKey for the correct pattern") are what prevent future agent mistakes.

Evaluate each ⚠️ callout: could an agent read it and immediately know what NOT to do and what to do instead? If not, make it more specific.

---

## Determinism Pattern for Harvest Reinforcement (2026-04-22)

### Viable Pattern: Instructions File + Prompt File

Category: Process/Model

The reliable way to make harvest happen more consistently across sessions is two layers:

1. **Always-on instructions** — add the harvest rule to `general-agent-behavior.instructions.md` (`applyTo: "**"`). This file is in-context on every turn, giving the agent persistent awareness of the expectation throughout the session, not just at the end.
2. **Prompt file** — `prompts/harvest.prompt.md` gives the user a zero-friction one-click trigger when they want to run the skill explicitly.

### VS Code Stop Hook Was Tried and Rejected

A `Stop` lifecycle hook was implemented to post a `systemMessage` reminder at session end. It was removed because:
- `Stop` fires unconditionally on every session end — trivial sessions included
- The `Stop` input carries only `stop_hook_active`; no transcript, tool-use count, or file-edit count is available to filter on
- The result was noisy and may have interfered with normal session termination

Do not re-recommend a hook-based approach unless VS Code ships a `Stop` input field that includes session activity metadata.
