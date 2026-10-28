# Azure Story Templates

Pick the tier during the brief (see SKILL.md). Placeholders in square brackets are replaced, never left in the draft.

## XS

For a rename, dead-code removal, message fix, small change in one or two files, or one mechanical change repeated across any number of files. None of these needs a design decision.

```markdown
# [Title: 4-8 words, starting with a verb]

[2-3 sentences: what is wrong, why it matters, and what to change.]

`path/to/file.ext`: [what changes in this file]

A script that [shows or lists what] is attached as `repro-name.cjs`. Run `node repro-name.cjs` from the repository root; [where the output appears].

## Acceptance Criteria
- [ ] [Observable result]
- [ ] [Observable result]
```

No Blocked By, Backing Content, or Goal. Two or three criteria. Omit the attachment sentence when there is none. When a mechanical change spans many files, replace the file line with one sentence naming the folders and put the full site list in an attachment.

## Standard

The default: one area, a few files, a clear direction for the fix.

```markdown
# [Title: 4-10 words]

## Blocked By
[Story #ID: title] or None

## Current State
[2-3 sentences: where the system stands today for the part this work touches, and the problem or relevance if it isn't obvious.]

## Goal
[2-3 sentences, framed like Current State: the objective of this work and what it is for. No steps or file lists.]

## Backing Content
[Optional. Short background on the area that the reader needs before Details makes sense. Delete this section when Current State and Goal are enough.]

## Details
[Where the work is (file paths, class and function names), the mechanism if it helps, a short current-code excerpt if it shows the problem faster than prose, edge cases, constraints, decisions left to the developer, full lists of sites, and anything that must stay unchanged that a developer might reasonably change.]

A script that shows the problem is attached as `repro-name.cjs`; [what it does, in a few words]. If you want to see it, copy it to the repository root and run `node repro-name.cjs`; [where the output appears]. [What it shows today, in one short sentence.]

## Acceptance Criteria
- [ ] [Observable result]
- [ ] [Observable result]
- [ ] [Observable result]
```

Three to five criteria. Omit Backing Content when Current State and Goal are enough. Omit the attachment paragraph when there is none.

Only when the user agreed to it after the cold read kept growing the story (see SKILL.md), add this section just before Acceptance Criteria:

```markdown
## Kickoff Conversation
Before starting, talk to [role or name] about:
- [Question the story deliberately leaves to the conversation]
- [Question]
```

## Large

For a design decision, several areas, a behavior change others will notice, or a spike. Use the Standard template, with the higher word limit. H3 subheadings are allowed inside Details. When a choice is left to the developer, say so in one sentence in Details, with any constraints. Three to five criteria; if more are needed, split the story.
