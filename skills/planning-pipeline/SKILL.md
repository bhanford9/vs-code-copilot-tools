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

All pipeline agents share a single LessonsLearned file:

`~/Repos/copilot-configs/skills/planning-pipeline/LessonsLearned.md`

Entries from any phase (planning, gap resolution, implementation) are captured here. Each agent reads this file at Step 0 and updates it at the end of the session when something notable occurred.

Follow `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md` for the entry format and escalation path.
