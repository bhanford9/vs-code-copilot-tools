---
name: audit-skill-lessons
description: Run a formal health audit on the LessonsLearned.GLOBAL.md file for a single named skill. Checks for bloat, duplication, sanitization violations, stale entries, escalation candidates, and actionability. Produces a structured findings report with concrete recommended actions.
mode: agent
---

# Audit: LessonsLearned.GLOBAL.md Health Audit for a Single Skill

This prompt runs a formal health audit on the `LessonsLearned.GLOBAL.md` file for one skill. It is more thorough than the batch `review-lessons` escalation scan — it evaluates bloat, duplication, sanitization, actionability, and overall file health in addition to escalation candidates.

---

## Before Starting

If the user has not named a skill, ask:

> "Which skill's `LessonsLearned.GLOBAL.md` should I audit? Provide the skill folder name (e.g., `code-review-pipeline`, `creating-azure-stories`)."

Once the skill is identified, locate its directory under the `skills/` folder in this workspace.

---

## Step 1 — Load Reference Material

Read all three files **in full** before writing any findings. Do not begin evaluation until all three are loaded.

1. **The target skill's `SKILL.md`** — understand what the skill already covers. Escalation candidates must fill a real gap in this document, not duplicate something already stated.
2. **The target skill's `LessonsLearned.GLOBAL.md`** — the file being audited.
3. **The `lessons-learned` skill's `SKILL.md`** — load the full escalation path, escalation indicators, sanitization gate, format rules, and the mandatory sanitization checklist. These are the authoritative criteria for all judgments made in this audit.

---

## Step 2 — Inventory All Entries

List every distinct entry in the file by heading. Record the total count. If the file has no entries, report that and stop.

---

## Step 3 — Evaluate Each Entry Against All Checks

For each entry, apply **every check** in the catalog below. A single entry may receive multiple flags. The goal is exhaustive evaluation — do not stop at the first flag.

### Check Catalog

| Flag | When to apply | Recommended action |
|------|---------------|--------------------|
| **ESCALATE** | The entry corrects a gap or omission in the SKILL.md itself — guidance that would help *any* user of this skill and is not already stated in the SKILL.md | Propose the exact text to insert into SKILL.md; mark the LL entry for removal (or condense to a one-line "Promoted to SKILL.md: [topic]" tombstone) |
| **HOOK** | The rule is binary (either violated or not), detectable in output files without semantic reasoning, and continues to recur despite being documented in LL | Describe what a computational hook would check; flag for future hook creation |
| **STALE** | `Category: Process/Model` entry describes model behavior, agent tendency, or tool limitation that may have been resolved by a model upgrade | Mark for model-upgrade review; if confidence is high that it no longer applies, recommend removal with rationale |
| **BLOAT** | Entry is significantly longer than needed — includes lengthy preamble, restates context the reader already has, contains code examples that add length without proportionate value, or could express the core warning in ≤50% of current words | Provide a rewritten, compressed version of the entry. Target: one strong heading + one tight paragraph |
| **DUPLICATE** | Two or more entries address the same failure mode, even if framed differently or written at different times | Identify all duplicate entries; propose a single merged entry that preserves the sharpest phrasing from each; mark the redundant entries for removal |
| **CONTAMINATED** | Entry contains codebase-specific identifiers: class names, method names, type names, file paths, namespace fragments, work item IDs, or any artifact tied to a specific project | Identify the offending identifiers; provide a fully sanitized rewrite that preserves the generalizable pattern while removing all project-specific references |
| **SUCCESS-JOURNAL** | Entry documents something that went smoothly, was straightforward, or is a general best practice — not a failure, surprise, or something that was hard, slow, or wrong | Recommend removal — success journaling is explicitly prohibited by the lessons-learned skill |
| **INACTIONABLE** | The guidance is too vague for a future agent to change its behavior — no clear "watch out for X" + "do Y instead" structure is present | Provide a sharpened rewrite, or recommend removal if the insight cannot be made concrete |
| **WRONG-SKILL** | The lesson is about a different skill's workflow, concerns a tool or system that another skill owns, or clearly belongs in a different GLOBAL file | Identify the correct home skill |
| **OK** | None of the above apply — entry is correctly placed, appropriately sized, sanitized, and actionable | No action needed |

