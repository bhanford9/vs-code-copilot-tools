---
name: lessons-learned
description: Defines how to use LessonsLearned.md feedback loops in skills and agents. Use when completing any skill or agent workflow that has a LessonsLearned.md file — to know when to read it, when and what to write, and when a lesson should move into the skill body instead.
---

# The LessonsLearned Feedback Loop

LessonsLearned.md files sit alongside a SKILL.md or in a shared location accessible to agents. They capture user-specific experience — mistakes, edge cases, and patterns that the core skill cannot anticipate — and accumulate over time to make the skill progressively more useful for each individual user.

## What LessonsLearned.md Is For

- **Prevent repetition of past mistakes** — the primary purpose is to stop future agents from spending time figuring out things you already figured out the hard way.
- **User-specific by design** — the same SKILL.md can serve many users. Each user's LessonsLearned.md captures their own codebase patterns, team conventions, and hard-won discoveries. User A and User B can build completely different LessonsLearned.md files from the same shared skill.
- **Not a success journal** — it is not for documenting things that worked or things the agent accomplished without struggle.

## The Workflow

### 1. Before Starting: Read LessonsLearned.md

Read the LessonsLearned.md file if it exists before beginning the workflow. Apply any recorded patterns, false positives, or "watch out for" notes to improve this session.

### 2. After Completing: Reflect Before Writing

Before appending anything, ask:

- Was anything hard, slow, or surprising in this session?
- Did something go wrong that a future agent should avoid?
- Did I have to figure out something not already in the SKILL.md?

If the answer to all of these is **no**, skip the update entirely. Routine sessions do not produce entries.

### 3. What to Write

- A short descriptive heading (not a date)
- 2–5 lines of specific, actionable notes
- Use DO's/DON'Ts section when alternate viable approaches exist and it's important to clarify which one to take
- Focus on: what to watch out for, what to avoid, what was unexpectedly hard

### 4. What NOT to Write

- Things the agent does easily and correctly every time
- Step-by-step summaries of what you did — that belongs in SKILL.md
- Obvious facts that any capable agent would know without being told
- Long explanations — brevity is essential; if an entry grows beyond a short paragraph, it's probably done

## User-Specific vs. Globally Applicable Lessons

Most lessons are user-specific: "In this codebase, X works differently because of Y." Those stay in LessonsLearned.md.

Some lessons reveal a defect or gap in the skill itself — something that would help *any* user, not just you. When you identify one of these:

1. **Promote it to the SKILL.md body** (the canonical source of truth)
2. Remove or condense the LessonsLearned.md entry (e.g., note "Promoted to SKILL.md: [topic]")
3. Do not leave duplicates between LessonsLearned.md and SKILL.md

**How to tell the difference:**

| User-specific | Globally applicable |
|---|---|
| "In this codebase, enum X is in namespace Y" | "Stop hooks cannot reason about session content — use workflow instructions instead" |
| "This team names tests with [pattern]" | "The `handoffs.agent` target must not have `user-invocable: false`" |
| "Azure DevOps story ID format is '#NNNNNN'" | "Missing `agents:` frontmatter causes silent subagent invocation failures" |

**If you're not at least 90% confident that a lesson is globally applicable, stop and ask the user to provide guidance on whether it should be promoted to SKILL.md or remain in LessonsLearned.md.**

## Format

No required template. Each entry should have:

- A short descriptive heading that describes the finding
- Brief free-form notes

**Example:**

```
### Enum Namespace Resolution in This Codebase

MaterialType enums are in `MaterialModel.Enums`, not the domain layer.
Always check namespace before writing test usings for this project.
```

## Feedback Loop

This skill follows its own pattern. See [LessonsLearned.md](LessonsLearned.md) for accumulated notes on how the feedback loop concept itself has evolved.
