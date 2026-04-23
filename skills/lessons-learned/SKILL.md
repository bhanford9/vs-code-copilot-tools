---
name: lessons-learned
description: Defines how to use the two-tier LessonsLearned feedback loop in skills and agents. Use when completing any skill or agent workflow that has a LessonsLearned file — to know which file to read, which file to write, and when a lesson should move into the skill body instead.
---

# The LessonsLearned Feedback Loop

Each skill directory uses a **two-tier** lessons learned system:

| File | Tracked in git? | Purpose |
|---|---|---|
| `LessonsLearned.GLOBAL.md` | ✅ Yes | Globally applicable process notes — agent behavior observations, skill gaps, workflow decisions. Shared across all users and workspaces. |
| `LessonsLearned.md` | ❌ No (gitignored) | Per-user, per-workspace codebase knowledge — type locations, naming conventions, team patterns, non-mockable types. Grows independently for each user. |

**Never put workspace-specific or codebase-specific content in `LessonsLearned.GLOBAL.md`.** If you are not sure which file to write to, default to `LessonsLearned.md`.

## What the Lessons Files Are For

- **Prevent repetition of past mistakes** — stop future agents from re-figuring things out the hard way.
- **`LessonsLearned.md` is user-specific by design** — the same SKILL.md serves many users. Each user's local file captures their own codebase patterns. User A and User B build completely different local files from the same shared skill.
- **`LessonsLearned.GLOBAL.md` is shared tooling knowledge** — observations that apply regardless of which codebase or workspace is in use.
- **Neither file is a success journal** — do not document things that worked smoothly.

## The Workflow

### 1. Before Starting: Read Both Files

Read both files for the relevant skill before beginning the workflow:
1. Read `LessonsLearned.GLOBAL.md` — always exists alongside the SKILL.md.
2. Read `LessonsLearned.md` if it exists on disk — it may not exist for new users or new skills. If absent, proceed without it.

Apply any recorded patterns, false positives, or "watch out for" notes from both files to improve this session.

### 2. At Session Close: Always Prompt the User

When the skill workflow is complete, **always** output this prompt to the user as your closing message:

> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

Do not silently skip this. Do not make the prompt conditional on whether the session was routine. The user decides whether to proceed — your job is to make the option visible every time.

### 3. After Completing: Reflect Before Writing

When the user starts a lessons learned session, reflect before writing anything:

- Was anything hard, slow, or surprising in this session?
- Did something go wrong that a future agent should avoid?
- Did I have to figure out something not already in the SKILL.md?

If the answer to all of these is **no**, skip the update entirely. Routine sessions do not produce entries.

### 4. Choose the Right File

Before writing, classify the lesson using the category tag:

- **`Category: Codebase`** → write to `LessonsLearned.md` (gitignored, local)
  - Facts about the project: type locations, naming conventions, non-mockable types, team patterns, work item ID formats.
  - These are stable and almost never go stale.
- **`Category: Process/Model`** → write to `LessonsLearned.GLOBAL.md` (tracked in git)
  - Observations about agent behavior, workflow gaps, harness decisions, or tool limitations.
  - These may go stale when the model improves.

**When in doubt, use `Category: Codebase` and write to the local `LessonsLearned.md`.** If you believe a lesson is globally applicable but are not 90% confident, write it locally and flag it for the user to decide whether to promote.

**CRITICAL — GLOBAL file content test**: Before writing any sentence to a `LessonsLearned.GLOBAL.md` file, ask: "Could this sentence appear unchanged in a review of a completely different codebase?" If it contains a work item ID, class name, method name, test name, file name, or any other artifact from the current repo, the answer is no — it belongs in `LessonsLearned.md` instead. The pattern or heuristic itself may be global; the example that illustrates it is almost always codebase-specific. Strip examples entirely, or rephrase them in the abstract before writing to GLOBAL.

### 5. Check for Duplicates First

Before writing to either file, scan it for existing entries on the same topic:
- If a matching entry exists, **update it** (strengthen it, add the new example) rather than creating a duplicate.
- If the same topic has appeared as a new incident **three or more times**, it is an escalation candidate — flag it for promotion to SKILL.md or conversion to a hook rather than adding another entry.

### 6. What to Write

- A short descriptive heading (not a date)
- 2–5 lines of specific, actionable notes
- A category tag on the first line: `Category: Codebase` or `Category: Process/Model`
- Use DO's/DON'Ts when alternate viable approaches exist and it's important to clarify which one to take
- Focus on: what to watch out for, what to avoid, what was unexpectedly hard

### 7. What NOT to Write

- Things the agent does easily and correctly every time
- Step-by-step summaries of what you did — that belongs in SKILL.md
- Obvious facts that any capable agent would know without being told
- Long explanations — brevity is essential; if an entry grows beyond a short paragraph, it's probably done

## Escalation Path: From Guidance to Enforcement

A lesson in a markdown file is passive — the agent must read and remember it. When passive guidance keeps failing, escalate:

```
Observed once → LessonsLearned.md or LessonsLearned.GLOBAL.md entry  (inferential, read before each session)
Recurs after lesson exists → Promote to SKILL.md rule  (inferential, always present)
Still recurs after promotion → Escalate to a hook  (computational, always enforced)
```

Escalation indicators:
- The same mistake appears as a new LessonsLearned entry despite an existing one on the same topic
- A SKILL.md rule tagged `CRITICAL` keeps being violated
- The rule is binary (either violated or not) and its violation is detectable in output files

Not all rules are hookable. Binary, file-detectable violations (e.g., test file contains comments) are strong hook candidates. Contextual, semantic judgments must remain inferential.

## Promotion to SKILL.md

When a `Process/Model` lesson in `LessonsLearned.GLOBAL.md` reveals a defect or gap in the skill itself — something that would help *any* user, not just you:

1. **Promote it to the SKILL.md body** (the canonical source of truth)
2. Remove or condense the `LessonsLearned.GLOBAL.md` entry (e.g., note "Promoted to SKILL.md: [topic]")
3. Do not leave duplicates between LessonsLearned.GLOBAL.md and SKILL.md

`Codebase` entries in `LessonsLearned.md` are user-specific and are promoted to SKILL.md only in the rare case they represent a universal pattern (not a workspace-specific fact).

## Model-Upgrade Review

When upgrading to a new model version, scan all `Process/Model` entries in `LessonsLearned.GLOBAL.md` and evaluate whether each still applies. `Codebase` entries in `LessonsLearned.md` are stable and do not need this scan. Entries that no longer apply should be removed or archived.

## Format

No required template. Each entry should have:

- A short descriptive heading that describes the finding
- A category tag on the first line after the heading
- Brief free-form notes

**Example — local file (`LessonsLearned.md`):**

```
### Enum Namespace Resolution in This Codebase
Category: Codebase

MaterialType enums are in `MaterialModel.Enums`, not the domain layer.
Always check namespace before writing test usings for this project.
```

**Example — global file (`LessonsLearned.GLOBAL.md`):**

```
### Stop Hooks Cannot Reason About Session Content
Category: Process/Model

Stop hooks run after the session ends and cannot inspect what was generated during it.
Use workflow step instructions (in SKILL.md or agent instructions) for content-dependent checks instead.
```

## Feedback Loop

This skill follows its own pattern. See [LessonsLearned.GLOBAL.md](LessonsLearned.GLOBAL.md) for accumulated notes on how the feedback loop concept itself has evolved.
