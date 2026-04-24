---
name: paper-banana-infographics
description: Generate high-quality Paper Banana prompts for educational infographics from a source markdown file. Minimizes user effort by auto-suggesting all categories from the source content. Use when creating infographics, generating Paper Banana prompts, turning markdown into visual diagrams, or producing educational illustrations.
---

# Paper Banana Infographic Prompt Generator

> The goal is to produce a precise, structured prompt that Paper Banana's Planner agent can interpret unambiguously — specifying exactly what to include, what to exclude, and how to lay it out. Most user input comes from approving or tweaking pre-filled suggestions rather than answering open-ended questions.

## Quick Checklist

```
Paper Banana Prompt Session:
- [ ] Read LessonsLearned.GLOBAL.md for process notes
- [ ] Read LessonsLearned.md for source-specific notes (if it exists)
- [ ] Step 1: Read source — ingest the markdown file
- [ ] Step 2: Auto-suggest — generate suggestions for all categories
- [ ] Step 3: Present & confirm — show suggestion table, let user approve/modify
- [ ] Step 4: Distill key elements — extract must-include facts (5–10 items)
- [ ] Step 5: Identify exclusions — name things in source that should NOT appear
- [ ] Step 6: Compose — assemble the final prompt from confirmed values
- [ ] Step 7: Review — verify prompt against source for accuracy and balance
- [ ] Step 8: Save — write the output file
```

---

## Step 1: Read Source

Ask the user for the path to their source markdown file if not already provided. Read the entire file before proceeding. Do not ask clarifying questions until after Step 2 — generate suggestions first.

---

## Step 2: Auto-Suggest All Categories

After reading the source, generate suggestions for every category below **before asking the user anything**. The user should never stare at a blank field.

### Categories and How to Generate Suggestions

| Category | How to Generate | Example |
|---|---|---|
| **Topic** | Use the document title or first heading | "The Water Cycle" |
| **Audience** | Infer from vocabulary complexity and subject matter; offer 3 grade-level options | "Middle school students (grades 6–8) with no prior knowledge" |
| **Intent** | Summarize what a viewer should walk away understanding in 1–2 sentences | "Understand how water moves through evaporation, condensation, and precipitation" |
| **Visual Style** | Choose the best-fit Paper Banana type based on content structure (see table below) | "Educational Infographic" |
| **Core Concept** | Identify the single most important idea the infographic must convey | "Water continuously cycles through the atmosphere, land, and oceans" |
| **Structure** | Infer a layout from the content's natural flow (see layout options below) | "Circular flow diagram with 4 labeled stages" |
| **Key Elements** | Extract 5–10 specific facts, labels, or components that must appear | "Evaporation, Condensation, Precipitation, Runoff, Groundwater" |
| **Exclusions** | Identify content in the source that is out-of-scope for a single infographic | "Detailed chemistry of water molecules, historical rainfall data" |
| **Color/Aesthetic** | Suggest a palette appropriate for audience and subject | "Cool blues and greens, clean white background, approachable font" |

### Paper Banana Visual Style Options

| Style | Best For |
|---|---|
| Educational Infographic | Concept explanation, multi-part overviews, biology/science |
| Methodology Diagram | Process flows, step-by-step procedures |
| System Architecture | Component relationships, layered systems |
| Flowchart | Decision trees, branching logic |
| Concept Map | Loosely connected ideas, vocabulary networks |

### Layout Options for Structure

- **Circular/cyclical** — processes with no clear start/end (e.g., water cycle, carbon cycle)
- **Top-down flow** — hierarchical or sequential content
- **Left-to-right flow** — timelines, before/after, cause-and-effect
- **Grid / N-column** — comparisons, categories with equal weight
- **Hub-and-spoke** — one central concept with radiating sub-topics
- **Layered vertical** — stacked systems (e.g., OSI model, earth layers)

---

## Step 3: Present & Confirm

Present all suggestions in a single structured block so the user can review everything at once. Format:

```
Here are the suggested values based on your source content.
Review each one and tell me what to change — or say "looks good" to proceed.

| Category        | Suggestion |
|-----------------|------------|
| Topic           | ...        |
| Audience        | ...        |
| Intent          | ...        |
| Visual Style    | ...        |
| Core Concept    | ...        |
| Structure       | ...        |
| Key Elements    | (list below) |
| Exclusions      | (list below) |
| Color/Aesthetic | ...        |

**Key Elements (must appear):**
1. ...
2. ...
...

**Exclusions (must NOT appear):**
1. ...
2. ...
...
```

Wait for user response before proceeding. Apply any changes they request, then confirm the final values.

---

## Step 4: Distill Key Elements

From the confirmed Key Elements list, verify that each item:
1. Is specific enough to be drawn or labeled (not vague like "important concepts")
2. Is achievable in a single infographic without overcrowding
3. Is not contradicted by the Exclusions list

