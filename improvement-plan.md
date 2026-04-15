# Implementation Plan: Feedback & Feedforward Improvements

Based on the ideation in `improvement-ideation.md`, this plan works through each feature independently to identify the changes needed for a consistent, high-quality feedback and feedforward implementation across the entire repo.

---

## What's Changing and Why

Three changes to the governing `lessons-learned` skill form the foundation — everything else builds on top. The per-feature changes are about applying those new rules consistently and filling gaps that exist today.

### Foundation: `skills/lessons-learned/SKILL.md`

All three additions go into the governing document before anything else changes, so every feature inherits the new rules automatically.

**Change 1 — Category tagging at write time**

Add a "Category" field to the What to Write section. Two categories:

- **`Codebase`** — facts about the project: type locations, naming conventions, non-mockable types, team patterns. Almost never go stale.
- **`Process/Model`** — observations about agent behavior or workflow gaps. May go stale when the model improves.

Include a note: when upgrading to a new model version, scan only `Process/Model` entries to evaluate if they're still valid. `Codebase` entries don't need that scan.

**Change 2 — Cluster detection before writing**

Add a step before writing: scan the existing LessonsLearned.md for entries in the same category or on the same topic. If a matching entry exists:
- Update it (strengthen it, add the new example) rather than writing a duplicate
- If this is the *third* time this topic has appeared as a new incident, flag it as a promotion or escalation candidate rather than updating again

This is the primary bloat prevention mechanism. The escalation trigger is mechanical: if the same thing keeps being observed, it belongs in SKILL.md or a hook, not more text in LessonsLearned.

**Change 3 — Escalation path definition**

Add an explicit section defining the path from passive guidance to enforcement:

```
Observed once → LessonsLearned.md entry (inferential, human-verified once)
Recurs after lesson exists → Promote to SKILL.md rule (inferential, always-on)
Still recurs after promotion → Escalate to a hook (computational, enforced)
```

Include a table of examples: which kinds of rules are hookable (binary, detectable in output files) vs. which must stay inferential (semantic, contextual).

---

## Per-Feature Review

### Planning Pipeline — MAJOR GAP

**Current state:** The six active planning pipeline agents (01-06, 08) have zero LessonsLearned integration. No `skills/planning-pipeline/` exists. This is the largest gap in the repo.

**Why it matters:** The planning pipeline is the most complex multi-agent workflow. It's exactly the kind of workflow that accumulates insights over time: which path works for which type of feature, where GapFinder stalls, what InitialPlanner consistently overlooks in certain domains.

**Changes needed:**

1. Create `skills/planning-pipeline/LessonsLearned.md` — a shared file for all planning pipeline agents, covering pipeline-level observations (path selection, inter-agent handoff patterns, domain-specific behaviors)

2. Add LessonsLearned read step to `01-InitialPlanner.agent.md` (the entry point; benefits most from accumulated pipeline knowledge before starting)

3. Add LessonsLearned update step to all six agents as a final phase: `01-InitialPlanner`, `02-GapFinder`, `03-GapResolver`, `04-RefinedPlanner`, `05-ArchitecturalDesigner`, `06-WorkPlanner`, `08-Implementation`

**Note on skill file:** The planning pipeline doesn't need a full `skills/planning-pipeline/SKILL.md` — the agents already define their own workflows and the feature overview covers the pipeline at a high level. The LessonsLearned.md is sufficient for now.

---

### Code Review Pipeline — MINOR GAPS

**Current state:** All 10 REVIEW agents have LessonsLearned read and update steps pointing to `skills/code-review-pipeline/LessonsLearned.md`. This is the best-implemented feature for feedback loops.

**After foundation changes apply:** The category tagging and cluster detection rules will be inherited automatically. No structural changes needed.

**Minor gap:** The `update step` language across the 10 agents is inconsistent — some say "follow the feedback loop process" and some have more specific phrasing. After the foundation changes to lessons-learned SKILL.md, verify all 10 agents' update steps reference the same skill file and use consistent phrasing.

**No escalation path examples currently in REVIEW agents.** Once `check-auditor-output` hook is live for checking audit output files, this is a good documented example of the escalation path in action — the SKILL.md for code-review-pipeline could note it.

---

### Unit Test Writer — MINOR GAPS

