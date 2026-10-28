# Azure Story Format Rules

Rules for each section, plus the length goals and structural requirements the lint script checks. SKILL.md explains the reasoning.

## Title
- Aim for 4-8 words for XS, 4-10 otherwise; clarity matters more than the count.
- Starts with a verb and names the change: "Remove the unused retry helper", not "Retry helper cleanup considerations".

## Blocked By (Standard and Large)
- `Story #ID: title` for each real blocker, or `None`.
- Only true prerequisites. Do not describe coordination or merge order here.

## Current State (Standard and Large)
- Answers: where does the system stand today, for the part this work touches? 2-3 sentences, framed and worded like the Goal so the two read as a before and after.
- Describe what is true now: the behavior, data, or limitation, plus the problem or relevance if it isn't obvious from that. No mechanism and no backstory.
- Example: "The order list's date-range filter leaves out orders placed on the end date. Monthly totals built from it come up short, and support has had three reports this month."

## Goal (Standard and Large)
- Answers: what is the objective of this work, and what is it for? 2-3 sentences at a high level, using the same framing as Current State so the change is clear by contrast.
- State the objective and intent, not steps, file lists, or locations.
- Example: "The date-range filter should include every order placed on the end date. Monthly totals built from the order list should then match the orders actually placed."
- A reader who stops after the Goal should understand what they are doing and why.

## Backing Content (Standard and Large, optional)
- Use it only when the reader needs some short background on the area before Details makes sense, such as a domain rule or how two parts relate. Leave it out when Current State and Goal are enough.
- Aim for 80 words. Background only: no mechanism, backstory, or evidence.

## Details (Standard and Large)
When Current State and Goal carry the briefing, Details is mostly where the work is plus light guidance. Do not restate the objective or re-argue why it matters. Answer each cold-read gap with a shorter Current State or Goal sentence, or a one-line pointer in Details, before adding explanation.
- Where the work is: file paths, class and function names.
- The mechanism (why it happens), with a current-code excerpt only if it shows the problem faster than prose.
- Edge cases, constraints, decisions left to the developer, and full lists of sites.
- What stays the same only if a developer might reasonably change it.
- No step-by-step procedure and no working solution code.
- When there's an attachment, a short paragraph that first says what is attached ("A script that shows the problem is attached as..."), then reads as a suggestion, not a command: how to run it, where the output appears, and what it shows today. Keep it low on detail.

## Acceptance Criteria
- XS: 2-3. Standard and Large: 3-5.
- Each is an observable result that someone other than the author can check.
- Name real tests, pages, or commands rather than feature areas (`OrderFilterTests`, not "order filtering").
- Not process ("code reviewed," "unit tests pass") and not a restatement of the implementation.

## Length Goals and Structural Requirements

Word counts are goals, not caps. The lint script warns when a draft exceeds them, but readability, necessary context, and clean transitions take priority. Do not shorten a connected explanation into fragments or remove bridges between thoughts to meet a count. Structural requirements still fail lint when violated.

| Check | XS | Standard | Large |
|---|---|---|---|
| Body word goal (excluding title, headings, code blocks, criteria) | 120 | 300 | 500 |
| Current State and Goal | n/a | 2-3 sentences each | 2-3 sentences each |
| Backing Content word goal (when present) | n/a | 80 | 80 |
| Code blocks | 2 | 2 | 2 |
| Lines per code block | 6 | 6 | 6 |
| Acceptance criteria | 2-3 | 3-5 | 3-5 |
| Sections | Acceptance Criteria only | Blocked By, Current State, Goal, optional Backing Content, Details, Acceptance Criteria | Same as Standard |

## Wording to Avoid

Fails lint, because it narrates the authoring process or defends the finding:
- "I/we found, verified, confirmed, ran, checked, probed"
- "verified against", "probe", "audit", "source inspection"
- "is not a claim", "this story does not claim", "was not verified"

Warns in lint; reread and usually rewrite:
- Filler: "ensure", "robust", "comprehensive", "leverage", "seamless", "holistic", "it is important to note"
- Abstract jargon when a plain phrase works: "contract", "boundary", "focused", "representative", "preserve existing ..."
- More than three em dashes, or sentences averaging over 25 words
- Backstory the reader can't see: "from before", "used to", "no longer", "originally", "previously", "the old", "was/were swapped/changed/renamed/moved/reordered". Describe the code as it is today.

## Markdown
- H1 title, H2 sections, H3 only inside Large Details.
- No other sections, such as Open Questions or Out of Scope. A choice left to the developer is one sentence in Details. Mention an exclusion only if a developer would reasonably assume it is included, also as one sentence in Details. The one exception is `## Kickoff Conversation`, allowed in Standard and Large stories just before Acceptance Criteria, only when the user agreed to it under SKILL.md's "When the Cold Read Keeps Growing the Story": who to talk to and two to four questions.
- Criteria use `- [ ]`.
- File paths and code names use backticks. No Markdown links; they break in Azure DevOps.
