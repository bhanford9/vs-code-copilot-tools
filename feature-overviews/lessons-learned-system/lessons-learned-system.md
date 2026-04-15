# Lessons Learned System

A feedback loop built into every skill and agent workflow. Sessions that surface something notable — a mistake, an unexpected edge case, a pattern the skill didn't anticipate — append a brief entry to a `LessonsLearned.md` file alongside the skill. Future sessions read it before starting.

## The Problem It Solves

Skills and agents encode general best practices. They can't encode user-specific discoveries: how a particular codebase names things, which types can't be mocked in a specific project, what edge cases a team's conventions introduce. Without a persistence mechanism, every session rediscovers the same things from scratch.

`LessonsLearned.md` is that persistence mechanism. It accumulates the discoveries that matter for *this* user's context, making each skill progressively more effective over time.

## How It Works

Every skill workflow that involves complex, multi-step work includes two steps:

1. **Before starting** — Read `LessonsLearned.md` if it exists. Apply any recorded patterns or watch-outs to improve the session before it begins.

2. **After completing** — Reflect on whether anything was hard, surprising, or worth avoiding next time. If yes, append a short entry. If the session was routine, skip it entirely.

The key discipline is restraint: entries are written only when something genuinely notable happened. Routine completions don't produce entries. Long explanations don't belong — brevity is essential.

## User-Specific vs. Globally Applicable

Most lessons are user-specific: discoveries about a particular codebase, team convention, or project quirk. These stay in `LessonsLearned.md`.

Some lessons reveal a defect or gap in the skill itself — something that would help any user. When that happens, the lesson is promoted into the `SKILL.md` body and the `LessonsLearned.md` entry is condensed or removed. Duplicates between the two files defeat the purpose of both.

## Where the Files Live

Each skill has its own `LessonsLearned.md` alongside its `SKILL.md`:

```
skills/
  writing-csharp-tests/
    SKILL.md
    LessonsLearned.md   ← test-writing discoveries
  code-review-pipeline/
    SKILL.md
    LessonsLearned.md   ← review session discoveries
  creating-azure-stories/
    SKILL.md
    LessonsLearned.md   ← story creation discoveries
  ...
```

## Entry Points

| Invoke | When |
|--------|------|
| `/fork-and-improve` | Mid-session course correction — something went off the expected path. Captures what happened, identifies the config fix (SKILL.md, LessonsLearned.md, hook, or instruction file), applies it, and writes the LessonsLearned entry while full context is still fresh |
| `/review-lessons` | Periodic maintenance — scans all LessonsLearned files across all skills, flags entries that should be promoted to SKILL.md or converted to hooks, and surfaces stale Process/Model entries for removal |

## Reference Files

| File | Role |
|------|------|
| [`skills/lessons-learned/SKILL.md`](../../skills/lessons-learned/SKILL.md) | Governs when and what to write — the canonical feedback loop process |
| [`skills/review-lessons/SKILL.md`](../../skills/review-lessons/SKILL.md) | Periodic escalation review — discovers all LessonsLearned files, evaluates entries in parallel, synthesizes action report |
