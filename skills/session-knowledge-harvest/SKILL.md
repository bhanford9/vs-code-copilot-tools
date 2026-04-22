---
name: session-knowledge-harvest
description: Extract and document architectural knowledge discovered during any coding or investigation session. Mines the session for business rules, behavioral contracts, counterintuitive code patterns, new terminology, and gaps that were researched or user-clarified — then integrates the findings into the existing architecture knowledge base. Use at the end of any session where meaningful domain or codebase understanding was gained: debugging sessions, code reviews, work item analysis, investigation spikes, refactoring work, or any session where "I didn't know that before" occurred.
---

# Session Knowledge Harvest

> Run at the end of any session where meaningful domain or codebase knowledge was gained. Mines the session for what was learned, checks what is already documented, and integrates new knowledge cleanly into the existing architecture docs.

---

## Quick Checklist

```
Session Knowledge Harvest:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if present)
- [ ] Phase 0: Workspace Docs Lookup — establish the docs directory before any extraction
- [ ] Phase 1: Extract — mine the session for knowledge candidates
- [ ] Phase 2: Classify — assign each item a type and destination
- [ ] Phase 3: Gap Check — verify what is already documented
- [ ] Phase 4: Plan — fit new knowledge into the existing doc structure
- [ ] Phase 5: Write — apply all changes
- [ ] Phase 6: Cross-reference pass — update links, frontmatter, TODOs
- [ ] Phase 7: Lessons Learned — update this skill's LessonsLearned files
```

---

## Phase 0: Workspace Docs Lookup

Before extracting anything, establish whether and where documentation should be written for the current workspace.

Use the `configure-docs` skill to perform the **Workspace Docs Lookup**.

| Result | Action |
|---|---|
| Path configured | Store the path — use it as the target for all Phase 5 writes. Proceed to Phase 1. |
| `DOCS_DISABLED` (automated invocation) | Skip silently — do not mention docs. Stop here. |
| `DOCS_DISABLED` (user manually invoked this skill) | Inform the user: "Automated documentation is disabled for this workspace. Run `configure-docs` to set a path or re-enable it." Stop here. |
| Unconfigured | Run the configure-docs flow (ask the user). If they provide a path, continue. If they choose Skip, stop here. |

---

## Phase 1: Extract

Before extracting, orient on the session:

1. **Read the session todo list** (if one was maintained) — it is ground truth for what was actually worked on, more reliable than working memory.
2. **Review the conversation** with the following structured extraction prompts. Each prompt targets a different source of documentable knowledge.

### Extraction Prompts

**Corrections made during the session**
Every time the user corrected the agent, or the agent had to revise its understanding, something was wrong. Whatever was wrong is almost certainly underdocumented. List each correction.

**High search-cost discoveries**
Anything the agent had to search for across multiple files or required significant exploration. High search cost = high documentation value. What would have been immediately findable if a good doc existed?

**Counterintuitive or surprising code**
Any place where behavior didn't match what the name, structure, or convention implied. The `Equals` method that only compared hash codes is a canonical example. These are traps future coding agents will fall into.

**Cross-file patterns discovered**
Any convention, contract, or pattern that appears in 3+ places but is not written down. If it had to be inferred by reading multiple files, it should be documented.

**Concepts explained by the user**
Any time the user provided domain context or answered a "why does it work this way?" question. These are knowledge items that exist only in the user's head.

**Resolved TODOs**
Any `📝 TODO` in the existing documentation that was answered during this session. These are cleanup targets, not just additions.

**New terms used**
Any term — domain, code, or system — that was used in this session and doesn't have a glossary entry.

---

## Phase 2: Classify

Before checking whether an item is documented, assign each extracted item a type. This determines where it belongs and whether it needs an agent warning.

| Classification | Description | Destination |
|---|---|---|
| **Domain rule** | A business or structural requirement — how something works by specification | Appropriate architecture doc section |
| **Behavioral contract** | A codebase-enforced rule that all related code must follow (e.g., the key-class equality pattern) | Architecture doc + ⚠️ coding agent note |
| **Coding agent trap** | Something counterintuitive that a future agent will likely get wrong | Architecture doc + prominent ⚠️ coding agent note |
| **New glossary term** | A term without an existing definition | `glossary.md` |
| **TODO resolution** | A `📝 TODO` in the docs that can now be filled in | Replace the TODO in place |
| **Known bug / tech debt** | A bug, design flaw, or planned replacement | Work item — not architecture docs |
| **Obvious from code** | Something any competent agent would infer by reading the code | Skip — do not document |

### The Coding Agent Trap Note Convention

