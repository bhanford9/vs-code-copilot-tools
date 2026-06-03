# LessonsLearned.GLOBAL.md — create-knowledge-docs

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## New Knowledge Base Files Must Be Numbered Before Creation

**Category: Process/Model — Recurring**

When a knowledge base uses a numbered file convention (e.g., `01-entity-lifecycle.md`, `02-integrations/`), every new file added at the same directory level **must carry the next sequential number as a prefix**. This is a recurring failure mode: agents create `topic.md` instead of `13-topic.md`, then the file is either invisible to navigation or must be renamed with a follow-up search-and-replace across all cross-references.

**Root cause:** The numbering rule is not visible at the moment of file creation. The agent is focused on content and skips the naming convention check.

**Required pattern before creating any new file in a numbered KB directory:**
1. Check the highest existing number (`ls *.md | sort` or equivalent)
2. Name the new file `{next}-{name}.md`
3. Add it to the README/navigation index immediately — not later

**Do not** create the file with a placeholder name intending to rename it later. Renames cascade across all files that cross-reference the original name. Get the number right at creation time.

---

## Generic Skills Must Use Fully Synthetic Examples

Category: Process/Model

Skill files that contain examples drawn from a real project — even theoretical examples that mirror a real system — are a data protection violation and require a follow-up scrubbing session.

- DO use completely invented, generic examples: payment gateways, schedulers, auth flows, queue systems.
- DON'T use domain terms, system names, or concepts from any real project.
- When in doubt, ask: could a reader identify the project from this example? If yes, replace it.

---

## Onboarding Transcripts Are High-Generalization Sources — Treat Specific Claims as TODOs

Category: Process/Model

When the documentation source is a meeting transcript (especially an onboarding or teaching session), speakers routinely simplify. Specific numbers and categorical claims from a teaching conversation are often approximations, not authoritative facts. Writing them as stated facts into reference documentation creates incorrect docs that require a follow-up correction pass.

Examples of what went wrong:
- A count stated conversationally (e.g., "~50 event types") was written as a fact in a heading, but the actual count varies by context
- A simplified formula (e.g., `RecordKey = type + source + component`) was written as a complete definition, but the real structure has additional fields
- Named examples of domain-specific processing steps were listed without being verified against the codebase

Rule:
- If the source is a meeting/onboarding transcript, **any specific number, count, or formula** stated conversationally should be written as `> 📝 TODO: Verify — taken from onboarding discussion, may be a simplification` rather than stated as fact.
- Architectural descriptions (how things work conceptually) from onboarding transcripts are generally trustworthy. Specific quantities and exhaustive enumerations are not.
- DO: capture the concept accurately. DON'T: promote the approximate number into a heading or authoritative statement.

---

## `category` Field Trap — Domain Names Are Not Valid Values

Category: Process/Model

The `category` front-matter field has exactly four valid values: `overview | deep-dive | reference | navigation`. When creating a knowledge base in a named domain (e.g., architecture, testing, security), there is strong pull to use the domain name as the `category` value. It is not valid. This mistake appeared at near-100% consistency in one audit — 8 of 15 files across a knowledge base had `category: architecture` instead of one of the four valid values.

The consequence is silent: the file renders fine, but category-based AI retrieval filtering returns no matches for that file regardless of query.

**Rule:** Before finalizing any front matter block, explicitly verify the `category` value is one of the four valid strings. Never trust intuition about what "makes sense" as a category name.

**Recommended addition to the Step 5 verification checklist:** "Every `category` field is exactly one of: `overview`, `deep-dive`, `reference`, `navigation`. Domain names (e.g., `architecture`, `testing`) are not valid values and silently break AI retrieval."

---

## `related` Path Relativity Trap in Subdirectory Files

Category: Process/Model

The `related` front-matter field uses paths **relative to the file's own location**. A file at `02-section/04-topic.md` that wants to reference `02-section/00-overview.md` must write `00-overview.md`, not `02-section/00-overview.md`. The latter resolves to `02-section/02-section/00-overview.md`, which doesn't exist.

This error appears consistently when a contributor either:
- Copies front matter from a root-level file as a template without adjusting path prefixes, or
- Reasons about paths from the repository root rather than the file's directory.

**Rule:** For any file living inside a subdirectory, trace each `related` path from the file's directory, not the repo root. Paths to sibling files (same directory) need no prefix. Paths to parent-directory files need `../`.

**Recommended addition to section 4d and the Step 5 verification checklist:** "For files in subdirectories, verify every `related` path is relative to the file's own directory — not the repository root."

---

## Orphaned `## See Also` from Iterative Document Growth

Category: Process/Model

When a document is written across multiple sessions, a recurring failure mode produces two `## See Also` sections: the first was placed at a perceived endpoint in an early session, then additional content was appended below it in a later session. The first See Also becomes stale and incomplete; the second (at the true end) is correct.

The early See Also is always the tell-tale artifact. It typically has fewer links than the final one, and content below it often contains an H2 or H3 section that would naturally belong in the See Also if the document had been finished in one pass.

**Signal:** Any file with two `## See Also` H2 headings. The first one is always the stale artifact. In at least one observed case, the stale See Also was followed by a `### Layer N` sub-section that duplicated content already covered earlier in the file — two artifacts from the same unfinished session.

**Rule:** During verification (Step 5), grep each file for `## See Also`. If two matches appear in the same file, the document has unfinished structure that requires a content audit — not just deletion of the duplicate heading.

---

## `graph` vs `flowchart` — Writers Always Use the Deprecated Keyword

Category: Process/Model

Contributors creating Mermaid node/edge diagrams from memory almost universally write `graph TD` or `graph LR`. The `graph` keyword is deprecated in Mermaid; the correct keyword is `flowchart`. Both currently render, so the error is silent and accumulates across files.

The intuitive pull is strong: "graph" is the English word for what is being drawn. `flowchart` doesn't feel right for a component relationship diagram that isn't a flowchart.

**Rule:** Node/edge diagrams always use `flowchart` (not `graph`). The exceptions that use their own keywords and are not subject to this rule: `stateDiagram-v2`, `sequenceDiagram`, `classDiagram`, `gantt`, `pie`.

**Recommended addition to the Step 5 verification checklist:** "All node/edge Mermaid diagrams use `flowchart TD/LR/TD` — not the deprecated `graph` keyword."
