# LessonsLearned.GLOBAL.md — session-knowledge-harvest

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## Seeded Knowledge

### The Scope Gate Is the Hardest Step to Apply Consistently

Category: Process/Model

The most common failure mode of this skill will be documenting too much — adding HOW content, implementation details, or things obvious from the code. The scope gate question ("Would a coding agent benefit from this AND be unlikely to find it from the code?") must be applied item by item, not as a general sentiment.

When in doubt, err toward discarding. A knowledge base that grows with low-value entries degrades faster than one that stays lean.

### The ⚠️ Coding Agent Trap Callout Is the Highest-Value Output

Category: Process/Model

The most useful thing this skill can produce is a specific, actionable warning callout in the right place. Generic warnings ("be careful with equality") have low value. Specific warnings ("do not use hash-code comparison as the final Equals answer; always follow with field comparison — see sibling classes implementing the same pattern for the correct form") are what prevent future agent mistakes.

Evaluate each ⚠️ callout: could an agent read it and immediately know what NOT to do and what to do instead? If not, make it more specific.

---

## Determinism Pattern for Harvest Reinforcement (2026-04-22)

### Viable Pattern: Instructions File + Prompt File

Category: Process/Model

The reliable way to make harvest happen more consistently across sessions is two layers:

1. **Always-on instructions** — add the harvest rule to an always-on instructions file (one with `applyTo: "**"`). This file is in-context on every turn, giving the agent persistent awareness of the expectation throughout the session, not just at the end.
2. **Prompt file** — a `harvest.prompt.md` prompt file gives the user a zero-friction one-click trigger when they want to run the skill explicitly.

### VS Code Stop Hook Was Tried and Rejected

A `Stop` lifecycle hook was implemented to post a `systemMessage` reminder at session end. It was removed because:
- `Stop` fires unconditionally on every session end — trivial sessions included
- The `Stop` input carries only `stop_hook_active`; no transcript, tool-use count, or file-edit count is available to filter on
- The result was noisy and may have interfered with normal session termination

---

## Instructions File Loading Does Not Guarantee Compliance (2026-04-23)

Category: Process/Model

Confirmed via session observation: an always-on instructions file can load and be in-context throughout an entire session, and the agent will still not proactively trigger the harvest at the end. The rule was present; the model deprioritized it at session end — the user had to ask.

- Loading ≠ compliance. The instruction was present; the model deprioritized it at session end.
- The two-layer pattern (instructions + prompt file) remains the best available mitigation — but it is not a guarantee.
- The current enforcement gap: the harvest instruction fires at "session end," but the model does not have a reliable internal signal for when a session is ending vs. merely pausing.
- **Watch for this pattern**: if the user completes the primary task (e.g., a code review), ends their request with something conclusory ("well done"), and no explicit harvest has occurred — proactively offer it. Don't wait for the user to ask "were there any documentation-related things?"

---

## Flat-File vs. Folder Ambiguity in Expanded Knowledge Bases (2026-05-20)

Category: Process/Model

When a knowledge base evolves from flat files to folder-based sub-sections, both the old flat `.md` file and the new folder (with `00-overview.md`) may coexist. They drift over time. The flat file often appears first in search results, causing incorrect insertion targets.

**Rule:** Before inserting a new section, check `README.md`'s reading order table. The canonical file is whichever path appears there. If a same-named flat file exists alongside a folder, the flat file is an artifact — insert into the folder's `00-overview.md`.

**Cross-reference check add-on:** After inserting, verify all generated links use the canonical path, not the flat file path.

---

## Planning Sessions Are High-Value Harvest Targets (2026-05-13)

Category: Process/Model

When a session is pure planning-doc authorship (no codebase search, no debugging), the standard extraction prompts ("counterintuitive code," "high search-cost discoveries") yield nothing — but the session still produces high-value knowledge. The value comes from design decisions crystallized while writing step-by-step checklists: behavioral contracts, service layer boundaries, deferred migrations, and ephemeral token patterns.

**Observation:** Writing a detailed checklist forces resolution of design ambiguities. Those resolutions (e.g., "derived property — never stored," "TokenX is ephemeral, nulled after use," "ServiceA belongs in LayerX not LayerY") are precisely the coding agent traps that belong in the architecture docs.

---

## Integration Tests Are the Best Documentation Auditor (2026-05-27)

Category: Process/Model

When integration tests fail in ways that don't match what architecture docs describe, the code is the ground truth — the docs are describing an outdated design. This pattern appeared clearly: planning-spec docs described a different gate chain than what was actually implemented.

**Rule for harvest:** When integration tests reveal a concrete implementation detail that contradicts existing architecture docs, that contradiction is a MANDATORY harvest item — not just a documentation update, but evidence that the docs were never updated after implementation.

**Watch for:** Architecture docs written from planning notes or step-file checklists (not from reading production code). These have the highest likelihood of describing a design that was modified during implementation. Treat them as "documentation debt" until verified against actual code during a real coding session.

**Practical impact:** The documented "gate order" or "layer names" in a planning doc may be completely different from what actual gate implementations enforce. Reading the DI registration order and the gate `Name` properties gives the authoritative truth.

**Lesson:** For planning sessions, the extraction prompt to use is: "What design decisions were made while writing these step files that a future coding agent would get wrong without documentation?" Apply the scope gate to those items.

---

## Lessons Learned Files Must Live Next to the Skill (2026-04-25)

Category: Process/Model

An agent wrote harvest session findings to `/memories/repo/session-knowledge-harvest-lessons.md` (a repo memory file) instead of the skill's own `LessonsLearned.md`. This defeats the feedback loop entirely — the file is invisible to the skill's "read before starting" step and doesn't benefit future sessions.

**Rule**: All lessons for this skill go to the skill's own `LessonsLearned.md` (codebase-specific) or `LessonsLearned.GLOBAL.md` (process/model), both located in the skill directory. Never use a memory file as a substitute. The lessons-learned SKILL.md already defines this — the agent must not improvise an alternative location.
