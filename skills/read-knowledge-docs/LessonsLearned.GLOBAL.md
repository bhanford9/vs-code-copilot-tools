# LessonsLearned.GLOBAL.md — read-knowledge-docs

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## Skills That Require Input Paths Must Have an Explicit Intake Gate

Category: Process/Model

The first version of this skill had no Step 1 Intake. It jumped straight to query framing and included a "try to find the docs folder" fallback in the discovery step. The user had to point out that the skill should require the knowledge base path up front, mirroring the `create-knowledge-docs` pattern.

- Any skill that operates on a specific artifact (a docs folder, a file, a repo path) must gate execution in Step 1 on having that path confirmed before touching anything.
- Do not include workspace-scanning fallbacks as a substitute for intake — they silently accept bad preconditions.

## Skills Invokable as Sub-Agents Need Dual-Context Intake Behavior

Category: Process/Model

The intake step was originally written with a single instruction: "STOP and ask the user." This works for direct invocation but breaks when the skill is executed by a sub-agent (e.g., `KnowledgeDocsResearcher` via `runSubagent`) — sub-agents cannot prompt the user.

- When a skill can be used both directly and as a sub-agent, its intake step must have two explicit branches:
  - **Direct invocation**: STOP and ask the user.
  - **Sub-agent invocation**: halt immediately with an error listing what was missing. Do not ask.
- The spawning agent (not the sub-agent) is responsible for collecting missing inputs from the user before invoking the sub-agent.
- The agent file itself should also make this explicit: "If input is missing, halt and return an error."