If the Key Elements list exceeds 10 items, flag this to the user — Paper Banana performs best with focused content. Suggest trimming to the most essential items.

---

## Step 5: Identify Exclusions

Strong exclusions prevent the "extra information" problem. Good exclusions are:
- Topics mentioned in the source but not central to the core concept
- Numerical data or statistics that would require precision (use Paper Banana's statistical chart mode instead)
- Sub-topics that deserve their own separate infographic
- Background context the viewer doesn't need to understand the core concept

Always include at least 2–3 explicit exclusions in the final prompt.

---

## Step 6: Compose

Assemble the final prompt using [TEMPLATE.md](TEMPLATE.md). The composed prompt has two parts:

1. **Metadata block** — all confirmed category values, for record-keeping
2. **Paper Banana prompt text** — a cohesive natural-language paragraph optimized for Paper Banana's Planner agent

The prompt text should:
- Open with the visual style and topic
- State the audience and intent clearly
- Describe the layout and structure explicitly
- List key elements in order of visual importance
- State exclusions directly ("Do NOT include...")
- Close with color/aesthetic guidance

---

## Step 7: Review

Before saving, verify the composed prompt against the source file:

- [ ] Every Key Element corresponds to actual content in the source
- [ ] No important concept from the source is omitted unintentionally
- [ ] Exclusions are genuinely present in the source (not phantom exclusions)
- [ ] Audience vocabulary level is consistent with the Intent and Core Concept
- [ ] The structure description matches the content's natural organization

If any issue is found, correct the prompt before saving.

---

## Step 8: Save

Write the output file using the naming convention:

```
{source-filename}-paper-banana.md
```

Place it in the same directory as the source file unless the user specifies otherwise.

The output file format is defined in [TEMPLATE.md](TEMPLATE.md).

---

## Critical Prompting Rules

These patterns are known to produce failures or poor output when ignored. Apply them during Step 6 (Compose) and Step 7 (Review).

### Always Specify Aspect Ratio
Include an aspect ratio in every prompt — omitting it causes Paper Banana to pick a default that may not suit the layout:
- Left-to-right or circular flow: `3:2` (landscape)
- Top-down or vertical layered: `3:4` or `4:5` (portrait)
- Wide comparison/timeline: `21:9`
- 4+ side-by-side columns: `4:3` landscape (portrait is too narrow — nodes become cramped)

Add an `Aspect Ratio` row to the Metadata table and a `**Aspect ratio:**` line in the prompt text.

### Protect Verbatim Text
Paper Banana paraphrases or misspells any text it isn't told to treat as literal. For titles, taglines, or any string that must appear exactly as written, add: "Use this exact text, spelled exactly as written."

### Markdown Formatting Has No Visual Effect
Bold, italic, and other markdown emphasis in the prompt does not produce visual styling. Describe desired visual emphasis explicitly — e.g., "render this phrase in a vivid accent color that differs visibly from surrounding text."

### Enumerate Every Arrow Explicitly
Without a complete arrow list, Paper Banana invents extra connections. Always provide: (1) a numbered list of every arrow with source → destination, (2) a total arrow count, and (3) a rule that no unlisted arrows may be added.

### Use Nested Sub-Elements for Parallel Branches
Representing parallel destinations as separate flow nodes with a merge point consistently produces mangled or extra arrows. When two items are attributes of the same concept, nest them as visual sub-elements inside a single parent node instead.

### Separate Agent Instructions from Image Text
Descriptive text guiding the agent (position hints, layout constraints, node descriptions) often leaks into the rendered image as literal text. Add an explicit rule: "Do not render layout instructions or node descriptions as image text."

### Anchor Color Descriptions with Specifics
Vague color terms ("dark," "light," "muted") produce unpredictable results. Use hex values or concrete comparisons — e.g., `#1e1e2e — rich dark gray, not pure black`.

### Enforce One Location Per Element
Paper Banana tends to restate the same concept in multiple places. A general "avoid repetition" instruction is insufficient. Add: "No element, label, or description may appear more than once in the entire image. Each piece of text exists in exactly one place."

### Parallel Sub-Agents Require Inline Skill Instructions
When generating multiple prompts via parallel sub-agents, each sub-agent must receive the full skill instructions and all critical lessons inline — not just a file path reference. A sub-agent given only a path will not reliably read it.

---

## Feedback Loop

Before starting, read [LessonsLearned.GLOBAL.md](LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](LessonsLearned.md). Apply any recorded patterns from past sessions.

When this workflow is complete, **proceed directly into the lessons learned reflection** — do not ask for permission first. Follow the two-tier feedback loop from `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md`:
- **Source-specific patterns** (infographic domain conventions, content patterns you discovered) → `LessonsLearned.md`
- **Process/workflow improvements** (prompt structure changes, step gaps, agent behavior observations) → `LessonsLearned.GLOBAL.md`
