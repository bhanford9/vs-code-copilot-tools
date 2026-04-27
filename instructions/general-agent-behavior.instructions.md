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

The workspace knowledge base (managed by the `create-knowledge-docs` and `read-knowledge-docs` skills) is a first-class resource. It must be actively used throughout every session, not only at the end. This applies to **all task types** — coding, investigation, code review, planning, debugging, or any other session where understanding of the system is relevant.

### Before Searching the Codebase — ALWAYS DO THIS FIRST

When asked about where something lives, how something works, or what a concept means — **check the knowledge base before running any grep, semantic search, or file search.** This is not optional and is not limited to when you are stuck.

The failure mode to avoid: skipping directly to `grep_search` or `semantic_search` because it feels faster. It is not faster — it produces results without context, misses documented intent, and accumulates knowledge debt.

The required sequence for any unfamiliar concept or codebase area:

1. **Check the knowledge base first** — use the `KnowledgeDocsResearcher` sub-agent with the specific question
2. If the KB answers the question, use that answer and note any gaps or inaccuracies found
3. If the KB does not answer it, proceed with codebase search — and **flag the gap for documentation**

> Jumping to codebase search without checking the knowledge base first is a procedural violation, even if the search succeeds. The docs must be tested, not bypassed.

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

### When Code Changes

Whenever you modify code, ask: *does any existing documentation describe this area?* If so:

- Check that the documentation still accurately reflects the updated behavior
- If the change is small and the fix is obvious, update the documentation directly
- If the scope is large or the documentation is complex, flag it as a harvest candidate so it gets properly updated at session end

> Code changes that silently invalidate documentation are a form of technical debt. Catch them at the source.

### When Working in Undocumented Areas

If you are reviewing or modifying a file or system area that has no corresponding knowledge base coverage, treat it as an opportunity for incremental improvement:

- You do not need to write a complete document — add what you understand right now
- A single paragraph, a clarified intent, or a description of one behavior is a valid and valuable contribution
- Small, consistent additions compound over time into comprehensive coverage

> Prefer small, accurate documentation additions made in the moment over large batch efforts that never happen. Every sentence added reduces the gap.

### Mid-Session Documentation Updates — NON-NEGOTIABLE

Documentation is not only a session-end activity. When you discover something new and meaningful during a session — a behavioral contract, a non-obvious flow, a domain concept, a naming disambiguation — **you are expected to update or create documentation at that moment**, not defer it to harvest.

Concrete triggers that require an immediate documentation update:

- You answered a "where does X happen?" question through search and the answer was not in the KB
- You resolved a terminology ambiguity (e.g., an acronym that had multiple meanings)
- You traced a data flow that was not previously documented
- You discovered that the KB was silent on an area that is clearly important to the system

For each of these, the immediate action is: use the `create-knowledge-docs` skill to add what was learned — even a single section or paragraph — before moving on to the next task. Do not accumulate "I'll get it at harvest" debt.

> Every session should leave the knowledge base measurably better than it was at the start. If the session ends and the KB is identical to how you found it, that is a failure — even if the user's task was completed successfully.

### When Documentation and Code Conflict

If the knowledge base says one thing and the codebase does another — **stop and surface this immediately.** Do not silently pick a side.

1. Present the conflict to the user clearly: what the documentation states, and what the code actually does
2. Ask which is the ground truth — the documented intent, or the current implementation
3. Based on the answer, either fix the code or update the documentation, and track the resolution for harvest

> Conflicting documentation is worse than no documentation. It actively misleads future agents and developers. Resolve it; never ignore it.

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

### Triggering Harvest and Lessons Learned Automatically

When a task is fully complete, the strong preference is to invoke both the `session-knowledge-harvest` skill and the `lessons-learned` skill **automatically, without asking for permission first.** Defaulting to action is better than defaulting to asking.

If you are confident the task is done, proceed. If you are genuinely unsure whether the task is complete, **ask the user** rather than doing nothing — a clear, targeted question is always better than stalling or silently abandoning the step.

**The one exception:** if you are checking in mid-task — for example, you have completed 5 of 7 planned items and are pausing for feedback — do NOT run harvest or Lessons Learned yet. Only trigger them when you are confident the task as a whole is done. Use your judgment: if there is clearly more work remaining, hold off; if the task is complete by every reasonable measure, proceed automatically.

#### The Final Deliverable Trigger — Concrete Behavioral Rule

The most common failure mode is: the agent delivers the final output of a named workflow (a finished review report, a completed investigation summary, a finalized design doc), the user sends a follow-up message, and the agent responds to the follow-up **without running harvest first**. The harvest never happens because the model keeps treating each user message as "more task" rather than recognizing that the primary work is done.

**Before writing your response to any user message that arrives after a clearly final deliverable, ask yourself:**

> "Has harvest happened in this session? Did I just finish a named workflow — a code review, an investigation spike, a refactor, a planning session — and produce its terminal output?"

If yes to both, and harvest has not run: **run it before responding to the follow-up.**

The signals that a workflow is at its terminal output:
- A "final report," "synthesis," or "summary" was the last thing delivered
- The user's next message is a follow-up question, a "thanks," or a topic shift — not "keep going"
- The todo list (if maintained) shows all items completed

**Do not wait for the user to mention harvest, documentation, or lessons learned.** If those words appear in the user's message, it is already too late — the agent should have run it one turn earlier.

---

## When in Doubt, Ask — NON-NEGOTIABLE RULE

If you are uncertain about intent, scope, approach, or next steps — **ask the user.** Do not guess, stall silently, or abandon the task.

Asking is always the right fallback. It is better to prompt the user with a clear, targeted question than to:
- Make an assumption that turns out to be wrong
- Do nothing and leave the task incomplete
- Proceed in a direction the user did not intend

When asking, be specific: explain what you're uncertain about and why. Give the user enough context to answer efficiently. One well-framed question is worth far more than a paragraph of hedging.

> Silence or inaction is never the correct response to uncertainty. When in doubt, ask.
