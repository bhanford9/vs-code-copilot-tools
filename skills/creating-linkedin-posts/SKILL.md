---
name: creating-linkedin-posts
description: Create high-impact LinkedIn posts from a concept, piece of content, or goal. Guides through understanding the goal, understanding the content, ideating post types, selecting the strongest format, planning, and writing. Use when creating LinkedIn posts, drafting social content, turning a blog post or infographic into a LinkedIn caption, sharing knowledge on LinkedIn, or writing audience-growth content.
---

# Creating LinkedIn Posts

> The goal is to write a post that earns engagement — reactions, comments, or DMs — not just impressions. Most user input comes from approving or adjusting pre-filled suggestions rather than answering open-ended questions.

## Quick Checklist

```
LinkedIn Post Creation:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if it exists)
- [ ] Step 1: Understand the goal — what outcome does the user want?
- [ ] Step 2: Understand the content — what is being shared?
- [ ] Step 3: Ideate — generate post type options with reasoning
- [ ] Step 4: Select — user picks the strongest format
- [ ] Step 5: Plan — outline the post structure for review
- [ ] Step 6: Write — produce the full draft
- [ ] Step 7: Review — check against goal and engagement principles
- [ ] Step 8: Save — write the output file
```

---

## Step 1: Understand the Goal

Before anything else, establish what success looks like for this post. Ask:

- What does the user want to happen as a result of this post?
- Who is the intended audience?
- Is this tied to a business goal (leads, brand visibility, consultancy reach)?

If the user has not stated a goal, ask for it directly. The goal shapes everything — a post designed to generate DMs is written differently than one designed to educate.

**Common goals:**
- Generate reactions and comments (visibility, algorithm boost)
- Attract inbound inquiries or business opportunities
- Establish thought leadership on a topic
- Drive traffic to a blog post, project, or resource
- Introduce a concept and invite follow-up conversation

---

## Step 2: Understand the Content

Read or receive the source content before suggesting anything. This may be:
- A concept the user describes verbally
- A piece of writing (blog post, skill, README)
- An infographic or image they've created
- A result, outcome, or experience they want to share

Summarize your understanding of the content back to the user in 2–3 sentences before proceeding. Correct any misunderstanding before ideating.

---

## Step 3: Ideate — Generate Post Type Options

Generate 3–4 distinct post type options. For each, provide:
- **Type name** (from the catalogue below or a custom type)
- **Why it fits** this content and goal
- **What it would include** (hook, structure, assets, CTAs)
- **Estimated engagement style** (comments, reactions, DMs, shares)

Present as a comparison table so the user can evaluate options side-by-side.

### Post Type Catalogue

| Type | Best For | Typical Structure |
|---|---|---|
| **Image + Caption** | Visuals like infographics, diagrams, screenshots | Hook → context → insight → question or CTA |
| **Knowledge Share** | Teaching a concept, pattern, or technique | Hook → explanation (short) → key takeaway → question |
| **Story / Experience** | Personal wins, failures, discoveries | Punchy opener → narrative → lesson → invitation |
| **Teaser / Link Post** | Driving traffic to external content | Hook → spoiler/excerpt → link → why it matters |
| **Engagement Prompt** | Generating comments and debate | Bold opinion or question → brief reasoning → direct ask |
| **Thread / Carousel** | Deep dives that deserve more space | Opening hook post → 3–5 follow-on points → summary |

### Ideation Considerations

For each option, also consider:
- **Hook strength** — the first 1–2 lines must earn the "see more" click
- **Asset pairing** — does this post benefit from an image, graphic, or link?
- **Spoiler mechanics** — for knowledge/concept posts, what can be teased without giving everything away?
- **CTA type** — question, invitation to DM, link click, or tag someone?

---

## Step 4: Select

Present the options table and ask the user to pick one. Accept modifications ("option 2 but with a question at the end"). Confirm the selection before proceeding.

---

## Step 5: Plan

Before writing, produce a short outline of the selected post:

```
**Post Plan**
Type: {type}
Hook: {first line or two}
Body structure: {bullet outline — 3–5 points}
CTA: {how it ends}
Assets: {image, link, none}
Tone: {e.g. conversational, authoritative, curious}
```

Present the plan and wait for approval or adjustments. Do not write the full post until the plan is confirmed.

---

## Step 6: Write

Write the full post. Follow these principles:

### Hook
- First line must be standalone — it shows before "see more" on mobile
- Use tension, contrast, a surprising claim, or a short punchy statement
- Avoid starting with "I" — LinkedIn's algorithm and readers both respond better to topic-first openers

### Body
- Short paragraphs — 1–3 lines max each
- One idea per paragraph
- Use white space liberally — walls of text get scrolled past
- Italics for emphasis sparingly — used well, they add rhythm
- Drop jargon unless the audience is technical and it signals credibility

### Spoilers and Teases
- Hint at depth without revealing everything — "there are ways to take this further, but that's a longer conversation"
- Leave one genuinely interesting thing unsaid to invite comments or DMs

### CTA
- End with a question or invitation — not a command
- Questions that invite people to share their own experience outperform yes/no questions
- "I'd love to talk" outperforms "DM me" — warmer, less transactional

### Length
- Sweet spot: 150–300 words for most post types
- Knowledge shares can go to 400 if every line earns its place
- Teasers should be shorter — under 150 words

---

## Step 7: Review

Before delivering the final post, verify:

- [ ] First line works as a standalone hook — reads well before "see more"
- [ ] No paragraph exceeds 3 lines
- [ ] The goal set in Step 1 is served by the post
- [ ] At least one thing is left unsaid or teased (where appropriate)
- [ ] CTA is warm and inviting, not transactional
- [ ] Post does not start with "I"
- [ ] Tone is consistent throughout

If any check fails, revise before presenting.

---

## Step 8: Save

Write the output file using the naming convention:

```
linkedin-post-{slug}.md
```

Where `{slug}` is a 2–4 word kebab-case summary of the topic (e.g., `linkedin-post-agentic-feedback-loop.md`).

Place it in a `linkedin-posts/` subfolder relative to the source content, or in the working directory if no source file exists.

The output file should contain:
- A metadata block (goal, audience, post type, date)
- The full post text, ready to copy-paste

---

## Feedback Loop

Before starting, read [LessonsLearned.GLOBAL.md](LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](LessonsLearned.md). Apply any recorded patterns from past sessions.

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, follow the two-tier feedback loop from `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md`:
- **Audience/platform patterns** (what hooks worked, what CTAs landed) → `LessonsLearned.md`
- **Process/workflow improvements** (step gaps, ordering issues, agent behavior) → `LessonsLearned.GLOBAL.md`
