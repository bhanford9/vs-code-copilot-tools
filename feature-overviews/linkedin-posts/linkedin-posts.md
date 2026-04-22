# LinkedIn Posts

A skill that guides the full lifecycle of writing a LinkedIn post — from understanding the goal through writing, reviewing, and saving the final draft — using a suggestion-first workflow that eliminates blank-page friction and prevents the most common engagement failures.

## The Problem It Solves

Writing a LinkedIn post that earns engagement is genuinely hard. Most posts generate impressions but not reactions because the failure modes are subtle and easy to miss:

- **Wrong format for the goal** — a knowledge-share post when the actual goal is to generate DMs, or a story when the audience needs a clear technical takeaway. Format and goal have to align, and they usually don't in first drafts.
- **A hook that doesn't earn the "see more" click** — the first line is the only line that shows on mobile before the fold. If it doesn't create tension, curiosity, or contrast, the rest never gets read.
- **A transactional CTA** — "DM me" signals desperation; "I'd love to talk" is warm and gets more responses. The difference is small but the effect is consistent.
- **Posts that start with "I"** — LinkedIn's algorithm and readers both respond less to ego-first openers. It's a fixable mechanical failure that goes unnoticed without a checklist.
- **Dense paragraphs** — walls of text signal low effort regardless of content quality. Scrolling behavior on LinkedIn is fast; white space is a prerequisite, not a style choice.

Without a structured workflow, AI-generated posts check structural boxes (hook, body, CTA) without knowing whether the format actually fits the goal. The result looks reasonable but doesn't earn engagement.

## How It Works

The flow moves through eight stages, each gated on the previous:

```
Establish goal → Understand content → Ideate formats → Select → Plan → Write → Review → Save
```

1. **Understand the goal** — Establishes what success looks like before anything else. A post designed to generate DMs is written and ended differently than one designed to drive traffic or spark debate. Without this, every subsequent decision is made against the wrong target.

2. **Understand the content** — Read or receive the source material and confirm understanding before suggesting anything. Prevents format options from surfacing that don't fit what's actually being shared.

3. **Ideate** — Generate 3–4 distinct post type options from a defined catalogue (Image + Caption, Knowledge Share, Story, Teaser, Engagement Prompt, Thread). Each option includes why it fits this specific content and goal, what it would contain, and what engagement style it's likely to produce — presented as a comparison table. The user evaluates; they don't invent.

4. **Select** — The user picks a format, with modifications accepted. Confirms before proceeding. This gate ensures the plan is built on actual user intent, not a model assumption.

5. **Plan** — A short structured outline before writing: hook draft, body structure, CTA, assets, tone. A review checkpoint at this stage eliminates large rework after the full draft is written.

6. **Write** — Full draft following specific engagement principles: first-line-as-hook, short paragraphs (1–3 lines), one idea per paragraph, warm CTA phrasing, spoiler mechanics that leave something unsaid to invite comments or DMs.

7. **Review** — Systematic checklist before delivery. First line works as a standalone, goal is served, no "I" opener, CTA is warm, something is left unsaid. Catches the most common failure modes before the post reaches the user.

8. **Save** — Output file with a metadata block (goal, audience, post type, date) plus the full post text ready to copy-paste. Naming convention: `linkedin-post-{topic-slug}.md`.

## Design Principle

The skill pre-populates options rather than asking open-ended questions. In Step 3, it generates format candidates with reasoning — the user reviews and selects from a menu rather than starting from a blank field. The same pattern repeats in Step 5 — a full outline is produced for approval before any prose is written.

This is the same philosophy as the Paper Banana infographics skill: minimize the blank-page problem by auto-suggesting everything grounded in the actual source content, then letting the user curate. The result is faster sessions and better-fit output, because suggestions reflect what's actually in the material rather than what the user can articulate from memory.

## Entry Points

| Invoke | When |
|--------|------|
| Mention the `creating-linkedin-posts` skill | You have source content (a blog post, infographic, skill, idea, or outcome) and want to turn it into a LinkedIn post |

## Reference Files

| File | Role |
|------|------|
| [`skills/creating-linkedin-posts/SKILL.md`](../../skills/creating-linkedin-posts/SKILL.md) | Eight-step workflow, post type catalogue, engagement principles, review checklist |
| [`skills/creating-linkedin-posts/LessonsLearned.GLOBAL.md`](../../skills/creating-linkedin-posts/LessonsLearned.GLOBAL.md) | Accumulated process and workflow patterns across sessions |
