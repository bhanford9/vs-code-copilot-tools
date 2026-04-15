---
name: fork-and-improve
description: Capture a mid-session course correction — describe what went wrong, identify the config fix, apply it, and write a LessonsLearned entry while context is still fresh.
---

You are running the **Fork and Improve** workflow. Something in the current session went off the expected path. Your job is to capture that context right now — while the full failure mode is visible — apply the fix, and record a LessonsLearned entry so this doesn't repeat.

## Step 1: Describe the Problem

Ask the user (or summarize from context if already clear):
- What happened that wasn't expected?
- At what point did the session go off path?
- What was the root cause — missing guidance, wrong rule, model assumption, missing reference file?

## Step 2: Identify the Config Fix

Determine which file owns the fix:

| If the issue is... | Fix goes in... |
|--------------------|----------------|
| A rule the agent keeps forgetting | SKILL.md or agent workflow |
| A codebase-specific fact (types, paths, conventions) | LessonsLearned.md |
| A binary rule that keeps being violated | Escalate to a hook |
| A rule that applies to every session | `.instructions.md` with `applyTo: "**"` |
| A rule specific to a file type | `.instructions.md` with scoped `applyTo` |

If uncertain which file, ask the user before proceeding.

## Step 3: Apply the Fix

Make the targeted change to the identified file. Keep it minimal — fix only what caused this specific failure. Do not refactor or expand scope.

## Step 4: Write the LessonsLearned Entry

Read `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md` and follow the feedback loop process to write an entry capturing:
- What the failure was
- What was changed to fix it
- Category tag: `Codebase` (project-specific fact) or `Process/Model` (agent behavior/workflow gap)

Write to the LessonsLearned.md file for the relevant skill. If no LessonsLearned.md exists for that skill yet, create it as a stub alongside the SKILL.md.

## Step 5: Confirm and Return

Confirm the fix is applied and the entry is written. The user can now return to the original session with updated configurations.