---

## Step 4 — Produce the Findings Report

### 4a. Per-Entry Table

```
| Entry Heading | Flags | Notes |
|---------------|-------|-------|
| {heading}     | {flags or OK} | {one-line justification} |
```

### 4b. Summary Statistics

- Total entries: N
- Clean (OK only): N  
- Entries with at least one flag: N
- Flag breakdown: ESCALATE: N | HOOK: N | STALE: N | BLOAT: N | DUPLICATE: N | CONTAMINATED: N | SUCCESS-JOURNAL: N | INACTIONABLE: N | WRONG-SKILL: N

### 4c. Overall File Health

Assign exactly one rating:

| Rating | Criteria |
|--------|----------|
| **Healthy** | Majority of entries are OK; no systemic problems; file is lean and actionable |
| **Moderate debt** | Several entries need work but the file is usable; no contamination |
| **High debt** | Pervasive issues (bloat, duplication, or contamination) requiring a focused cleanup pass |
| **Critical** | File actively causes harm: contaminated entries in a public repo, or so large/noisy that agents are unlikely to apply any of it correctly |

### 4d. Prioritized Action List

List every recommended action, ordered by severity (Critical issues first, then Quick wins, then Polish):

```
PRIORITY 1 — Critical (do these first)
  [CONTAMINATED] Strip identifiers from "{heading}" — proposed rewrite: ...
  [REMOVE] Delete "{heading}" — reason: success journal

PRIORITY 2 — Value adds (escalation and deduplication)
  [ESCALATE] Promote "{heading}" to SKILL.md — proposed insertion point and text: ...
  [HOOK] Convert "{heading}" to a hook — hook would check: ...
  [MERGE] Merge "{heading A}" + "{heading B}" — proposed merged text: ...

PRIORITY 3 — Polish (compression and clarity)
  [REWRITE] Compress "{heading}" — proposed rewrite: ...
  [STALE?] Review "{heading}" after model upgrade — verify: ...
  [MOVE] Relocate "{heading}" to {other-skill}/LessonsLearned.GLOBAL.md
```

### 4e. File-Level Structural Observations

Note any issues that apply to the whole file rather than a specific entry:

- **Header**: Is a proper header present identifying the skill and the file's purpose?
- **File size**: Files exceeding ~250 lines are accumulating noise. Is this file approaching or past that threshold?
- **Dating**: Are entries dated? Dates enable staleness triage; their absence makes it impossible to know which entries preceded a model upgrade.
- **Entry order**: Are entries ordered with newest first, or grouped by theme? Disordered files are harder to deduplicate.
- **Dead entries**: Are there placeholder or "seeded" entries from file initialization that have never been updated with real observations?

---

## Step 5 — Offer to Apply Actions

After delivering the report, ask:

> "Would you like me to apply any of these changes now? I can promote entries to SKILL.md, remove entries, merge duplicates, rewrite bloated entries, or sanitize contaminated text. Shall I apply all recommended actions, or would you like to review them individually first?"

Do **not** make any edits to either file until the user confirms. When applying changes, treat ESCALATE as an atomic operation: add the text to SKILL.md and remove (or condense) the LL entry in the same multi-replace call — never stage them separately.

---

## Lessons Learned

After completing the audit (and after any approved edits are applied), run the lessons-learned reflection per the `lessons-learned` skill. Classify findings:

- Observations about the **audit workflow itself** (e.g., which checks caught the most issues, which were hard to apply) → `LessonsLearned.GLOBAL.md` for this skill or the `lessons-learned` skill
- No codebase-specific content belongs in any GLOBAL file
