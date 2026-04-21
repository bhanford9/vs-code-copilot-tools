# LessonsLearned.GLOBAL.md — read-knowledge-docs

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

> Both entries that previously lived here have been promoted into the SKILL.md body (Step 1 dual-context intake behavior and the explicit intake gate pattern). No entries remain. Add new entries below when something hard, slow, or surprising occurs in a session.

---

## Loading read-knowledge-docs Without create-knowledge-docs Is Incomplete for Update Sessions

Category: Process/Model

When asked to update or extend an existing knowledge base, this skill was loaded (correctly) to understand current doc content — but `create-knowledge-docs` was NOT loaded. `create-knowledge-docs` defines the structural writing conventions (YAML front matter, heading style, TODO placement, cross-reference syntax) that must be followed when adding content. Reading without those conventions in scope led to additions that may not fully conform to the established style.

- DO treat `read-knowledge-docs` + `create-knowledge-docs` as a paired set whenever the goal is to update existing knowledge-base docs.
- `read-knowledge-docs` alone is sufficient only for pure read/research sessions with no intent to write.
- When in doubt whether you are "just reading" or "reading before writing," load both.
