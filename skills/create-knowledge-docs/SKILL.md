---
name: create-knowledge-docs
description: Build or extend a structured, AI-indexable knowledge base from any source material — transcripts, wikis, code, interviews, or existing docs. Produces or updates layered markdown documents with YAML front matter, Mermaid diagrams, a glossary, and cross-references designed for both human readers and AI retrieval agents. Use when CREATING OR UPDATING technical documentation, onboarding guides, architecture references, domain knowledge bases, or any situation where information needs to be captured in a durable, retrievable form. This skill defines the structural conventions that must be followed any time you write to a knowledge-base-format document — not just when building from scratch.
---

# Create Knowledge Docs

> This skill produces documentation built for two audiences simultaneously: a human reading for the first time, and an AI agent retrieving targeted information on demand. Every convention in this skill serves both audiences. Do not skip the structural standards — they are the mechanism that makes the documentation useful for future AI-assisted work.

## Quick Checklist

```
Knowledge Doc Session:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if it exists)
- [ ] Step 1: Intake — gather sources, audience, output location, depth
- [ ] Step 2: Plan — identify stories, deep dives, diagrams, glossary terms
- [ ] Step 3: Review plan with user — confirm structure before writing
- [ ] Step 4: Implement — write docs following all structural standards
- [ ] Step 5: Verify — check cross-references, YAML, and Mermaid validity
- [ ] Step 6: Reflect and update LessonsLearned
```

---

## Step 1: Intake

Before planning or writing anything, establish the full context. Ask the user for any of the following that are not already known:

### Required

| Field | Question to Ask |
|---|---|
| **Source material** | What is the source of knowledge? (transcript, wiki, codebase, interviews, existing docs, combination?) |
| **Output location** | Use the `configure-docs` skill to resolve the target directory. If a path is configured, use it and do not ask the user. If unconfigured or `DOCS_DISABLED`, follow the skill's branch rules before continuing. |
| **Subject / domain** | What is this documentation about? |
| **Primary audience** | Who will read this? (new developers, senior engineers, external users, AI agents?) |

### Recommended

| Field | Question to Ask |
|---|---|
| **Depth** | Overview only, or deep dives too? Both? |
| **Additional resources** | Are there wikis, existing docs, or code files that should inform or cross-reference the output? |
| **Diagrams** | Mermaid for structural/flow content, Paper Banana for conceptual infographics, or both? |
| **Existing docs to update** | Is this a new knowledge base or augmenting something that already exists? |

**Do not ask all fields at once.** If you have enough to start planning (source + output location + subject), proceed to Step 2 and note any missing fields at the top of your plan. Ask only for what is genuinely blocking the next step.

---

## Step 2: Plan

Before writing any files, produce a **Documentation Plan** and present it to the user. The plan identifies the documents to write, what each covers, and what diagrams each needs.

### Identify the Stories

A knowledge base is not a flat list of facts. It tells stories at multiple levels of abstraction. For each domain, ask:

1. **What are the 2–4 high-level stories?** — The narrative arcs a newcomer needs to understand to have a mental model of the system.
2. **What are the deep dives?** — Topics that a practitioner will need to reference in detail while actively working.
3. **What needs a glossary?** — Any domain-specific terms, system-specific terms, or terms that are named differently in code vs. in the domain.
4. **What needs a diagram?** — Any system with components that interact, any process with distinct phases, any concept that involves cycles or hierarchy.

### Plan Output Format

Present the plan as:

```
## Documentation Plan

### High-Level Stories
| # | Title | What it covers |
|---|---|---|
| 1 | ... | ... |

### Deep Dives
| # | Title | What it covers |
|---|---|---|
| 1 | ... | ... |

### Supporting Documents
| File | Purpose |
|---|---|
| README.md | Navigation index |
| glossary.md | All domain terms |

### Diagrams Per Document
| Document | Mermaid Diagrams | Paper Banana |
|---|---|---|
| ... | ... | ... |

### Open Questions
- {anything still needed from the user before writing}
```

Wait for the user to confirm or revise the plan before proceeding to Step 4.

---

## Step 3: Review Plan with User

Present the full plan from Step 2. Apply any requested changes. Do not begin writing until the user has confirmed the structure.

If the user says "looks good" or equivalent, proceed immediately. Do not re-summarize the plan or ask follow-up questions about confirmed sections.

