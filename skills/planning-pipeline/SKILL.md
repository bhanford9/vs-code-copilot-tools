---
name: planning-pipeline
description: The discovery pipeline for feature planning. Agents 01–06 and 08 guide features from initial understanding through gap resolution, architecture, work planning, and implementation. Use when planning a new feature, resolving unknowns, designing architecture, or executing implementation.
---

# Planning Pipeline

The planning pipeline is a multi-phase discovery workflow that transforms a feature request into implemented code. Each agent covers one stage of the journey.

## Agents

| Agent | Phase | Purpose |
|-------|-------|---------|
| `01-InitialPlanner` | 1 | Outline an initial plan from the feature request |
| `02-GapFinder` | 2 | Identify knowledge gaps in the current plan |
| `03-GapResolver` | 3 | Resolve gaps through codebase research |
| `04-RefinedPlanner` | 4 | Produce a refined plan using resolved gap information |
| `05-ArchitecturalDesigner` | 5 | Design the architecture for the feature |
| `06-WorkPlanner` | 6 | Break work into phases, dependencies, and tasks |
| `08-Implementation` | 8 | Execute the plan — write code, run tests, commit |

## LessonsLearned

All pipeline agents share a single pair of LessonsLearned files:

- `~/Repos/vs-code-copilot-tools/skills/planning-pipeline/LessonsLearned.GLOBAL.md` — process/model observations, tracked in git
- `~/Repos/vs-code-copilot-tools/skills/planning-pipeline/LessonsLearned.md` — codebase-specific discoveries, gitignored (may not exist in a fresh clone)

Each agent reads both files at Step 0 (skip local file if absent). When each agent's workflow is complete, it **tells the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, follow `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md` for the entry format, file routing, and escalation path.
