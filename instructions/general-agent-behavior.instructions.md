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

## Using the Knowledge Base — NON-NEGOTIABLE RULE

The workspace knowledge base (managed by the `create-knowledge-docs` and `read-knowledge-docs` skills) is a first-class resource. It must be actively used throughout every session, not only at the end.

### When You Are Stuck

If you are blocked on a task, cannot determine the right approach, or are uncertain about system behavior — **consult the knowledge base before asking the user or guessing.** Use the `KnowledgeDocsResearcher` sub-agent to query it efficiently. The answer may already be documented.

### When You Cannot Find Something in the Codebase

If a search returns no results, or the code you expect to exist does not, treat this as a **documentation signal**:

- The concept, pattern, or behavior may be undocumented or poorly named
- **Flag this immediately** and, before moving on, ask the user targeted questions to fill the gap — e.g., "I couldn't locate where X is handled. Can you point me to it, or describe how it works? This will help me document it correctly."
- Track the gap for harvest at session end

> Absence of evidence in the codebase is a prompt to improve the knowledge base, not an excuse to stop or guess.

### When Traversing Complex or Ambiguous Code

When you encounter code that is hard to understand, non-obvious in intent, or likely to confuse future readers:

1. **Check the knowledge base** to see if this area is already explained
2. If it is not — or the documentation is incomplete — **mark it as a documentation candidate** and add it to your session tracking for harvest
3. Do not silently move past ambiguous code; name the confusion and record it

### Documentation Quality as a Team Multiplier

Every gap you surface and every question you ask about undocumented behavior is an investment in the shared knowledge base. Good documentation means:

- Future agents start better-informed
- Human developers onboard faster
- Recurring confusion is eliminated at its source

> Actively testing the goodness of the documentation — by using it and noting where it fails — is part of every task, not just the final harvest step.

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
