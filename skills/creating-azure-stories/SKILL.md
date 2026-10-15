---
name: creating-azure-stories
description: Create, rewrite, or review Azure DevOps work items (stories) sized to the work (XS, Standard, Large), written as a connected briefing for a developer with medium familiarity, with evidence moved to attachments and required lint and cold-read gates. Use when creating Azure DevOps stories, work items, user stories, when user mentions Azure boards, story templates, acceptance criteria, or asks to write, rewrite, or review work items.
---

# Creating Azure Stories

A story is a briefing for the developer who will do the work. It is not a record of how the problem was found or a defense of the finding. Write the least a developer needs to understand the problem, the direction of the fix, and what done means, and tell it as one connected story.

## Workflow

```
Azure Story Creation:
- [ ] 1. Read LessonsLearned.GLOBAL.md and, if present, LessonsLearned.md
- [ ] 2. Write the brief; get the user's confirmation
- [ ] 3. Pick the size tier
- [ ] 4. Draft from the tier's template (TEMPLATE.md)
- [ ] 5. Gate: lint script
- [ ] 6. Gate: cold read by a subagent
- [ ] 7. Gate: ambiguity audit by a subagent; after rewrites, rerun 5 (and 6 if a rewrite adds a claim)
- [ ] 8. Present the draft with all gate results; publish only when asked
- [ ] 9. Lessons learned
```

### 2. Brief (confirm before drafting)

Show the user:
- **Spine**: one sentence in the form "When X, Y happens because Z; change W so that V."
- **Tier** and the reason for it.
- **Decisions already made** (for example, remove rather than fix). The story states these; it does not reopen them.
- **Pointers**: file paths, function names, related story IDs.
- **Attachments**: repro scripts, evidence output.

Everything in the story must support the spine. Cut what does not.

### 3. Size tier

| Tier | Use when | Template |
|---|---|---|
| XS | Rename, dead-code removal, message fix, a small change in 1-2 files, or one mechanical change repeated across any number of files; no design decision | XS |
| Standard | One area, a few files, clear fix direction | Standard |
| Large | A design decision, several areas, a behavior change others will notice, or a spike | Large |

When unsure between two tiers, pick the smaller one. Size the tier by the change, not by the investigation behind it or the number of call sites: the same mechanical edit repeated across one file is XS, even if finding it took days. A side effect of the fix that the developer will run into anyway (for example, other callers getting slower) does not move a story up a tier; state the decision about it in one sentence.

Word counts are goals, not hard limits. Choose the tier by the work's scope, not to obtain a larger word allowance. Exceed the goal when necessary to preserve readable prose, backing context, or clean transitions; never shave words at the expense of the connected briefing.

## Audience

Write for a developer with medium familiarity:
- They know the repository layout, languages, test framework, and tooling. Do not explain these.
- That familiarity does not include domain rules, unusual behavior, or edge-case exceptions. Explain any such rule needed to understand why the problem exists or why the fix is appropriate; do not send the reader to the code to learn the rule.
- They do not know this investigation, its history, or the conversation that produced the story. Tell them only what they need from it.
- They do not know the code's history or other work going on: past commits, earlier refactors, other stories, what the code "used to" do. Describe the code as it is today ("these calls pass the retry count where `sendRequest` expects the timeout"), not how it got that way ("these calls still use the order from before the swap"). Words like "still," "the old," "from before," "no longer," and "was changed" usually mean a sentence leans on history the reader can't see. If history changes what the developer must do, state it fully in one sentence with a story ID or commit; otherwise leave it out.
- For a difficult concept, give a nudge: one sentence plus a pointer to a file, function, or attachment. Not a tutorial.
- Leave the developer room to think. Don't add tips for routine work such as reproducing a state or choosing how to test; a tip written from context the reader lacks reads as noise.

## Telling the Story

