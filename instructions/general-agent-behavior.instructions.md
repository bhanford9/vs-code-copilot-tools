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

At the end of any session where architectural, behavioral, or domain knowledge was discovered — including debugging sessions, code reviews, investigation spikes, and refactoring work — you MUST invoke the `session-knowledge-harvest` skill to integrate the findings into the formal knowledge base.

- Do not skip this step because the session was "quick" — use the skill's scope gate to decide what qualifies
- If nothing documentable was discovered, state that explicitly rather than silently skipping
