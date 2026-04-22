# LessonsLearned.GLOBAL.md — configure-docs

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## Seeded Knowledge

### Skills Are Semantically Discoverable; Prompts Are Not

Category: Process/Model

The Workspace Docs Lookup Procedure was originally written inside `prompts/configure-docs.prompt.md`. This was the wrong location. Agents that find themselves needing to resolve a docs directory cannot discover or invoke a prompt file autonomously — prompts are user-triggered only. Skills are semantically matched by the agent based on description, so an agent in an ambiguous "where do I write docs?" state can find and load this skill without user direction.

Rule: Any procedure that an agent might need to invoke autonomously belongs in a skill, not a prompt. Prompts are entry points for users, not agents.

### Prompt File Is a Thin Wrapper; All Logic Lives Here

Category: Process/Model

`prompts/configure-docs.prompt.md` exists as a one-liner that routes to this skill. It gives users a named entry point in the prompt picker. The prompt contains no logic — all procedure, schema, and branch rules live here in the skill. If logic needs to change, change only this SKILL.md.

### Path Normalization Must Be Explicit

Category: Process/Model

Windows paths are case-insensitive, but string key lookups in JSON are case-sensitive. A workspace key of `C:\Repos\MyApp` will not match `c:/repos/myapp`. The normalization rules (lowercase + forward slashes + no trailing slash) must be applied consistently at both write time and lookup time. If a mismatch is suspected, dump the `workspaces` keys and compare against the normalized `cwd` character by character.
