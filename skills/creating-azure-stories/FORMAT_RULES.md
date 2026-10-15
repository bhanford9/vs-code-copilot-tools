# Azure Story Format Rules

Rules for each section, plus the length goals and structural requirements the lint script checks. SKILL.md explains the reasoning.

## Title
- Aim for 4-8 words for XS, 4-10 otherwise; clarity matters more than the count.
- Starts with a verb and names the change: "Remove the unused retry helper", not "Retry helper cleanup considerations".

## Blocked By (Standard and Large)
- `Story #ID: title` for each real blocker, or `None`.
- Only true prerequisites. Do not describe coordination or merge order here.

## Backing Content (Standard and Large)
- What the subject is, in one plain sentence, then a concise statement of why it needs to change. "It doesn't handle X well" is often enough.
- Aim for 80 words. Exceed that goal when needed for a clear introduction and clean transitions. The mechanism (why it happens) goes in Details; backstory, related stories, and how the problem was found go nowhere or in an attachment.
- Describe the need as what someone sees, not how the code produces it.

## Goal (Standard and Large)
- One sentence on the benefit: what should be better once this is done, in general terms. The reader wants to know why the work is worth doing.
- State where we are trying to go, not where we are: "Tests should cope with slow-loading screens," not "Tests cope with slow-loading screens." The current state belongs in Backing Content.
- Not what the code or tests will do: "Reports should stay correct when users filter by date" rather than "The filter includes the end date," and "Tests should cope with slow-loading screens" rather than "Tests can require a load to finish."

## Details (Standard and Large)
- Where: file paths and function names.
- What: the change as a concept or short pseudocode.
- A current-code excerpt only if it shows the problem faster than prose.
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
| Backing Content word goal | n/a | 80 | 80 |
| Code blocks | 2 | 2 | 2 |
| Lines per code block | 6 | 6 | 6 |
| Acceptance criteria | 2-3 | 3-5 | 3-5 |
| Sections | Acceptance Criteria only | The five standard sections | The five standard sections |

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