---

## Step 4: Implement — Structural Standards

Every document produced by this skill **must** follow the standards below. These are not optional — they are what makes the output useful for AI retrieval and human navigation.

---

### 4a. File and Folder Conventions

#### Directory Structure

A knowledge base uses a **hierarchical directory structure** — sections are either leaf files or folders, never both:

- A section with no sub-sections is a single `.md` file.
- A section that gains sub-sections becomes a **folder** containing a `00-overview.md` (the section overview) and numbered child files or subfolders.

Numbering resets at each directory level — sub-sections within a folder are numbered `01`, `02`, `03`. The full address of any document is its path.

```
docs/knowledge-base/
├── README.md                    ← root navigation index (unique — one per knowledge base)
├── glossary.md                  ← cross-cutting; always stays at root
├── 01-overview.md               ← leaf section (no sub-sections)
├── 03-design-engine/
│   ├── 00-overview.md           ← section overview (replaces the flat file)
│   ├── 01-chord-sizing.md       ← leaf sub-section
│   └── 02-web-sizing/
│       ├── 00-overview.md
│       └── 01-v1s-web.md
└── infographics/
```

**`00` is reserved.** Never use `00` for a content sub-section — it always means "orientation for this directory level."

**`README.md` is unique.** Only one exists per knowledge base, at the root. Section folders use `00-overview.md`, not `README.md`. Using `README.md` inside section folders causes agent file-search ambiguity and breaks the numbering signal.

#### Depth = Specificity

| Level | Purpose | Tone |
|---|---|---|
| Root leaf files (`01-overview.md`) | What the system is, why it exists | Conceptual, jargon-light |
| Section overview (`03-topic/00-overview.md`) | How the subsystem works end-to-end | Descriptive, some implementation detail |
| Deeper levels | A specific mechanism, rule, or edge case | Prescriptive, authoritative |

Top-level and `00-overview.md` files must always be sufficient to build a mental model without reading sub-sections.

#### Other File Naming Rules

- File names: lowercase, hyphen-separated, no spaces
- Names should be meaningful as standalone search queries: `chord-sizing.md` not `part1.md`
- Use a subfolder for infographics: `infographics/`

---

#### Migrating a Flat File to a Section Folder

When a leaf file grows to the point where sub-sections are needed:

1. **Create the folder** with the same name as the file (without `.md`)
2. **Move the file** into the folder as `00-overview.md` — content unchanged
3. **Add sub-section files** alongside it (`01-topic.md`, `02-topic.md`, etc.)
4. **Update cross-references** — search for links to the old flat filename and update:
   - `[03-topic.md](03-topic.md)` → `[03-topic/00-overview.md](03-topic/00-overview.md)`
5. **Update the root README's Reading Order table** — replace the flat file entry with the folder overview path; add sub-section rows beneath it indented with `&nbsp;&nbsp;`

---

### 4b. YAML Front Matter — Required on Every File

Every markdown file must begin with a YAML front matter block. This is the primary mechanism for AI retrieval — an agent can scan front matter without reading file contents.

```yaml
---
tags: [tag1, tag2, tag3]
category: overview | deep-dive | reference | navigation
related: [other-file.md, another-file.md]
---
```

**`tags`** — Include:
- The subject domain (e.g., `authentication`, `data-model`, `pipeline`)
- Key concepts covered in this file
- Synonyms or alternate terms a searcher might use
- System names, tool names, and proper nouns mentioned

**`category`** — One of:
- `overview` — high-level story, suitable for a newcomer's first read
- `deep-dive` — detailed reference, suitable for active practitioners
- `reference` — static lookup content (glossary, term lists, configuration tables)
- `navigation` — index or map files (README)

**`related`** — All files that are directly relevant to this one. This enables an agent to discover the document graph without reading file contents.

---

### 4c. Document Structure Template

Every content file follows this pattern:

```markdown
---
{YAML front matter}
---

# {Title — meaningful as a standalone search query}

> {One-sentence abstract. Written for an AI retrieval snippet or a human skimming. Should answer "what is this file about?" in one sentence.}

---

## {Major Section — H2}

{Content}

### {Sub-section — H3}

{Content}

---

## See Also

- [{Title}]({path}) — {one-phrase reason to go there}
- [{Title}]({path}) — {one-phrase reason to go there}
```

#### Rules for the abstract

