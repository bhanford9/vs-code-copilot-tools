---
name: read-knowledge-docs
description: Efficiently retrieve and extract targeted information from a structured knowledge base written by the create-knowledge-docs skill. Uses YAML front matter, abstracts, headings, glossary anchors, and cross-reference links to locate specific information without reading large amounts of content. Best invoked via the KnowledgeDocsResearcher sub-agent so research happens in an isolated context and findings are returned as a structured report. Use when looking up domain concepts, tracing architecture, resolving terminology, finding known gaps, or answering a specific question about a documented system.
---

# Read Knowledge Docs

> This skill teaches an agent to retrieve targeted information from a structured knowledge base without consuming unnecessary context. The knowledge base was written using conventions that make fast, surgical lookup possible — this skill is the reading counterpart to those writing conventions.

## Quick Checklist

```
Knowledge Doc Research Session:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if it exists)
- [ ] Step 1: Intake — confirm query and knowledge base path before starting
- [ ] Step 2: Frame the query — clarify what needs to be found and why
- [ ] Step 3: Discover the knowledge base — find the README and scan structure
- [ ] Step 4: Target — narrow to candidate files using YAML, filenames, and README
- [ ] Step 5: Extract — read only what is needed, in priority order
- [ ] Step 6: Traverse — follow cross-references if the first file is insufficient
- [ ] Step 7: Report — return structured findings to the calling context
- [ ] Step 8: Autonomously update LessonsLearned
```

---

## When to Use This Skill vs. Reading Files Directly

Use this skill (or the `KnowledgeDocsResearcher` agent) when:
- You need to answer a specific question about a documented system
- You need to find where a concept is defined or explained
- You want to understand how multiple parts of a system relate
- You are not sure which file contains the information you need

Read files directly (without this skill) only when you already know exactly which file and section you need.

---

## Step 1: Intake

Before doing any work, establish the two required inputs.

### Required

| Input | Question to Ask |
|---|---|
| **Query** | What do you need to find or understand? Be as specific as possible. |
| **Knowledge base path** | Where does the documentation live? (path relative to workspace root, e.g., `docs/architecture/`) |

**If invoked directly by a user:** If either input is missing, STOP and ask the user before touching any files. Keep it to one focused question if only one input is missing.

**If invoked as a sub-agent (e.g., via `runSubagent`):** Do not ask the user. If either input is missing, halt immediately and return an error message that lists exactly what was not provided. The spawning agent is responsible for collecting these before invoking you.

> **For spawning agents:** Before invoking `KnowledgeDocsResearcher`, you must have both the query and the knowledge base path confirmed. If either is unknown, prompt the user yourself — do not delegate that interaction to the sub-agent.

If both are present, proceed to Step 2.

---

## Step 2: Frame the Query

Before touching any files, state the query explicitly. A well-framed query prevents unnecessary reading and keeps the research focused.

Write a query statement in this form:

> "I need to find: {specific information needed}. I will use it to: {purpose}. I do NOT need: {out-of-scope information to actively ignore}."

**Examples:**
> "I need to find: how the Scheduler determines when a job has completed successfully. I will use it to: understand the exit condition for a retry scenario. I do NOT need: the full phase walkthrough or queue internals."

> "I need to find: what the Event Bus is and how the notification service uses it. I will use it to: answer a question about why certain events are not being received. I do NOT need: the message broker internals or serialization details."

The "do NOT need" clause is as important as the query itself — it prevents scope creep when following cross-references.

---

## Step 3: Discover the Knowledge Base

Navigate to the knowledge base path confirmed in Step 1. Read the `README.md` — it contains the reading order table that maps every file to its purpose.

**Read the README fully.** It is short by design. The reading order table tells you which files exist, what each covers, and when to read them — this alone often narrows the search to 1–2 candidate files.

---

## Step 4: Target — Find Candidate Files Without Reading Them

The knowledge base is built with YAML front matter on every file. Use it to find candidates without reading content.

### Strategy 1: YAML Tag Scan (fastest)

Search for your query terms in the YAML front matter across all files in the knowledge base:

```
grep_search(query="tags:.*{your term}", isRegexp=true, includePattern="docs/**/*.md")
```

The `tags` field includes:
- Domain concepts (e.g., `scheduler`, `queue`, `retry`)
- System names and proper nouns (e.g., `EventBus`, `WorkerPool`, `ConfigService`)
- Synonyms and alternate terms

If your term appears in any file's `tags`, that file is a candidate.

### Strategy 2: Filename Pattern (second fastest)

Knowledge base files are named semantically — the filename is a meaningful search query. Use `file_search` with your topic:

```
file_search(query="docs/**/*scheduler*")
file_search(query="docs/**/*pipeline*")
```

### Strategy 3: README Reading Order Table

The README maps every file to a "when to read" description. Scan this table manually — it is the most human-readable targeting tool.

### Strategy 4: Glossary First for Terminology Queries

If the query is about what a term *means*, always start with `glossary.md`. Every term defined in the knowledge base is in the glossary, and each entry links to the document where it is most fully explained. This is a two-read max: glossary entry → target doc.

```
grep_search(query="\\*\\*{YourTerm}\\*\\*", isRegexp=true, includePattern="**/glossary.md")
```

### Strategy 5: TODO Gap Detection

If you need to know whether a topic is documented or is a known gap, search for the `📝 TODO` prefix:

```
grep_search(query="📝 TODO", isRegexp=false, includePattern="docs/**/*.md")
```

A TODO entry in a section means the team knows this gap exists. Report it as a known gap rather than "not documented."

---

## Step 5: Extract — Read in Priority Order

Once you have a candidate file, do not read it all at once. Use this priority order:

