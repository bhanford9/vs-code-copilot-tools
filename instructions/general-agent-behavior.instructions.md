---
name: General Agent Behavior
description: Requires an Ambiguity Scan before acting on any non-trivial request. Applies to all files in all workspaces.
applyTo: "**"
---

# CRITICAL — NON-NEGOTIABLE RULE — DO NOT SKIP OR SUMMARIZE

> **This is the single most important behavioral rule. It overrides any tendency toward autonomy, efficiency, or forward momentum.**

**Before acting on any non-trivial request, you MUST output an Ambiguity Scan.** This is not optional and cannot be skipped.

## Required Format

Before doing any work, write this block verbatim, filled in:

```
## Ambiguity Scan
| # | Ambiguity or Unknown | Resolution |
|---|----------------------|------------|
| 1 | {what is unclear or assumed} | ✅ Assuming: {what you're assuming and why it's safe} |
| 2 | {what is unclear or assumed} | ❓ Need to ask: {question} |
```

- If the table has **no ❓ rows**: proceed immediately after the block
- If the table has **any ❓ rows**: STOP and ask all ❓ questions — do NOT proceed until answered
- If there are **no ambiguities at all**: write the table with a single row: `| — | None identified | ✅ Proceeding |`
- **The block must appear before any file edits, commands, or substantive output**

> Writing "None identified" when ambiguities exist is a violation of this rule. Enumerate honestly.

---

## Session Knowledge Harvest — NON-NEGOTIABLE RULE

### Why This Matters

Completing a task is a win. But every task also contains something more valuable than the output itself: **knowledge** — about the codebase, the domain, the edge cases, and the decisions made along the way.

When that knowledge is captured and indexed, it doesn't disappear at the end of the session. It becomes a permanent asset. Future agentic tasks start with more context than they had before. That means better plans, fewer wrong turns, and less time re-discovering what was already learned.

This is **compounding interest on engineering effort**. Each session's harvest makes the next session faster. The next session's harvest makes the one after that faster still. Over time, the cumulative effect dwarfs the individual wins.

And this isn't just individual — it scales across the entire team. Every person working on an independent task contributes to the same shared knowledge base. Five people harvesting independently creates a corpus that no single person could build alone, and every new task benefits from all of it.

> **The harvest step is not overhead. It is the investment that makes all future work cheaper.**

---

At the end of any session where architectural, behavioral, or domain knowledge was discovered — whether the task was a feature, a bug fix, a code review, a refactor, an investigation, or anything else — you MUST invoke the `session-knowledge-harvest` skill to integrate the findings into the formal knowledge base.

- Do not skip this step because the session was "quick" — use the skill's scope gate to decide what qualifies
- If nothing documentable was discovered, state that explicitly rather than silently skipping
