# Lessons Learned: creating-azure-stories

> This file is updated at the end of AzureStoryCreation sessions.
> Read it before creating stories to apply accumulated knowledge about this skill.

---

## Two Work Item Creation Paths — Format Disambiguation

Two distinct agents exist for creating Azure work items:
- **`AzureStoryCreation` agent** (this skill): Markdown H2 sections (`## Blocked By`, `## Goal`, etc.)
- **`WorkItemCreator` agent** (older): Inline `Key: Value` prose with `*` bullets

The `AzureStoryCreation` format is authoritative for new stories. `WorkItemCreator` predates this skill and is being retired. If a user invokes `CreateWorkItems` and consistency matters, redirect to `AzureStoryCreation`.

## Details Section — Direction, Not Procedure

Details may give the fix direction as a concept or short pseudocode (see SKILL.md "Code in Stories"). It still drifts into procedure: which fields to compare, implementation order, long lists of what not to change. If the text would let a developer start coding without making any design decision, trim it back to direction plus pointers. List something that stays unchanged only when a developer would reasonably change it by mistake.

## Rewrite Trial (September 2026): What the Cold Read Caught

Teammates said earlier stories read as AI-generated: evidence caveats, process narration, inline scripts, and one template for every size. After the rewrite rules, lint caught none of the remaining problems. The cold read caught all of them:
- Attachment lines that didn't say where to save the file or whether it checks the real code. This is now part of the template.
- Feature areas named in acceptance criteria where testers need real test names. This is now a criteria rule.
- Relative terms without a reference point ("until focus moves").
- A scope question ("does this also cover the sibling assertions?") that revealed the story had missed related cases.

Lint enforces shape; only the cold read tests whether the story makes sense to a stranger. Don't skip it for small stories.

Reviewer feedback from the same trial:
- A story about fifteen calls with reversed arguments in one file was drafted as Standard because the investigation was large. It was XS. Size the tier by the change, not by the effort behind it or the number of call sites.
- *(Superseded October 2026 by "Current State and Goal Carry the Briefing")* Backing Content kept drifting into mechanism and backstory. It should state the subject and a short need for change; the mechanism goes in Details.
- The draft discussed a function before saying what it was. Open with a plain sentence saying what the subject is and what it's for.
- A multi-part fix jumped straight into the first part's details. State the plan and the reason for its parts first, then detail each part. The cold read did not flag this until its prompt asked about details arriving before the plan.
- Open Questions and Out of Scope sections were removed from the Large tier at the user's request. Developer choices go in Details as one sentence; exclusions are mentioned only when a developer would reasonably assume them.
- *(Superseded October 2026 by "Current State and Goal Carry the Briefing"; the forward-looking "should" framing still applies)* Goals were written in present tense ("People reading results can rely on them"), which reads as the current state. A Goal states where we are trying to go ("should be able to rely on them"); the current state belongs in Backing Content. Lint warns when a Goal has no "should" or "will."
- Attachment notes read like commands and carried too much detail. Point to an attachment with a short suggestion: what it shows, how to run it, where the output appears, and what it shows today.
- Answering every cold-read "Missing" item added tips like "to see a real stub, look up a dialog after closing it," which assume context the reader lacks. Answer only what a medium-familiarity developer couldn't work out; leave routine how-to to them.
- A draft turned a logging method's name into a prose term for success messages because that is what the code calls them. The cold read can't catch this, since the reader doesn't know the team's vocabulary. Use plain words the team uses, and keep code names in backticks.
- "Tests call the `PageHelpers.js` loading waits" read like a typo. Compressed noun phrases ("loading waits," "page wrappers") should be spelled out as what the thing does.
- Turning an action into a noun ("whether the load has to finish") read badly, and collided with a domain term that means something else. Check domain vocabulary before using a common word loosely; record such words in LessonsLearned.md.
- Stories kept referring to things before introducing them ("the attached `x.txt` lists...", "the six helper functions..."). The skill's own template taught "the attached"; it now says "a script ... is attached as" first, and lint fails on "the attached."
- "Test logs can be trusted" passed lint and the cold read but could be read as a task ("test that logs can be trusted") and didn't say who trusts them. Added the ambiguity audit as a third gate. On its first run it flagged that sentence plus 18 others, mostly real: words with a second meaning ("say," "shows," "stops"), references to things never named ("both problems"), and examples attached to the wrong noun.

---

## Audit Rewrites Leaked Backstory (September 2026)