- Order: what the subject is, what is wrong, why it matters, where it is, what changes, what done looks like.
- Open with one plain sentence saying what the subject is and what it's for, before anything about what's wrong with it. "`retryTwice` is the helper uploads used to retry once on failure" comes before "`retryTwice` swallows the final error."
- Describe the problem first as what someone sees; put the mechanism in Details. Backing Content is only the subject and a concise need for change.
- Each paragraph answers a question the previous one raised. If a paragraph could move anywhere, it is not connected: fix the transition or cut it.
- Before detailing a solution with several parts, say what the parts are and why in one or two sentences. Then give each part's details. "Split each helper into two versions, because some callers must wait and others only want to try" comes before either version's rules.
- Introduce everything before referring to it: terms, files, functions, attachments, and lists. Say that a thing exists ("six helper functions also wrap these waits," "a list is attached as...") before using "the" for it. Writing "the attached list" or "the six helpers" first is like saying "the hammer is broken" with no hammer in sight.
- State decisions plainly. When a choice is left to the developer, say so in one sentence in Details, with any constraints.
- Mention something that stays unchanged only if a developer would reasonably change it by mistake.

### The Obvious Thing Is Not the Obvious Thing to Say

Research makes minor details feel obvious to the author; the reader has not made that journey. Do not omit a fact just because you now take it for granted. A small detail can be the crucial backing point for a claim or the bridge between two thoughts.

Before finishing the draft, check each claim and transition: what did you learn from the code that makes this conclusion follow? If the reader needs that fact to understand why the problem exists, why it matters, or why the proposed change fits, state it briefly where it is needed. For example, "the fallback uses the same service" may explain why retrying there does not avoid a service outage. Include that connection, not the investigation log. Keep routine lookup values and how-to out unless they serve this explanatory purpose.

## Voice

- Use plain words and active voice. Vary sentence length naturally and keep related sentences together in paragraphs that develop one thought. Short sentences are useful, but a string of clipped definitions and commands is not a connected explanation.
- Write like a teammate: "this check passes when it should fail," not "the assertion contract is not enforced."
- Use the words the team already uses. Don't coin terms, and don't turn a code name into a prose term (`Cache.Snapshot` does not make "snapshots" a word the team uses). If a code name matters, keep it in backticks as code.
- Write the way you'd explain it out loud. Say what a thing does in a full clause instead of compressing it into a noun phrase: "there are functions in `PageHelpers.js` that wait while the app is busy loading" rather than "tests call the `PageHelpers.js` loading waits."
- Describe what code does precisely. "Tests call these to make sure the app is ready before the rest of the test runs" says what happens; "tests use them before moving on" doesn't.
- Don't use a word loosely if it has a specific meaning in the product's domain. Check LessonsLearned.md for words to avoid in this codebase.
- See "Wording to avoid" in FORMAT_RULES.md; the lint script enforces the worst of it.

## Evidence Goes in Attachments

How the problem was found and why it can be trusted (repro scripts, output, history, search results, limits of the evidence) goes in attachment files, not the story body. The body may point to it with a short suggestion: "A script that shows the problem is attached as `repro-name.cjs`. If you want to see it, run `node repro-name.cjs` from the repository root."

Keep a caveat in the body only when it changes what the developer must do, such as "confirm in the running app; the script only exercises the helper."

Attach evidence or leave it out. Never suggest how a demonstration could be built ("this is easiest to show with a small script that..."). If a reader would need a demo to see or check the problem, build it, run it, and attach it, and mention it in the body as a short suggestion.

## Code in Stories

- **Current code**: allowed when it shows the problem faster than prose. At most 2 blocks, 6 lines each.
- **Fix direction**: pseudocode or a one-line signature, at most 5 lines, labeled illustrative. Never working solution code.
- **Scripts**: always attachments, with a short suggestion in the body on how to run them and what they show.
- Prefer file paths and function names over prose that describes code.

## Steps 5-7: Gates (Required)

Run all three gates on every draft before presenting it. Only the user may explicitly accept a failing gate after the remaining gaps are stated. The author must not waive missing domain context or transitions as implementation details.

5. **Lint**: `pwsh -NoProfile -File <skill folder>/scripts/Test-StoryDraft.ps1 -Path <draft.md> -Tier <XS|Standard|Large>`. Fix failures and re-run. Treat warnings as prompts to reread, not automatic edits. Length warnings are advisory: retain words that improve readability or connect ideas, and remove only unnecessary material.
6. **Cold read**: invoke the tool-less `StoryColdReader` with the prompt from COLD_READ.md and the pasted draft. Compare its answers with the spine. Check its missing-link and unexplained-rule findings for facts the research made obvious to you but the draft never states. A paraphrase is not a pass: unresolved domain terms, rules, backing facts, or transitions needed to understand the work fail the gate. Revise, rerun step 5, and repeat step 6 with a fresh `StoryColdReader`. If the restricted agent is unavailable, report the gate as blocked rather than substituting an unrestricted agent.
7. **Ambiguity audit**: hand off to a separate subagent as described below, using AMBIGUITY_AUDIT.md. It checks each sentence for other readings: unexpected endings, words with more than one meaning, unclear actors, unclear references, and task-versus-outcome phrasing. Rewrite every flagged sentence or state why the other reading isn't plausible. Then rerun step 5. If a rewrite adds a new claim or new information, as opposed to rewording, also rerun step 6 with a new subagent: new claims written with the investigation fresh in mind are where backstory slips in. The cold read doesn't replace this: readers skim past ambiguity when the overall meaning is clear.