Items classified as **Behavioral Contract** or **Coding Agent Trap** must include a prominent warning callout using this exact format:

```markdown
> ⚠️ Coding agent note: {specific actionable warning — what to do or avoid and why}
```

This callout is what makes the documentation useful at precisely the moment a future agent is about to make a mistake.

### The Scope Gate

Before proceeding with any item, apply this filter:

> "Would a coding agent working in this area 3 months from now benefit from knowing this — and would they be unlikely to find it quickly by reading the code?"

If both answers are not **yes**, discard the item. This gate cuts HOW details, implementation procedures, and anything that is obvious from the code itself.

---

## Phase 3: Gap Check

For each surviving classified item, check whether it is already documented before planning to add it.

**Delegate to `KnowledgeDocsResearcher`** — do not search manually. Pass it a specific question per item. This keeps the main conversation context clean and prevents duplicate search work.

Read the `read-knowledge-docs` SKILL.md before delegating, to confirm the right query strategy.

If an item is **already documented**:
- Check whether the existing documentation is accurate and complete. If the session revealed a nuance that is missing, the item becomes an **update** rather than an **addition**.
- If it is accurate and complete, discard the item entirely.

---

## Phase 4: Plan

Present a **Documentation Plan** to the user before writing anything. Do not skip this step.

The plan format:

```
## Documentation Plan

### New Additions
| Item | Classification | Destination file | Action |
|---|---|---|---|
| {what was learned} | {type} | {existing or new file path} | Add / Update / Create |

### TODO Resolutions
| File | TODO line summary | Replacement content summary |
|---|---|---|

### Cross-Reference Updates Needed
| File | Update needed |
|---|---|

### New Glossary Terms
| Term | One-line definition preview |
|---|---|

### Items Discarded
| Item | Reason |
|---|---|
```

**Before finalizing the plan:**

1. Read the `create-knowledge-docs` SKILL.md — verify that all proposed placements follow its structural conventions (YAML front matter, document template, heading rules, cross-reference rules, file naming conventions).
2. Verify that the Details section of any proposed doc addition describes **what and where** only — no HOW, no implementation steps, no code snippets.
3. Check: does any proposed addition require a new file or directory? If so, confirm it follows the hierarchical directory conventions.

Wait for user confirmation before writing.

---

## Phase 5: Write

Execute all changes from the confirmed plan. Apply each item using `multi_replace_string_in_file` for multiple edits in the same session — do not use sequential single-file edits.

**For each new section added, verify:**
- YAML `tags:` updated to include new topic terms
- YAML `related:` includes any files cross-referenced in the new content
- The document abstract (blockquote after the H1) still accurately describes the file's full scope

**For coding agent traps and behavioral contracts:**
- The ⚠️ callout is specific — not "be careful with equality" but "do not use hash-code comparison alone as the final Equals answer; always follow with field comparison"
- The callout names what to do AND what not to do, with a brief reason

---

## Phase 6: Cross-Reference Pass

After writing, run a targeted cross-reference check. Do not skip this — it is what keeps the knowledge base navigable over time.

**Check each modified or created file:**

- [ ] Does `README.md`'s reading order table need a new row, updated description, or updated path?
- [ ] Are YAML `tags:` in modified files complete? Add any new concept terms introduced.
- [ ] Are YAML `related:` in modified files bidirectional? If file A now references file B, does file B's `related:` list include file A?
- [ ] Do sibling documents need a new `See Also` entry pointing to what was added?
- [ ] Were any `📝 TODO` notes resolved? Remove them from the doc and record the resolution in the plan summary.
- [ ] Were any glossary cross-references used in new content? Confirm they link to `glossary.md` on first mention.

---

## Phase 7: Lessons Learned

When the session is complete, update the two-tier LessonsLearned files for this skill:

- **`LessonsLearned.md`** (local, gitignored) — codebase-specific patterns: which doc files exist, where things live in this repo's architecture, team conventions observed.
- **`LessonsLearned.GLOBAL.md`** (tracked in git) — process improvements: extraction prompts that worked or didn't, classification rules that need sharpening, cases where the scope gate was hard to apply.

Follow the `lessons-learned` SKILL.md for the two-tier write rules.

Only write an entry if something was hard, surprising, or went wrong. Do not document smooth sessions.

---

## Scope — What This Skill Is NOT For

- Do not use this skill to document **implementation decisions** (HOW code was written). That belongs in code comments.
- Do not use this skill to create **work items** — use the `creating-azure-stories` skill for that.
- Do not use this skill to document **test results or characterization data** — that belongs in the test infrastructure.
- Do not extract **obvious facts** that any agent would infer from reading the code. The value of this skill is precision, not volume.