A story said "many calls still pass the two arguments in the old order, from before they were swapped." The swap was an old commit found in git history; a developer picking up the story would not know about it. The sentence was written while fixing an ambiguity-audit flag, and the skill only reran lint after audit rewrites, so no cold reader saw it. Fixes made to the skill:
- SKILL.md Audience: describe the code as it is today, not how it got that way; history goes in only when it changes what the developer must do, stated fully with an ID.
- Audit rewrites and later edits rerun lint, and a new cold read when the rewrite adds a claim.
- COLD_READ.md asks the reader to flag sentences that rely on history or other work they weren't told about.
- Lint warns on backstory wording ("from before," "used to," "no longer," "was swapped/changed").

Also: a LessonsLearned tip that suggested replacement wording ("say 'swapped' instead of 'argument order'") steered the rewrite into backstory. When a lesson suggests replacement wording, make it describe the current state.

## Gate Answers Inflated an XS Story to Standard (September 2026)

The same swapped-arguments story was drafted as Standard because fixing it made about 60 existing checks slower, which was treated as a design decision. Four gate runs then each added sentences answering cold-read questions (a default argument value, a constant's value, why files were excluded). The user pointed out that the subject and the problem were enough. It was rewritten as XS at about 95 words. Changes: a side effect the developer will hit anyway doesn't raise the tier; gate findings are fixed by cutting or rewording first; values readable in the code aren't added; a cold-read rerun is only required when a rewrite adds a claim. Also, scope an evidence script to the story's scope so the story doesn't need exclusion sentences.

## Ambiguity Audit Volume on Large Stories (September 2026)

On a Large story the audit flagged 22 sentences after the cold read was resolved, mostly real: pronouns with several possible antecedents, instructions written in present tense that read as current behavior ("The handler checks only the APIs on the list"), and "can't see" in a story about visibility checks. Write each change as an instruction ("Change the handler to check..."), name the subject instead of "it" when two things were just mentioned, and avoid sense words (see, show, look) in stories about visibility. Subagents also inherit the workspace's instruction files, so a gate answer may start with unrelated preamble; ignore it rather than adding anything to the handoff.

## Check That a Story Is Still Needed Before Rewriting It (September 2026)

Two stories were removed instead of rewritten. One described a weak assertion, but a later check in the same test (a window the app opens only after a successful save) already failed on the case the story worried about; trace the whole path from action to result, not just the assertion the story names. The other story's whole fix had been folded into a sibling story when its "blocked by" link was dropped. When removing a dependency between stories, check whether the dependency's story still has anything left to do.

## Linking Two Interdependent Stories Created in the Same Batch

When creating two (or more) stories in the same session where one blocks the other, neither will have a real Azure DevOps number yet. Use the companion story's title plus its markdown filename in "Blocked By" (e.g. `Companion story: "Title" (work-items/slug.md) — link the real story number once created in Azure DevOps`) instead of leaving a placeholder like `Story #[NUMBER]`. This keeps the dependency traceable for whoever files the stories, and is a cleaner pattern than guessing or omitting the link.

## Cold Read Drove a Refactor Story to 1,100 Words (October 2026)

A refactor story whose purpose was "what's wrong today, the new structure, and how it helps developers" failed five cold reads in a row. Each round asked for more domain rules (definitions of domain concepts, the difference between two similar-sounding settings, each list's exact sequence), and answering them grew the body from about 550 to 1,128 words against a 500 goal. The user said nobody would read a story that long and that the story had drifted: a refactor story doesn't need to teach the domain, because regression suites guard the behavior. Changes made to the skill: after three failed cold reads with significant growth, stop and go back to the user; first check whether the story has drifted from its purpose; with the user's agreement, keep the story near the word goal and add a `## Kickoff Conversation` section listing whom to talk to and the open questions. Lint accepts that section with a warning.

## When to Append an Entry

Only append if something was harder than expected or revealed a universal process pattern not already captured in SKILL.md. If the session went smoothly, skip the update. Do not record codebase-specific patterns here — those belong in `LessonsLearned.md`.

## Batch of Many Related Stories: Shared Context First (October 2026)

*(Superseded by "Current State and Goal Carry the Briefing": the cold reader now knows the repository and team vocabulary, so team-standard terms are not defined in each story. The two-clause review rule and the gate-handling notes below still apply.)*

Nineteen stories were drafted in one pass from one investigation. The first cold-read round failed 10 of 11 stories on the same gaps: an undefined enum/code value, undefined shared terms (a test job's nickname, a team name for reference data), an unexplained tool from a companion story, and no rule for judging regenerated expected output. Each story is read alone, so shared context has to be repeated in every story. Before drafting a batch, write a short reusable block (terms, code values, the review rule for changed output) and paste it into each story; it costs ~40 words per story and saves a whole gate round.

Two further lessons from the same batch:
- "Accept X only when the list explains it; otherwise the pull request needs a reason" reads as self-contradictory to cold readers. Write it as two clauses: what a reviewer can accept, and what must happen first for anything else.
- Ambiguity auditors may read the draft file directly (exact text, less pasting); cold readers have no tools, so their draft must be pasted. After a story fails three cold reads, ask the user before going on. Here they chose to trim two stories near the word goal and add a Kickoff Conversation, and to accept small final fixes on two others without a fourth read.

## Current State and Goal Carry the Briefing (October 2026)

Team feedback on a 19-story batch: a reader picking up a story needs three things, with the least information: the current state of the system (or the problem or relevance), the intended state at a high level, and where the work is. Backing Content usually had more detail than needed (averaging ~130 words against an 80 goal), and every Goal was a single sentence of benefit that didn't state the task, so readers had to dig through Details to learn what to do.

Changes made to the skill:
- Standard and Large stories open with **Current State** (2-3 sentences, today) and **Goal** (2-3 sentences, objective and intent), written with the same framing as a before and after. A reader who stops after the Goal should understand what the work is and why.
- Backing Content became optional and moved after the Goal, for short area background only.
- Details holds where the work is (paths, classes), the mechanism, edge cases, constraints, developer decisions, and full site lists.
- The cold reader now plays a team developer who knows the repository and its tooling but not its domain rules. A stranger persona kept demanding definitions of team-standard terms and inflated every Backing Content. A new first question checks that the objective is clear from Current State and Goal alone.
- Lint checks the new section order, warns when Current State or Goal is outside 2-3 sentences, and warns when the Goal names a file path.

The brief now uses a Current State / Goal pair in place of the "When X, Y happens because Z" spine.


## Current State / Goal Restructure: First Cold Reads (October 2026)
- After converting drafts to Current State → Goal → Details and removing team-term definitions, three stories that had each needed several cold-read rounds in the old shape (one Standard, two Large) passed on the first run. Each reader stated the objective from Current State and Goal alone.
- Most findings that remained came from the ambiguity audit and were wording-level: pronouns ("them", "that run", "both") and forward references ("under the same rule as..."). Fix those with a direct noun, not added background.
- If an AC describes a check that needs a temporary edit, such as "with X changed, tests still pass", say whether that edit is reverted or committed by another story.

## Strong Current State/Goal Means Thin Details; Don't Fall Back on Kickoff (October 2026)
- User feedback on a Standard story: once Current State and Goal clearly frame the work, Details only needs the locations to change and brief guidance (one short decision rule for the tricky case). A 448-word draft with a Kickoff Conversation was cut to 257 words with no Kickoff, and the user preferred it.
- Answering every cold-read gap with more Details text bloats a story the Goal already explains. Before adding to Details, check whether the gap is already answered by Current State or Goal, or is a routine call the developer can make.
- Don't add a Kickoff Conversation just because questions remain. Keep it for stories whose objective stays unclear after Current State and Goal; it should not stand in for routine judgment a developer makes.

## Publishing Must Upload the Attachments the Story Mentions (October 2026)
- Stories were published with "a list … is attached as X" while no file was attached in Azure DevOps. When publishing, upload each file the body names (POST `_apis/wit/attachments?fileName=`, then add an `AttachedFile` relation), and include the attachment count in the read-back check.
- Don't copy one blanket sentence into many stories (for example, "differences are expected"). Check that the claim fits each story's tests; a shared sentence spreads one wrong assumption everywhere.

## Trace the Path Before Telling a Developer to Copy It (October 2026)
- A CI story said "base the new workflow on X". X only called a shared workflow that the same story was changing to exclude the tests the new workflow had to run. Before writing "base it on" or "copy from", trace what the source actually runs, and check that the story's other changes don't break that path.
- For each test a story says to update or leave alone, check in the code what kind of behavior it actually exercises (for example, a core calculation versus only a data migration), and label it that way in the story. Cold readers repeatedly could not apply an update-or-investigate rule to an unlabeled list of tests.