- Must be the **first content line** after the front matter — before any headings
- Must be a single sentence in a blockquote (`> ...`)
- Must be self-contained — no pronouns without antecedents
- Written to work as a search engine snippet: "The payment gateway is the component responsible for processing external transactions..."

#### Rules for headings

- H1: one per file, matches the document title
- H2: major logical sections — each should be meaningful as a standalone search query
  - ✅ `## What Is the Scheduler?`
  - ❌ `## Overview`
- H3: sub-sections within an H2
- Never skip levels (no H4 without H3)

#### Rules for the See Also section

- Every file must have a See Also section at the bottom
- Each entry is a markdown link followed by a dash and a one-phrase description of why to go there
- This section enables an agent to traverse the document graph from any entry point

---

### 4d. Cross-References

Link to other documents on **first mention** of any concept that has its own file. Use the file's display title as link text, not the filename.

```markdown
The Scheduler (see [03-scheduler.md](03-scheduler.md)) operates as a multi-phase pipeline.
```

For glossary terms: link to the glossary on **first use in each file**:

```markdown
All [queue entries](glossary.md#queue-entry) must pass validation checks.
```

Use anchor links (`#heading-slug`) for deep references within a file.

**Rules:**
- Cross-reference at first use, not every use
- Never duplicate a cross-reference more than once per section
- All cross-reference links must use relative paths (not absolute)
- Cross-references must be bidirectional — if A links to B, B's See Also should link to A

---

### 4e. Glossary Conventions

The glossary is the primary AI retrieval anchor for terminology. An agent reading only the glossary should be able to answer "what does X mean in this domain?" for any term.

```markdown
## {Letter}

**{Term}**
{Definition — 1–4 sentences. State what it is, what it does, and why it matters.}
See [{related doc title}]({path}).
```

Rules:
- Alphabetical order within each letter section
- Bold the term
- Every term links to the document where it is most fully discussed
- Include synonyms and alternate names as separate entries pointing to the canonical entry
- Note code-domain mismatches explicitly: "The code uses the term X; engineers call this Y"

---

### 4f. TODO Placeholders

This documentation is a living resource. Use `📝 TODO` placeholders to mark known gaps:

```markdown
> 📝 TODO: Document the event payload schema and the fields it exposes.
```

Rules:
- Always placed in a blockquote
- Specific — name what is missing, not just "add more detail"
- Do not leave an entire section empty — if a section has no content yet, write one summary sentence and a TODO for expansion
- TODOs should be searchable: use the consistent `📝 TODO` prefix so an agent can find all open gaps with a single search

---

### 4g. Mermaid Diagrams

Use Mermaid diagrams for:
- System component relationships (use `graph` or `flowchart`)
- Process flows with distinct phases (use `flowchart`)
- State machines or decision trees (use `flowchart` with decision diamonds)
- Pipelines with directional data flow (use `flowchart LR`)
- Hierarchies (use `graph TD`)

**Do not use Mermaid for:**
- Conceptual/educational visuals (use Paper Banana instead)
- Anything that requires custom icons, illustrations, or color coding beyond what Mermaid supports natively
- Tables or lists that can be expressed in markdown directly

#### Diagram Syntax Standards

Always use `flowchart` (not deprecated `graph`) unless there is a specific reason to use another diagram type:

```markdown
​```mermaid
flowchart TD
    A["Node label"]
    B["Another node"]
    C{Decision?}

    A --> B
    B --> C
    C -->|Yes| A
    C -->|No| D["Done"]
​```
```

**Labeling rules:**
- Every node must have a human-readable label in quotes
- Use `["label"]` for standard nodes, `{"decision?"}` for decision nodes, `[("label")]` for data stores
- Label text should be self-explanatory without reading the surrounding prose
- Direction: `TD` for hierarchies and phases; `LR` for pipelines; `TD` default
- **For line breaks inside a label, use `<br/>` — never `\n`.** `\n` renders as the literal characters `\n` in all Mermaid renderers.

**Subgraph guidance:**
- Use `subgraph` to show a container with internal parts (e.g., a shared data structure with named fields)
- Connect external arrows to the **subgraph ID**, not to the internal nodes — this keeps edge labels outside the container and avoids layout collisions
- Internal nodes inside a subgraph should be a visual listing only; give them no edges unless the diagram's explicit purpose is to show which internal part is accessed

