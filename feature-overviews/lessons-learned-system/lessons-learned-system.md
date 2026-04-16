# Lessons Learned System

A feedback loop built into every skill and agent workflow. Sessions that surface something notable append a brief entry to a lessons learned file alongside the skill. Future sessions read it before starting.

## The Problem It Solves

Skills and agents encode general best practices. They can't encode user-specific discoveries: how a particular codebase names things, which types can't be mocked in a specific project, what edge cases a team's conventions introduce. Without a persistence mechanism, every session rediscovers the same things from scratch.

The lessons learned system provides that persistence — and because different users have completely different codebases, it separates shared process knowledge (tracked in git) from workspace-specific codebase facts (local to each user).

## Two-Tier Architecture

Each skill directory contains two files:

| File | Tracked in git? | Purpose |
|---|---|---|
| `LessonsLearned.GLOBAL.md` | ✅ Yes | Process/model observations applicable to any user — agent behavior gaps, skill workflow improvements. Shared across all clones. |
| `LessonsLearned.md` | ❌ No (gitignored) | Per-user codebase knowledge — type locations, naming conventions, team patterns, non-mockable types. Grows independently for each user. |

**New users** get the GLOBAL file on clone; their local file starts empty and grows through use.

## How It Works

Every skill workflow that involves complex, multi-step work includes two steps:

1. **Before starting** — Read `LessonsLearned.GLOBAL.md` always. Read `LessonsLearned.md` if it exists on disk. Apply any recorded patterns or watch-outs to improve the session.

2. **After completing** — Reflect on whether anything was hard, surprising, or worth avoiding next time. If yes, classify the lesson:
   - `Category: Codebase` → write to `LessonsLearned.md` (local, gitignored)
   - `Category: Process/Model` → write to `LessonsLearned.GLOBAL.md` (tracked)
   - If routine with no surprises, skip the update entirely.

## Escalation Path

Passive guidance can fail. When it keeps failing, escalate:

```
LessonsLearned.GLOBAL.md entry  (process/model, read before sessions)
   ↓ same topic recurs 3+ times
Promote to SKILL.md rule         (always present, all users)
   ↓ still recurs after promotion
Convert to a hook                 (computational, always enforced)
```

## Where the Files Live

```
skills/
  writing-csharp-tests/
    SKILL.md
    LessonsLearned.GLOBAL.md   ← process notes, tracked in git
    LessonsLearned.md          ← codebase discoveries, gitignored
  code-review-pipeline/
    SKILL.md
    LessonsLearned.GLOBAL.md
    LessonsLearned.md
  ...
```

## Entry Points

| Invoke | When |
|--------|------|
| `/fork-and-improve` | Mid-session course correction — captures what happened, applies the config fix, and writes to the correct LessonsLearned file while context is fresh |
| `/review-lessons` | Periodic maintenance — scans all `LessonsLearned.GLOBAL.md` files, flags entries for promotion to SKILL.md or conversion to hooks, and surfaces stale entries |

## Reference Files

| File | Role |
|------|------|
| [`skills/lessons-learned/SKILL.md`](../../skills/lessons-learned/SKILL.md) | Canonical two-tier feedback loop process — when to read, where to write, escalation path |
| [`skills/review-lessons/SKILL.md`](../../skills/review-lessons/SKILL.md) | Periodic escalation review — discovers all GLOBAL files, evaluates entries in parallel, synthesizes action report |