### 5a. Read the Abstract First (1 line)

The abstract is a blockquote immediately below the H1:

```markdown
# Title

> {Abstract — answers "what is this file about?" in one sentence}
```

Read this first. If the abstract confirms the file is relevant, continue. If not, the file is a false positive — move on.

### 5b. Scan Headings (structure only)

Read only the H2 and H3 headings. In a well-structured knowledge doc, headings are written as standalone search queries:

- `## What Is the Scheduler?` — self-explanatory
- `## How the Retry Loop Works` — tells you the section covers retry runtime behavior

From the heading list, identify which section answers your query. Then read only that section.

### 5c. Read the Target Section

Read the identified section. If it fully answers the query, stop. Do not read adjacent sections unless they are referenced by your target section and needed for the answer.

### 5d. Check the See Also Section

The `See Also` section at the bottom of every file lists related files with one-phrase descriptions. Scan it to determine whether a cross-reference is worth following. If a See Also entry matches the "do NOT need" clause from your query framing, skip it.

---

## Step 6: Traverse Cross-References If Needed

If the first file answered the query partially, follow cross-references strategically:

1. Note the specific gap (what is still unanswered)
2. Check whether a cross-reference in the text or See Also section directly addresses that gap
3. Apply the same Priority Order from Step 4 to the cross-referenced file
4. Stop as soon as the query is answered — do not read the full cross-reference file

**Hard limit:** Follow at most 3 cross-references per query. If the answer is not found after 3 hops, reframe the query and restart from Step 4, or report that the information does not appear to be documented.

**Never read more than 2 full files** unless the query explicitly spans multiple systems. If you find yourself reading more than 2 full files, the query is too broad — narrow it.

---

## Step 7: Report Findings

Return findings as a structured report to the calling context. Use this format:

```markdown
## Research Report: {query summary}

**Answered:** {Yes / Partially / No — information not documented}

### Findings

{Direct answer to the query in 1–3 paragraphs. Cite the source file and section for every claim.}

### Sources Used

| File | Section | What It Contributed |
|---|---|---|
| {path} | {heading} | {brief description} |

### Known Gaps

{Any 📝 TODO entries encountered that are relevant to the query. List them here so the caller knows they are known gaps, not missing documentation.}

### Suggested Follow-Up

{Optional. If the query revealed an adjacent topic that the caller might want to know about, mention it briefly. Do not expand unless asked.}
```

**Report principles:**
- Every claim must cite a source file and section — no unsourced assertions
- Keep the findings section brief — the caller asked a specific question, not for a full summary
- Known gaps are useful output, not failures — report them clearly
- Do not include information from sections you did not need to read

---

## Step 8: Autonomously Update LessonsLearned

After the research session completes, the sub-agent **always** updates its own LessonsLearned — no user prompt required. This is the key difference from other skills.

Reflect on the session:

- **Did any targeting strategy fail?** (e.g., YAML tags didn't cover the query term, file names were misleading)
- **Was the priority order insufficient?** (e.g., had to read a full file when a more targeted approach should have worked)
- **Were cross-references missing or broken?** (e.g., See Also section didn't include a file that turned out to be directly relevant)
- **Did a `📝 TODO` gap affect the ability to answer the query?**
- **Did the knowledge base structure deviate from expected conventions?** (This could indicate the docs were written without the `create-knowledge-docs` skill)

Write only entries for things that were hard, slow, or unexpected. Do not document sessions where all strategies worked correctly.

Use the two-tier file convention from the `lessons-learned` skill:
- **Workflow issues** (targeting strategy gaps, traversal limit problems, report format failures) → `LessonsLearned.GLOBAL.md`
- **Knowledge-base-specific patterns** (this particular doc set has unusual conventions, certain tags are misleading, a glossary entry is wrong) → `LessonsLearned.md`

---

## Conventions Reference — What to Expect From a create-knowledge-docs Knowledge Base

The following table documents the conventions produced by the `create-knowledge-docs` skill. When reading a knowledge base built with that skill, these will always be present.

| Convention | Location | How to Use It |
|---|---|---|
| YAML `tags` | Every file, front matter | Tag-scan for topic without reading content |
| YAML `category` | Every file, front matter | Filter: `overview` for orientation, `deep-dive` for details, `reference` for lookups |
| YAML `related` | Every file, front matter | See the file's neighbors without opening them |
| One-sentence abstract | First line after H1, in `>` blockquote | Confirm file relevance in one read |
| Semantic H2/H3 headings | Throughout every file | Locate target section by scanning headings only |
| `See Also` section | Bottom of every file | Find adjacent files relevant to current topic |
| `glossary.md` | Root of knowledge base | Terminology first stop; every entry links to source doc |
| `README.md` | Root of knowledge base | Full file inventory with "when to read" guidance |
| `📝 TODO` prefix | Any section with known gaps | Identify known gaps before reporting "not documented" |
| Cross-references at first use | Inline in content | Follow to source doc for deeper explanation |
| Numbered filenames | Content files | Indicates reading order without opening README |
| Mermaid diagrams | Before/in complex sections | Visual structure — read the prose following them for authoritative content |

---

## Deviation Handling

If the knowledge base does NOT follow the `create-knowledge-docs` conventions (no YAML front matter, no abstracts, no See Also sections), fall back to:

1. Read the README or index file if one exists
2. Use `grep_search` on the topic terms across all markdown files in the folder
3. Read matched files using the heading-scan → target-section approach
4. Note the deviation in LessonsLearned.GLOBAL.md so future agents are warned

Do not assume a knowledge base is well-structured until you have confirmed at least one file has YAML front matter with `tags` and an abstract.