The same applies to later edits, including edits the user asks for: rerun step 5 every time, and step 6 when the edit adds a new claim or substantially changes the narrative flow.

### When the Cold Read Keeps Growing the Story

Stop revising when the cold read has failed after three revisions and each revision added significant length (for example, the body grew well past the tier's word goal). A story nobody is willing to read helps no one. Go back to the user, show the word count and the gaps the cold read still reports, and suggest keeping the story short and requiring a conversation before work starts. Do not keep adding background to close every gap.

First check whether the story has drifted from its purpose. Each new gap answered with more domain detail is a sign the story is trying to teach the domain instead of stating the problem, the direction, and what done looks like. Cut it back to that.

If the user agrees, keep the body near the tier's word goal and add a `## Kickoff Conversation` section just before Acceptance Criteria: who to talk to (by role or name) and the two to four questions the conversation should answer, taken from the cold read's remaining gaps. Record the user's acceptance of the remaining cold-read gaps when presenting the draft.

### Fixing What the Gates Find

Fix gate findings by cutting or rewording first when that preserves the explanation. If a claim lacks a backing fact or a transition skips a necessary connection, add the smallest verified detail that closes the gap, even if a developer could find it in the code in a minute. Ease of lookup does not make a fact unnecessary to the story. Leave out routine lookup values and how-to that do not support the reasoning. Additional words are justified when they close an explanatory gap, clarify scope, state a decision, or make the prose and transitions easier to follow. Do not remove that improvement merely to meet a length goal.

Report all three results when presenting the draft.

### Handing Off to a Subagent

A gate only works if the subagent reads the draft the way a stranger would. Anything extra steers it toward your view.

1. Start a new subagent for every gate run, including reruns after revisions.
	For cold reads, use `StoryColdReader` only. Its `tools: []` and `agents: []` prevent codebase access and delegation. Paste the draft; do not ask it to open a draft file.
2. Send the prompt from COLD_READ.md or AMBIGUITY_AUDIT.md as written, with only the inputs it asks for: the draft text, plus the words to avoid for the ambiguity audit.
3. Add nothing else. Leave out the spine, the brief, your opinion of the draft, sentences you suspect, what earlier gates found, what changed since the last run, and the conversation.
4. Take the answer as returned. Don't send follow-up questions that hint at the answer you expect.

## Output

- Write the draft to a `.md` file (for example `work-items/<slug>.md`) with attachments in an `attachments/` folder beside it. Do not paste the full story in chat as the deliverable.
- File paths use backticks, never Markdown links; links break when copied to Azure DevOps.
- Drafting does not authorize publishing or updating an existing work item. Both need explicit approval.

## Reference Files

- TEMPLATE.md: the three tier templates
- FORMAT_RULES.md: section rules, limits, and wording to avoid
- EXAMPLES.md: before-and-after examples
- COLD_READ.md: the cold-read subagent prompt
- AMBIGUITY_AUDIT.md: the ambiguity-audit subagent prompt
- scripts/Test-StoryDraft.ps1: the lint gate

## Feedback Loop

Before writing a story, read [LessonsLearned.GLOBAL.md](LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](LessonsLearned.md). Apply any recorded patterns from past sessions.

When this workflow is complete, **proceed directly into the lessons learned reflection** — do not ask for permission first. Follow the two-tier feedback loop from `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md`:
- **Codebase findings** (story patterns specific to this codebase, work item formats, team conventions) → write to `LessonsLearned.md`
- **Process/format improvements** (story structure guidance applicable to any codebase) → write to `LessonsLearned.GLOBAL.md`

Both files are at `~/Repos/vs-code-copilot-tools/skills/creating-azure-stories/`.
