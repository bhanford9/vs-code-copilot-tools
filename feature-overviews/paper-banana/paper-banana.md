# Paper Banana Infographic Prompts

A skill-driven workflow that generates structured, high-quality prompts for the [Paper Banana](https://paper-banana.org/) visual generation tool from a source markdown file — by reading the source and pre-filling every decision, so the user reviews rather than answers.

## The Problem It Solves

Paper Banana's Planner agent interprets prompts literally: what to include, what to exclude, how to lay it out. Open-ended prompting — "make an infographic about the water cycle" — produces results that are either overcrowded (everything from the source was included) or hollow (only the most obvious facts appeared). The two failure modes have the same root cause: the user didn't specify key elements or exclusions, so Paper Banana guessed.

Exclusions are especially easy to omit because they require knowing what *not* to include — which means having read and processed the source content first. A user staring at a blank prompt field hasn't done that analysis; the model has.

A second class of failures comes from structural ambiguity: no aspect ratio, verbatim text that gets paraphrased, arrow relationships that get invented or duplicated. These aren't creativity failures — they're missing constraints. Paper Banana doesn't fill them with good defaults; it fills them with whatever fits.

This skill exists because the right workflow for producing a Paper Banana prompt is not "ask the user questions" — it's "read the source, generate all the answers, then ask the user to confirm."

## How It Works

The workflow moves through eight stages from source file to saved prompt:

```
Read source → Auto-suggest → Confirm → Distill elements → Identify exclusions → Compose → Review → Save
```

**Reading the source first** is non-negotiable. Every category — topic, audience, intent, visual style, layout, key elements, exclusions, palette — is derived from the content, not from model assumptions or user recollection. The user is not asked anything until the model has completed its own analysis.

**Auto-suggesting before asking** is the core inversion that makes the skill work. All nine categories are filled speculatively using rules: topic from the first heading, audience from vocabulary complexity (with three grade-level options offered), visual style from Paper Banana's type taxonomy matched against the content's structure, layout from the content's natural flow (circular, top-down, hub-and-spoke, etc.). The user receives a single table of pre-filled values, not a questionnaire.

**Confirming as a batch** respects the user's time and keeps the decision surface small. One response — "looks good" or a targeted set of corrections — is enough to finalize all nine categories. The model applies changes and confirms before proceeding.

**Distilling key elements** is where the model stress-tests the inclusion list: each item must be specific enough to be drawn or labeled, achievable within a single infographic, and not contradicted by the exclusions. Lists exceeding ten items are flagged — Paper Banana performs best with focused content.

**Identifying exclusions explicitly** addresses the failure mode directly. The model names topics present in the source that are out of scope: sub-topics that warrant their own infographic, numerical data that belongs in a chart, background context the viewer doesn't need. Every prompt carries at least two or three exclusions by design.

**Composing the prompt** assembles a two-part output: a metadata record of all confirmed values, and a cohesive natural-language paragraph optimized for Paper Banana's Planner agent. The paragraph follows a fixed sequence — visual style and topic, then audience and intent, then layout, then key elements in order of visual importance, then explicit exclusions, then color guidance. Structural constraints are added inline: aspect ratio, verbatim-text protection, a complete numbered arrow list with a total count and a prohibition on unlisted arrows. These rules come from the `Critical Prompting Rules` section of the skill, which documents patterns known to produce failures when ignored.

**Reviewing before saving** closes the loop: every key element is verified against the source, every exclusion confirmed as genuinely present in the source, and the audience vocabulary checked for consistency with the intent. Phantom exclusions — things the model named that aren't actually in the source — are corrected at this stage.

**Saving** writes the output file using a predictable naming convention (`{source-filename}-paper-banana.md`) next to the source file, unless the user specifies otherwise.

## Entry Points

| Invoke | When |
|--------|------|
| Mention the `paper-banana-infographics` skill | Provide a path to a source markdown file; the workflow begins immediately |

## Reference Files

| File | Role |
|------|------|
| [`skills/paper-banana-infographics/SKILL.md`](../../skills/paper-banana-infographics/SKILL.md) | Full eight-step workflow, category suggestion rules, visual style taxonomy, layout options, critical prompting rules |
| [`skills/paper-banana-infographics/TEMPLATE.md`](../../skills/paper-banana-infographics/TEMPLATE.md) | Output file format — metadata block and prompt text structure |
| [`skills/paper-banana-infographics/LessonsLearned.GLOBAL.md`](../../skills/paper-banana-infographics/LessonsLearned.GLOBAL.md) | Accumulated process and model-behavior findings from past sessions |
