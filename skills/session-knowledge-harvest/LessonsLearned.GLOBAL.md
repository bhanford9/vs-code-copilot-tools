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

The most useful thing this skill can produce is a specific, actionable warning callout in the right place. Generic warnings ("be careful with equality") have low value. Specific warnings ("do not use hash-code comparison as the final Equals answer; always follow with field comparison — see sibling classes LoadCategoryKey and ControllingLoadCombinationKey for the correct pattern") are what prevent future agent mistakes.

Evaluate each ⚠️ callout: could an agent read it and immediately know what NOT to do and what to do instead? If not, make it more specific.

---

## Determinism Pattern for Harvest Reinforcement (2026-04-22)

### Viable Pattern: Instructions File + Prompt File

Category: Process/Model

The reliable way to make harvest happen more consistently across sessions is two layers:

1. **Always-on instructions** — add the harvest rule to `general-agent-behavior.instructions.md` (`applyTo: "**"`). This file is in-context on every turn, giving the agent persistent awareness of the expectation throughout the session, not just at the end.
2. **Prompt file** — `prompts/harvest.prompt.md` gives the user a zero-friction one-click trigger when they want to run the skill explicitly.

### VS Code Stop Hook Was Tried and Rejected

A `Stop` lifecycle hook was implemented to post a `systemMessage` reminder at session end. It was removed because:
- `Stop` fires unconditionally on every session end — trivial sessions included
- The `Stop` input carries only `stop_hook_active`; no transcript, tool-use count, or file-edit count is available to filter on
- The result was noisy and may have interfered with normal session termination

Do not re-recommend a hook-based approach unless VS Code ships a `Stop` input field that includes session activity metadata.

---

## Instructions File Loading Does Not Guarantee Compliance (2026-04-23)

Category: Process/Model

Confirmed via session debug log: `general-agent-behavior.instructions.md` loaded successfully as "General Agent Behavior" (`Resolved 3 instructions in 76.6ms | loaded: [CSharp Diagnostics, CSharp Test Conventions, General Agent Behavior]`). The rule "MUST invoke session-knowledge-harvest at the end of any session where architectural knowledge was discovered" was in-context throughout the session. The agent still did not proactively trigger the harvest — the user had to ask for it.

- Loading ≠ compliance. The instruction was present; the model deprioritized it at session end.
- The two-layer pattern (instructions + prompt file) remains the best available mitigation — but it is not a guarantee.
- The current enforcement gap: the harvest instruction fires at "session end," but the model does not have a reliable internal signal for when a session is ending vs. merely pausing.
- **Watch for this pattern**: if the user completes the primary task (e.g., a code review), ends their request with something conclusory ("well done"), and no explicit harvest has occurred — proactively offer it. Don't wait for the user to ask "were there any documentation-related things?"

---

## Planning Sessions Are High-Value Harvest Targets (2026-05-13)

Category: Process/Model

When a session is pure planning-doc authorship (no codebase search, no debugging), the standard extraction prompts ("counterintuitive code," "high search-cost discoveries") yield nothing — but the session still produces high-value knowledge. The value comes from design decisions crystallized while writing step-by-step checklists: behavioral contracts, service layer boundaries, deferred migrations, and ephemeral token patterns.

**Observation:** Writing a detailed checklist forces resolution of design ambiguities. Those resolutions (e.g., "derived status — never stored," "MachineToken is ephemeral, nulled after use," "CopilotAgentDispatchStrategy lives in CLI not Core") are precisely the coding agent traps that belong in the architecture docs.

**Lesson:** For planning sessions, the extraction prompt to use is: "What design decisions were made while writing these step files that a future coding agent would get wrong without documentation?" Apply the scope gate to those items.

## Knowledge Document Style: "Why" Not "How" (2026-05-13)

Category: Process/Model

The first attempt at a TaskTracker architecture document was rejected because it was organized around implementation steps (1–11) and described *how* each component works mechanically. The correct form is different:

**Wrong:** Organized by step / component. Describes what each thing does. Technical spec feel.

**Correct:** Organized by domain concept. Explains *why* the system is designed the way it is. Requirements-rationale feel. A future agent reads it to understand the intent so it can make decisions that preserve that intent — not just to understand the code.

### The Document Structure That Works

Each document in the knowledge base should answer these questions, in order:
1. **What is this concept?** — Domain definition, not code description
2. **Why does it exist?** — The requirement or domain problem it solves
3. **What are the rules?** — Behavioral constraints expressed as requirements, not code
4. **What must a coding agent know?** — The non-obvious constraints not derivable from reading the code

### The Folder/File Structure That Works (from JEDI V2 reference)

- `README.md` at root with a **reading order table** that includes a **"Read When..."** column — this is critical for token efficiency; an agent can scan it and open only the doc it needs
- Numbered files (`01-`, `02-`) for navigation order
- Topic with sub-topics becomes a folder with `00-overview.md` and numbered children
- `glossary.md` at root, linked from every doc
- YAML front matter: `tags`, `category`, `related` — enables lookup without full-file reads
- Abstract blockquote immediately under H1: one sentence of "what this is and why it matters"
- `📝 TODO` for documented gaps rather than omitting them

### The ⚠️ Callout Still Belongs — But Inside "Why" Docs

The `⚠️ Coding agent note:` callout from the previous pattern remains valid and valuable. The difference is context: in the old approach they appeared in a tech-spec doc; in the new approach they appear inside a "why does this rule exist?" section, which makes them more trustworthy and actionable.

---

## Lessons Learned Files Must Live Next to the Skill (2026-04-25)

Category: Process/Model

An agent wrote harvest session findings to `/memories/repo/session-knowledge-harvest-lessons.md` (a repo memory file) instead of the skill's own `LessonsLearned.md`. This defeats the feedback loop entirely — the file is invisible to the skill's "read before starting" step and doesn't benefit future sessions.

**Rule**: All lessons for this skill go to `c:\Users\bmhanford\Repos\copilot-configs\skills\session-knowledge-harvest\LessonsLearned.md` (codebase-specific) or `LessonsLearned.GLOBAL.md` (process/model). Never use a memory file as a substitute. The lessons-learned SKILL.md already defines this — the agent must not improvise an alternative location.
