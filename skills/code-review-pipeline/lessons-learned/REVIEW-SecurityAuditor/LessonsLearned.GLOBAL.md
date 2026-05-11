# Lessons Learned: REVIEW-SecurityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future security reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-08 — Scope-Relative Severity for Absent Auth

**Pattern**: When a personal/local-only application has no authentication, resist classifying this as Critical/High at face value. Apply a deployment-context matrix: localhost-only = Medium; LAN-accessible = High; internet-facing = Critical. Flag it clearly with the escalation condition rather than assigning worst-case severity for a tool that is demonstrably scoped to single-user local use.

**Heuristic**: Check whether the architectural intent (personal tool, no multi-user model) is apparent from the domain model, DI registration, and README before assigning severity to missing auth.

---

## 2026-05-08 — Binary Database Files in Git

**Pattern**: Design-time or migration-scaffolding database files (SQLite `.db`, Access `.mdb`, etc.) frequently appear committed to source repositories. They are binary blobs that do not belong in git: they can accumulate real data, cause merge conflicts, and bloat history. Always check `git ls-files` for `*.db` patterns during security reviews. Classify as Medium if only schema is present, escalate if real data is detected.

---
