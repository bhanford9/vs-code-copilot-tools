---
name: review-lessons
description: Scan all LessonsLearned.md files across every skill, identify escalation candidates (entries that should be promoted to SKILL.md or converted to hooks), and surface a prioritized action list.
---

You are running the **Review Lessons** workflow. Your job is to read every `LessonsLearned.md` file in this repo, apply the escalation criteria from the `lessons-learned` skill, and produce a structured report of candidates requiring action.

## Step 1: Read the Escalation Criteria

Read `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md` in full before starting. Pay particular attention to:
- The **Escalation Path** section (once → LessonsLearned, recurs → promote to SKILL.md, still recurs → hook)
- The **Escalation Indicators** (duplicate entries on same topic, `CRITICAL`-tagged rules that persist, binary file-detectable violations)
- The **User-Specific vs. Globally Applicable** section (distinction between what stays in LessonsLearned vs. what promotes to SKILL.md)
- The **Model-Upgrade Review** section (Process/Model entries that may have gone stale)

## Step 2: Scan All LessonsLearned Files

Read every `LessonsLearned.md` file found under `~/Repos/copilot-configs/skills/`:

```
skills/agentic-tools-auditor/LessonsLearned.md
skills/checking-csharp-errors/LessonsLearned.md
skills/code-review-pipeline/LessonsLearned.md
skills/creating-azure-stories/LessonsLearned.md
skills/lessons-learned/LessonsLearned.md
skills/merge-copilot-settings/LessonsLearned.md
skills/planning-pipeline/LessonsLearned.md
skills/update-copilot-tools/LessonsLearned.md
skills/update-validated-joists-test-data/LessonsLearned.md
skills/writing-csharp-tests/LessonsLearned.md
```

For each file, read the full content before evaluating.

## Step 3: Evaluate Each Entry

For every entry in every file, apply these checks:

### Promotion Candidates (LessonsLearned → SKILL.md)
Flag if:
- The entry describes behavior that would apply to **any user** of this skill, not just this specific codebase
- The entry's heading appears in **more than one** LessonsLearned file (same problem discovered independently)
- The corresponding SKILL.md has no coverage of this topic despite it being a reliable pattern

### Hook Candidates (passive guidance → enforced hook)
Flag if:
- The entry describes a **binary, detectable** violation (either the output contains X or it doesn't)
- The violation could be caught by checking a file's contents after a tool call (PostToolUse) or before one (PreToolUse)
- The entry has `Category: Process/Model` and the problem is structural rather than knowledge-based (structural = always wrong to do; knowledge-based = depended on missing information)

### Staleness Candidates (may no longer apply)
Flag if:
- The entry has `Category: Process/Model`
- It describes a model behavior (e.g., "the model tends to…") that may have changed since the entry was written

### No Action
If the entry is user-specific codebase knowledge (`Category: Codebase`) and is not duplicated, it belongs exactly where it is. Do not flag it.

## Step 4: Produce the Report

Present findings as a structured table per skill, then a consolidated action list. Use this format:

```
## [Skill Name]

| Entry | Category | Flag | Reasoning |
|-------|----------|------|-----------|
| {heading} | Codebase/Process/Model | Promote / Hook / Stale / OK | one sentence |
```

After the per-skill tables, produce:

### Recommended Actions

Ordered by priority:

1. **Hook candidates** — highest priority; passive guidance that should be binary enforcement
2. **Promotion candidates** — move to SKILL.md, remove from LessonsLearned
3. **Staleness candidates** — review with user before removing

For each action item, state:
- What to change
- Which file(s) are affected
- Whether user confirmation is needed before proceeding

## Step 5: Ask Before Acting

**Do not make any file changes during this step.** Present the report to the user and ask:

> "Which of these would you like to act on? I can work through them one at a time, or you can pick specific items."

Wait for the user's response before touching any files.