**Always follow a Mermaid diagram with a prose explanation.** The diagram is a visual aid — the prose is the authoritative content. A reader who cannot render Mermaid must still understand the concept.

**Diagram placement:** Place diagrams immediately after the heading they illustrate. Do not put diagrams at the end of a section.

#### Paper Banana Prompts

For conceptual illustrations (educational infographics, system overviews for non-technical audiences, visual metaphors), use the `paper-banana-infographics` skill to generate prompts rather than attempting to produce illustrations inline.

Store Paper Banana prompt files in an `infographics/` subfolder. Use the naming convention `{topic}-paper-banana.md`. See the `paper-banana-infographics` skill for the full prompt format.

---

### 4h. README.md — Root Navigation Index

Every knowledge base has exactly **one** `README.md`, at the root of the doc folder. Section folders use `00-overview.md` instead — never `README.md`.

The root `README.md` must:

1. States what the knowledge base covers (one paragraph)
2. Provides a **Reading Order** table with: filename, title, what it covers, and when to read it
3. Lists any infographics or supplementary materials
4. Notes that the knowledge base is a living document

```markdown
## Reading Order

| File | What It Covers | Read When... |
|---|---|---|
| [01-overview.md](01-overview.md) | High-level system scope and context | First thing, always |
| [glossary.md](glossary.md) | All domain term definitions | Any time a term is unfamiliar |
```

The README is the entry point for both human readers and AI agents discovering this knowledge base for the first time. Keep it short — it is a map, not content.

---

### 4i. AI Retrieval Optimization — Summary of All Techniques

The following table documents every technique this skill uses to make content fast to retrieve and easy to consume for an AI agent. The companion `read-knowledge-docs` skill depends on these conventions — if you change output formats here, update that skill's Conventions Reference table accordingly.

| Technique | Where Used | AI Benefit |
|---|---|---|
| YAML `tags` | Every file front matter | Allows tag-based filtering without reading content |
| YAML `category` | Every file front matter | Narrows search to overview vs. deep-dive vs. reference |
| YAML `related` | Every file front matter | Enables graph traversal without content reading |
| One-sentence abstract | First line of every file | Returns a useful snippet from a single-line read |
| Semantic heading text | All H2/H3 headings | Makes headings work as standalone search queries |
| `See Also` section | Bottom of every file | Enables agent to chain from one doc to the next |
| Glossary with doc links | `glossary.md` | Single lookup point for all terminology |
| Cross-references on first use | In-line in content | Connects concepts to their authoritative source |
| Anchor links (`#slug`) | In-line cross-references | Enables deep lookup within a file |
| `📝 TODO` prefix | All gap placeholders | Makes knowledge gaps discoverable with one search |
| Numbered file names | Content files | Communicates reading order without a README |
| Mermaid diagrams + prose | Complex relationships | Visual + text redundancy for incomplete renderer support |

---

## Step 5: Verify

Before calling the work complete, check:

- [ ] Every file has YAML front matter with `tags`, `category`, and `related`
- [ ] Every file has a one-sentence abstract in a blockquote immediately after the H1
- [ ] Every file has a `See Also` section
- [ ] All cross-references use relative paths and link text (not bare filenames)
- [ ] Bidirectional: if A's See Also links to B, B's See Also links to A
- [ ] `README.md` reading order table includes all content files
- [ ] `glossary.md` covers all domain-specific and system-specific terms introduced
- [ ] Every Mermaid diagram is followed by prose explanation
- [ ] Mermaid node labels use `<br/>` for line breaks, not `\n`
- [ ] No sections are entirely empty — all gaps have `📝 TODO` entries with specific descriptions
- [ ] File names are lowercase, hyphen-separated, semantically meaningful

---

## Step 6: Reflect and Update LessonsLearned

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, read `skills/lessons-learned/SKILL.md` and follow the two-tier feedback loop. Consider:

- Were there source types (transcript, codebase, wiki) that required special handling not covered in this skill?
- Did the plan structure not fit the content well? (e.g., no clean "high-level story" separation, or too many glossary terms to handle)
- Were any of the structural standards hard to apply to this content type?
- Did any AI retrieval technique prove more or less useful than expected?
- Did the user revise the plan significantly? What did that reveal about the intake questions?

Only write entries for things that were hard, slow, surprising, or went wrong. Routine sessions produce no entries.
