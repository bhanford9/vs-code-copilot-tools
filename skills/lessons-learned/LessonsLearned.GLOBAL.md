# Lessons Learned: lessons-learned skill

> This file tracks how the feedback loop concept itself has evolved.
> Read it before modifying or auditing the lessons-learned skill.

---

## Initial Design

The LessonsLearned pattern originally lived as duplicated inline guidance inside each skill's "Feedback Loop" section and each agent's closing step. Each file had its own slightly different wording of the same rules (when to write, what to skip, subjective gate).

Extracting to a shared skill eliminates the drift and gives a single place to refine the philosophy. When the philosophy changes, update SKILL.md here — not eight separate files.

### Promotion Must Be Atomic
*Promoted to SKILL.md — see "Promotion to SKILL.md" section, step 4.*

---

## Stop Hook for LessonsLearned Enforcement Is Too Noisy — Do Not Revisit

Category: Process/Model

A `Stop` hook to enforce LessonsLearned updates at session end was proposed and attempted. It was too noisy: the hook fires on every session close regardless of whether the session involved meaningful work, producing a reminder prompt even for trivial single-question sessions. The signal-to-noise ratio was unacceptable.

The in-agent "tell the user: type 'lessons learned session'" pattern is sufficient. It fires only when the agent completes its intended workflow, not on every session end.

**Rule:** Do not propose a `Stop` hook for LessonsLearned enforcement. If better hook tooling arrives (e.g., hooks that can inspect session content before firing), revisit then — but never a blind time/event-triggered reminder.

