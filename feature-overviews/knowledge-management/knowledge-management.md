# Knowledge Management

A suite of four skills and one sub-agent for building, maintaining, and querying a formal, AI-indexed architecture knowledge base per workspace. Sessions contribute new findings to a shared corpus; future sessions retrieve them surgically without re-discovering what's already known.

## The Problem It Solves

Every coding session generates knowledge that doesn't survive the conversation: a behavioral contract the user explained in passing, a counterintuitive pattern found only after searching through a dozen files, a domain concept that exists only in someone's head. Without a capture-and-retrieval mechanism, that knowledge evaporates — and every future session rediscovers it at full cost.

The Knowledge Management suite treats session knowledge as an asset with a lifecycle. Knowledge is captured immediately after sessions, written in a format optimized for AI retrieval, stored in a machine-local registry that any skill can look up, and queried surgically when future sessions need it. Over time, the knowledge base compounds: every session — debugging, code review, investigation spike — contributes, and every query costs less than a manual re-search would.

## How It Works

The system has four phases. The first runs once per machine; the other three recur throughout the life of the workspace.

```
configure-docs     →    create-knowledge-docs    →    /harvest    →    @KnowledgeDocsResearcher
(once per machine)      (initial setup or            (after every       (any time a question
                         major additions)             learning           needs an answer)
                                                      session)
```

**Configure — `configure-docs` skill**  
Before documentation can be written or read, the system needs to know where the knowledge base lives. `configure-docs` resolves this from `workspace-docs.json` — a machine-local file that maps workspace root paths to their documentation directories. It is gitignored, unique to each machine, and managed exclusively by this skill.

Every other documentation-aware skill delegates to `configure-docs` for the path — they never ask the user directly. The first time any documentation skill runs in an unconfigured workspace, `configure-docs` surfaces a one-time setup prompt. If the user opts out (`DOCS_DISABLED`), all automated skills skip silently. This self-bootstrapping behavior means there is no required onboarding step for new cloners — the system handles first-time configuration on demand.

**Build — `create-knowledge-docs` skill**  
Takes any source material — transcripts, code, interviews, wikis — and produces a structured, AI-indexed knowledge base. The format is opinionated by design: YAML front matter on every file (for tag scanning without reading content), a single-sentence abstract after each H1 (for one-read relevance checks), semantic H2/H3 headings (for structure-only scanning), a `See Also` section on every file (for graph traversal), and a root glossary (for terminology lookup).

These conventions serve two audiences simultaneously: a human reading for orientation and an AI agent retrieving targeted information. The structural choices are not style preferences — they are what make the retrieval step efficient.

**Harvest — `session-knowledge-harvest` skill**  
Run at the end of any session where meaningful knowledge was gained. The skill mines the conversation for documentable discoveries using six extraction prompts — targeting corrections made during the session, high-search-cost findings, counterintuitive code patterns, cross-file conventions, user-explained concepts, and resolved documentation TODOs. It classifies each finding (domain rule, behavioral contract, coding agent trap, glossary term), delegates gap-checking to `KnowledgeDocsResearcher` to verify what's already documented, and produces a documentation plan before writing anything.

The harvest step is enforced as always-on behavior: `general-agent-behavior.instructions.md` requires invoking it at the end of any session where architectural or domain knowledge was gained. This makes knowledge capture a behavioral baseline rather than an optional step.

**Query — `read-knowledge-docs` skill and `KnowledgeDocsResearcher` agent**  
Retrieves targeted information from the knowledge base without reading full files. The skill uses YAML tag scanning, filename patterns, the README reading-order table, and abstract-first reading to reach the relevant section directly. The preferred invocation is via the `KnowledgeDocsResearcher` sub-agent — research runs in an isolated context, keeping main-conversation context clean. The agent returns a cited findings report: what was found, which file and section it came from, and any known documentation gaps on the topic.

`KnowledgeDocsResearcher` is also used internally by the harvest skill for gap-checking — confirming what is already documented before writing additions. This prevents duplicates and ensures every new entry is genuinely net-new knowledge.

## Entry Points

| Invoke | When |
|--------|------|
| `/harvest` | End of any session where domain or architectural knowledge was gained |
| `/configure-docs` | First-time setup, changing the docs directory, or toggling opt-out |
| `@KnowledgeDocsResearcher` | Answering a specific question from the knowledge base without reading full files |
| Mention `create-knowledge-docs` | Building a new knowledge base or adding major documentation from source material |

## Reference Files

| File | Role |
|------|------|
| [`skills/session-knowledge-harvest/SKILL.md`](../../skills/session-knowledge-harvest/SKILL.md) | Seven-phase harvest workflow: extract, classify, gap-check, plan, write, cross-reference, lessons learned |
| [`skills/configure-docs/SKILL.md`](../../skills/configure-docs/SKILL.md) | Workspace docs lookup procedure, config schema, and branch actions for unconfigured and opted-out workspaces |
| [`skills/create-knowledge-docs/SKILL.md`](../../skills/create-knowledge-docs/SKILL.md) | Structural standards for AI-indexed docs: YAML front matter, document template, heading rules, glossary conventions |
| [`skills/read-knowledge-docs/SKILL.md`](../../skills/read-knowledge-docs/SKILL.md) | Surgical retrieval workflow: YAML tag scanning, abstract-first reading, cross-reference traversal, gap reporting |
| [`agents/KnowledgeDocsResearcher.agent.md`](../../agents/KnowledgeDocsResearcher.agent.md) | Sub-agent that runs research in isolated context and returns a cited findings report |
| `~/Repos/vs-code-copilot-tools/workspace-docs.json` | Machine-local config mapping workspace paths to documentation directories (gitignored, managed by `configure-docs`) |
| [`instructions/general-agent-behavior.instructions.md`](../../instructions/general-agent-behavior.instructions.md) | Always-on instruction that enforces harvest invocation at session end |
