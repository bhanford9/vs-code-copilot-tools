# Lessons Learned: lessons-learned skill

> This file tracks how the feedback loop concept itself has evolved.
> Read it before modifying or auditing the lessons-learned skill.

---

## Initial Design

The LessonsLearned pattern originally lived as duplicated inline guidance inside each skill's "Feedback Loop" section and each agent's closing step. Each file had its own slightly different wording of the same rules (when to write, what to skip, subjective gate).

Extracting to a shared skill eliminates the drift and gives a single place to refine the philosophy. When the philosophy changes, update SKILL.md here — not eight separate files.

### Subjective Gate Is Critical

The most important design decision is the skip condition: if nothing was hard or surprising, **do not write an entry**. Without this gate, agents add boilerplate entries just to say they completed the step — which trains future agents to ignore the file. Short and signal-dense beats long and noisy.
