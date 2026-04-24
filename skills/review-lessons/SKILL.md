---
name: review-lessons
description: Scan all LessonsLearned.GLOBAL.md files across all skills, evaluate each entry for escalation candidates using parallel subagents, and synthesize a prioritized action report. Use when running a periodic maintenance review of the LessonsLearned feedback loop.
---

# Review Lessons Workflow

A periodic maintenance workflow that reads every `LessonsLearned.GLOBAL.md` file in the skills directory, evaluates entries against the escalation criteria from the `lessons-learned` skill, and surfaces candidates that should be promoted to SKILL.md, converted to hooks, or removed as stale.

> **Note on the two-tier system**: Only `LessonsLearned.GLOBAL.md` files are scanned here — these contain `Process/Model` entries that are candidates for escalation. Local `LessonsLearned.md` files are gitignored, per-user codebase files and are not reviewed in this workflow (they are user-specific and do not escalate to shared tooling).

## Before Starting

Read `~/Repos/vs-code-copilot-tools/skills/review-lessons/LessonsLearned.GLOBAL.md` per the `lessons-learned` skill. Apply any recorded patterns to improve this session.

## Step 1: Load Escalation Criteria

Read `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md` in full. Extract and keep in working memory:

- The **Escalation Path** (LessonsLearned → SKILL.md → hook)
- **Escalation Indicators** (duplicate entries on same topic, `CRITICAL`-tagged rule violations, binary file-detectable rules)
- **User-Specific vs. Globally Applicable** distinction
- **Model-Upgrade Review** criteria for `Category: Process/Model` entries

## Step 2: Discover All LessonsLearned Files

Use a glob or recursive search to find **all** `LessonsLearned.GLOBAL.md` files under `~/Repos/vs-code-copilot-tools/skills/`. Do not rely on a hardcoded list — the set of skills grows and shrinks over time.

```powershell
Get-ChildItem -Path "~/Repos/vs-code-copilot-tools/skills" -Recurse -Filter "LessonsLearned.GLOBAL.md" | Select-Object -ExpandProperty FullName
```

Record the complete list before proceeding. If zero files are found, report that and stop.

## Step 3: Parallel Evaluation

Spawn a subagent for each discovered `LessonsLearned.GLOBAL.md` using the `runSubagent` tool. Spawn **all subagents simultaneously** — do not wait for one to finish before starting the next.

Each subagent receives the prompt below, with `{path}`, `{skill_name}`, and `{skill_folder}` substituted with actual values. `{skill_folder}` is the directory name under `skills/` (e.g., `creating-azure-stories`):

---

### Subagent Prompt Template

```
You are evaluating a single LessonsLearned.GLOBAL.md file for escalation candidates.

Read this file in full: {path}

Read the escalation criteria from: ~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md
Focus on these sections: "Escalation Path", "Escalation Indicators", "User-Specific vs. Globally Applicable", "Model-Upgrade Review".

For every entry in the file, evaluate it against the criteria and assign exactly one flag:
- Promote — should be moved to the corresponding SKILL.md because it applies to any user of this skill (not just this specific codebase or project)
- Hook — describes a binary, file-detectable violation that should be enforced computationally rather than left to passive guidance
- Stale — has Category: Process/Model and describes model behavior that may no longer apply
- OK — is user-specific codebase knowledge that belongs exactly where it is; no action needed

Return ONLY a markdown block in exactly this format. No preamble, no explanation outside the table.

## {skill_name} (`skills/{skill_folder}/LessonsLearned.GLOBAL.md`)

| Entry | Category | Flag | Reasoning |
|-------|----------|------|-----------|
| {entry heading} | Codebase / Process/Model | Promote / Hook / Stale / OK | One sentence: why this flag |

If the file is empty or a header-only stub with no entries, return only:
## {skill_name} — No entries
```

---

Collect all subagent return values before proceeding to Step 4.

## Step 4: Synthesize

Read every subagent output. Combine into a single consolidated report with two sections:

### Per-Skill Tables

Include each subagent's output table verbatim, one after another. Omit any "No entries" results.

### Recommended Actions

A single prioritized table of all non-OK entries across all skills. Order by priority:

1. **Hook** candidates — highest priority; passive guidance that should become binary enforcement
2. **Promote** candidates — move to SKILL.md, condense or remove from LessonsLearned
3. **Stale** candidates — requires user confirmation before removal

Format:

| Priority | Skill | Entry | Action | Files Affected |
|----------|-------|-------|--------|----------------|
| Hook | {skill} | {entry heading} | Create a hook that enforces: {description} | `hooks/`, `hooks/scripts/` |
| Promote | {skill} | {entry heading} | Move to `{skill}/SKILL.md`; remove from LessonsLearned.GLOBAL.md | `SKILL.md`, `LessonsLearned.GLOBAL.md` |
| Stale | {skill} | {entry heading} | Confirm with user — remove if no longer applicable | `LessonsLearned.GLOBAL.md` |

If there are no non-OK entries across all files, report: "No escalation candidates found. All entries are appropriately placed."

## Step 5: Present and Wait

Present the full report to the user. Then ask:

> "Which of these would you like to act on? I can work through them one at a time, or you can pick specific items."

**Do not make any file changes until the user responds.**

## Step 6: Lessons Learned

Follow the `lessons-learned` skill to reflect on whether anything was hard or surprising in this session. Proceed directly into the reflection — do not ask for permission. Update `~/Repos/vs-code-copilot-tools/skills/review-lessons/LessonsLearned.GLOBAL.md` if warranted (process/model findings only — no codebase content).
