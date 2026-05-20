# Lessons Learned: creating-azure-stories

> This file is updated at the end of AzureStoryCreation sessions.
> Read it before creating stories to apply accumulated knowledge about this skill.

---

## Two Work Item Creation Paths — Format Disambiguation

Two distinct agents exist for creating Azure work items:
- **`AzureStoryCreation` agent** (this skill): Markdown H2 sections (`## Blocked By`, `## Goal`, etc.)
- **`WorkItemCreator` agent** (older): Inline `Key: Value` prose with `*` bullets

The `AzureStoryCreation` format is authoritative for new stories. `WorkItemCreator` predates this skill and is being retired. If a user invokes `CreateWorkItems` and consistency matters, redirect to `AzureStoryCreation`.

## Details Section — HOW Content Is a Persistent Violation

Despite being a stated rule in SKILL.md, the Details section frequently drifts into HOW content: which fields to compare, what not to change, implementation order. This violation recurred in April 2026 even when the rule was already documented and visible.

The self-check in SKILL.md's Critical Rules exists precisely because the rule alone is insufficient. When reviewing a Details section, apply the self-check actively — do not assume compliance. If the text would allow a developer to begin coding without making any design decisions, it contains HOW content and must be trimmed.

---

## When to Append an Entry

Only append if something was harder than expected or revealed a universal process pattern not already captured in SKILL.md. If the session went smoothly, skip the update. Do not record codebase-specific patterns here — those belong in `LessonsLearned.md`.
