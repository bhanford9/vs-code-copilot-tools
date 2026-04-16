# Lessons Learned: creating-azure-stories

> This file is updated at the end of AzureStoryCreation sessions.
> Read it before creating stories to apply accumulated knowledge about this codebase and common story patterns.

---

## Seeded Knowledge

### Format Rules

- **Section headers are H2 (`##`), not H3 (`###`).** `## Blocked By`, `## Backing Content`, `## Goal`, `## Details`, `## Acceptance Criteria` — all standalone H2. There is no `## Description` wrapper. (TEMPLATE.md previously had this wrong and was corrected 2026-04-11.)
- **Do not use `-` for acceptance criteria bullets.** Use `- [ ]` checkbox syntax for acceptance criteria items.
- **The `Details` section should mention specific file paths and module names** but never contain code snippets, algorithm descriptions, or step-by-step implementation procedures.

### Format vs. WorkItemCreator Agent

- **Two work item creation paths exist with different formats.** The `AzureStoryCreation` agent (this skill) uses Markdown H2 sections. The older `WorkItemCreator` agent uses inline `Key: Value` prose with `*` bullets. **This skill's format is authoritative for new stories.** The WorkItemCreator format predates this skill and is in the process of being retired.
- When asked to create a story and the user invokes `CreateWorkItems`, the output format will differ from this skill. If consistency matters, redirect to `AzureStoryCreation`.

### Backing Content Quality

- **Backing Content should answer three questions:** (1) What problem does this solve? (2) Why is it needed now? (3) What context does the team need to understand the scope?
- **Avoid vague backing content** like "This is needed for the upcoming release." If you don't know the business justification, ask the user — do not generate placeholder text.

### Goal Section Quality

- **The Goal should be product-outcome language, not technical language.** "Users can export their profile data" not "The ExportService is extended to support JSON serialization."
- **1–2 sentences maximum.** If it takes 3 sentences, the goal is too broad and the story should be split.

### Acceptance Criteria Quality

- **3–7 criteria.** Fewer than 3 suggests the work isn't well understood; more than 7 suggests the story is too large.
- **Each criterion is independently testable by a QA engineer**, not by the developer who wrote it. If a criterion requires intimate knowledge of the implementation to test, rewrite it at the product behavior level.
- **Unit tests are always implied** and do not need to be listed as a separate acceptance criterion unless there is a specific coverage requirement.

### Codebase-Specific Story Patterns

_(Populated from session learnings — add entries after each AzureStoryCreation session)_

---

## When to Append an Entry

Only append if something was harder than expected or revealed codebase-specific patterns not already in this skill. If the session went smoothly, skip the update.

Write a short descriptive heading, then free-form notes. Consider: codebase-specific patterns discovered, clarifications the user had to provide, acceptance criteria phrasing that worked well for this domain.