**Current state:** Phase 5 of UnitTestWriter explicitly reads the lessons-learned SKILL.md and updates `skills/writing-csharp-tests/LessonsLearned.md`. Well-integrated.

**After foundation changes apply:** Category tagging is especially valuable here — virtually all writing-csharp-tests lessons are `Codebase` type (enum namespaces, non-mockable types). Marking them as such distinguishes them from `Process/Model` entries and makes them immune to model-upgrade scanning.

**No structural changes needed.** Phase 5 language is solid.

**Opportunistic improvement:** The escalation path (Idea 2 from ideation) maps naturally to this skill. If an enum namespace lesson appears repeatedly, it's a signal that type lookup should be made more mechanical — a codegen helper or pre-verified type reference. Not a change to make now, but worth noting in the skill's SKILL.md.

---

### Azure DevOps Story Creation — MINOR GAPS

**Current state:** Phase 5 follows the lessons-learned SKILL.md and writes to `skills/creating-azure-stories/LessonsLearned.md`. Well-integrated.

**After foundation changes apply:** Story creation lessons are mixed — format-specific rules are `Process/Model` (they depend on what the model knows about format), while team/project conventions are `Codebase`. Category tagging will make these visible.

**No structural changes needed.**

---

### Copilot Tools Management — MINOR GAPS

**Current state:** Both `update-copilot-tools` and `merge-copilot-settings` skills have LessonsLearned feedback loops. Well-integrated.

**After foundation changes apply:** Most lessons here will be `Process/Model` (sync failure patterns, path validation quirks, merge edge cases). These should be reviewed when upgrading models or when VS Code's behavior changes. Category tagging makes this visible.

**No structural changes needed.**

---

### Agentic Tools Auditor — ENHANCEMENT

**Current state:** SKILL.md Dimension 4 already checks whether a LessonsLearned.md exists for each skill and whether it should. This is the right place but it's shallow — it doesn't audit the health of existing LessonsLearned files.

**Changes needed:**

Expand Dimension 4 in `skills/agentic-tools-auditor/SKILL.md` to include health checks:

- **Escalation candidates:** Does the same topic appear in 3+ entries? Flag for promotion to SKILL.md or hook.
- **Category distribution:** If > 60% of entries are `Process/Model` category, note that many entries may need model-upgrade review.
- **Cross-skill duplicates:** Does a pattern appear in multiple skills' LessonsLearned files? It may belong in a shared instructions file instead.
- **Missing categories:** Are entries missing category tags? (Applies after foundation changes are shipped.)

No changes needed to the orchestrator agent — this is purely a SKILL.md dimension expansion that the individual-auditor sub-agents will apply.

---

## New Artifact: Session-Fork Capture Prompt

**Gap:** The high-value moment of mid-session course correction (when the agent goes off path and the user realizes the workflow needs a fix) has no formal mechanism. Currently this happens ad-hoc or gets lost.

**Change:** Create `prompts/fork-and-improve.prompt.md` as a `/fork-and-improve` slash command.

What it does:
1. Captures the description of what went wrong
2. Identifies which config file owns the fix (by asking the user, or searching)
3. Applies the fix to the correct file
4. Writes a LessonsLearned entry with the failure context — while the full context is still present in the session
5. Confirms the fix and prompts the user to return to the original task with updated configs

This is most effective when invoked during a session (not retrospectively) because the agent still has the full failure context in view.

---

## Execution Order

The foundation must ship first — the per-feature cleanups inherit from it.

| Phase | Work | Scope |
|-------|------|-------|
| **1** | Update `skills/lessons-learned/SKILL.md` with category tagging, cluster detection, escalation path | 1 file |
| **2** | Create `skills/planning-pipeline/LessonsLearned.md` stub | 1 new file |
| **3** | Add LessonsLearned read/update steps to all 7 planning pipeline agents | 7 files |
| **4** | Verify consistency of REVIEW agent update step phrasing (10 agents) | 10 files |
| **5** | Expand Dimension 4 in `skills/agentic-tools-auditor/SKILL.md` | 1 file |
| **6** | Create `prompts/fork-and-improve.prompt.md` | 1 new file |
| **7** | Add fork-and-improve to FEATURES.md | 1 file |

Phases 3, 4, 5 can run in parallel after phases 1 and 2 complete.
