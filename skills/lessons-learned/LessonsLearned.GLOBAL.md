# Lessons Learned: lessons-learned skill

> This file tracks how the feedback loop concept itself has evolved.
> Read it before modifying or auditing the lessons-learned skill.

---

## Initial Design

The LessonsLearned pattern originally lived as duplicated inline guidance inside each skill's "Feedback Loop" section and each agent's closing step. Each file had its own slightly different wording of the same rules (when to write, what to skip, subjective gate).

Extracting to a shared skill eliminates the drift and gives a single place to refine the philosophy. When the philosophy changes, update SKILL.md here — not eight separate files.

### Promotion Must Be Atomic — Remove and Add in the Same Operation

When promoting a LessonsLearned entry to a SKILL.md body, the removal from the LL file and the addition to the SKILL.md must happen in the same operation. Adding to the skill body first and leaving the LL file for a follow-up creates a window where the information exists in both places — and that second step is easily forgotten or requires user prompting to complete.

**Rule:** When executing a promotion, treat it as one atomic change: write the content to SKILL.md and delete it from LessonsLearned in the same `multi_replace_string_in_file` call (or equivalent). Never stage the promotion as two separate passes.

---

## Stop Hook for LessonsLearned Enforcement Is Too Noisy — Do Not Revisit

Category: Process/Model

A `Stop` hook to enforce LessonsLearned updates at session end was proposed and attempted. It was too noisy: the hook fires on every session close regardless of whether the session involved meaningful work, producing a reminder prompt even for trivial single-question sessions. The signal-to-noise ratio was unacceptable.

The in-agent "tell the user: type 'lessons learned session'" pattern is sufficient. It fires only when the agent completes its intended workflow, not on every session end.

**Rule:** Do not propose a `Stop` hook for LessonsLearned enforcement. If better hook tooling arrives (e.g., hooks that can inspect session content before firing), revisit then — but never a blind time/event-triggered reminder.

---

## GLOBAL File Written With Codebase-Specific Content Despite Documented Rule

Category: Process/Model

During a code review session, the closing lessons learned step wrote entries containing project names, class names, and method names into `LessonsLearned.GLOBAL.md` — a file tracked in a shared git repo. The SKILL.md for both the `lessons-learned` skill and the `code-review-pipeline` skill already stated the rule ("Never put workspace-specific or codebase-specific content in GLOBAL"). The agent followed the rule's intent for the lesson's *conclusion* (abstract process rule) but violated it for the *context* section (named JEDI classes and methods).

**Root cause**: The agent was reasoning "a concrete example makes the lesson more useful" — which is true for the local file but false for a shared file where no other reader has context for that codebase.

**Rule**: When writing to any `*.GLOBAL.md` file, apply this filter to every sentence before writing: *"Would this sentence make sense to a developer who has never seen this codebase?"* If not, delete it or move it to the local `*.md` file. Context/example sections are the primary failure point — not conclusion/rule sections.

