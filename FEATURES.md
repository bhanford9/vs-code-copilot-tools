# Feature Map

A conceptual index of every tool in this repo. Each entry describes what the tool does from a user perspective, not how it is implemented.

---

## Planning Pipeline

An 8-agent discovery workflow that frontloads uncertainty before committing to implementation. The core philosophy: **discover what you don't know before writing code**. Systematic gap finding and resolution reduces mid-implementation surprises, costly refactors, and requirements drift.

| Invoke | How |
|--------|-----|
| `@InitialPlanner` | Start the pipeline — describe a feature or task |
| `/CreateWorkItems` | Convert a completed plan into Azure DevOps stories |

**Agents involved:** `InitialPlanner` → `GapFinder` → `GapResolver` → `RefinedPlanner` → `ArchitecturalDesigner` → `WorkPlanner` → `@AzureStoryCreation` → `Implementation`

**Common paths:**
- **Exploratory**: InitialPlanner → GapFinder → GapResolver → RefinedPlanner → Implementation
- **Design-First**: InitialPlanner → ArchitecturalDesigner → WorkPlanner → @AzureStoryCreation → Implementation
- **Fast Track**: InitialPlanner → Implementation (simple/well-understood features)

**Detailed docs:** [feature-overviews/planning-pipeline/planning-pipeline.md](feature-overviews/planning-pipeline/planning-pipeline.md) · [Quick Reference](feature-overviews/planning-pipeline/planning-pipeline-quick-reference.md)

**LessonsLearned:** `skills/planning-pipeline/LessonsLearned.md` — read by all pipeline agents at session start, updated after sessions where something notable occurred

---

## Code Review Pipeline

A multi-agent pipeline that runs a structured audit of code changes across seven quality dimensions: requirements, correctness, test coverage, maintainability, testability, performance, and extensibility. Sequential audits establish context; five specialty auditors then run in parallel as subagents. Produces per-dimension reports and a synthesized final review with merge recommendation.

| Invoke | How |
|--------|-----|
| `/PrepareCommitReview` | Create an isolated review branch from a set of commit SHAs |
| `/ReviewLocal` | Review uncommitted local changes |
| `/CleanupCommitReview` | Restore the repo and remove temp branches after review |

**Agents involved:** `REVIEW-CodeReviewOrchestrator` → `REVIEW-RequirementsAuditor` → `REVIEW-CodeCorrectnessAuditor` → `REVIEW-ParallelAuditCoordinator` (spawns 5 parallel auditors) → final synthesis

**LessonsLearned structure:** Each of the 5 parallel auditors and the FinalSynthesizer has its own independent `LessonsLearned.GLOBAL.md` under `skills/code-review-pipeline/lessons-learned/REVIEW-{AgentName}/`. Pipeline-level findings shared by the Orchestrator, Coordinator, RequirementsAuditor, and CorrectnessAuditor live in `skills/code-review-pipeline/LessonsLearned.GLOBAL.md`.

**Detailed docs:** [feature-overviews/code-review-pipeline/code-review-pipeline.md](feature-overviews/code-review-pipeline/code-review-pipeline.md) · [Conventions](feature-overviews/code-review-pipeline/code-review-conventions.md)

---

## Unit Test Writer

An agent that writes comprehensive NUnit unit tests through methodical code and pattern analysis — reads existing test structure, resolves types and interfaces, and never guesses.

| Invoke | How |
|--------|-----|
| `@UnitTestWriter` | Describe the class or method to test |

**Skill:** `writing-csharp-tests` — conventions, common pitfalls, known project helpers

**Overview:** [`feature-overviews/unit-test-writer/unit-test-writer.md`](feature-overviews/unit-test-writer/unit-test-writer.md)

---

## Azure DevOps Story Creation

An agent that produces correctly structured Azure DevOps work items with required sections (Blocked By, Backing Content, Goal, Details, Acceptance Criteria) through codebase research and user collaboration.

| Invoke | How |
|--------|-----|
| `@AzureStoryCreation` | Describe the work or feature needing a story |
| `/CreateWorkItems` | Run from a completed plan |

**Skill:** `creating-azure-stories` — format rules, templates, examples

**Overview:** [`feature-overviews/azure-story-creation/azure-story-creation.md`](feature-overviews/azure-story-creation/azure-story-creation.md)

---

## Copilot Tools Management

Tools for keeping this repo's configuration in sync across machines.

| Invoke | How |
|--------|-----|
| `/update-copilot-tools` | Pull latest, analyze changes, handle follow-up steps |
| `/merge-copilot-settings` | Apply `settings.base.json` on top of local `settings.json` |

**Skills:** `update-copilot-tools`, `merge-copilot-settings`

**Overview:** [`feature-overviews/copilot-tools-management/copilot-tools-management.md`](feature-overviews/copilot-tools-management/copilot-tools-management.md)

---

## Agentic Tools Auditor

An orchestrated audit of all VS Code Copilot agentic tool configurations in the current workspace. Discovers every config item, runs parallel per-item auditors, and synthesizes findings into recommendations.

| Invoke | How |
|--------|-----|
| `@AgenticToolsAuditor` | Run from any workspace to audit its agentic setup |

**Agent:** `individual-auditor` (sub-agent, spawned per config item)
**Skill:** `agentic-tools-auditor`

**Pre-commit cleanup:** After implementing roadmap items, all generated audit artifacts (`AUDIT.md`, `*.AUDIT.md`, `AUDIT-SYNTHESIS.md`, `AUDIT-CONTEXT.md`, `AUDIT-BEFORE-STATE.md`) must be removed before committing. The skill includes a cleanup procedure with the exact commands — always requires explicit user confirmation before deleting.

**Overview:** [`feature-overviews/agentic-tools-auditor/agentic-tools-auditor.md`](feature-overviews/agentic-tools-auditor/agentic-tools-auditor.md)

---

## C# Development Assistance

Auto-attached rules and skills that improve C# coding workflows without requiring explicit invocation.

| What | Description |
|------|-------------|
| C# error checking | Always uses the "Check Changed Files" VS Code task — never `dotnet build` or `get_errors` |
| C# test conventions | NUnit naming patterns, Moq mocking conventions, parameterized test guidance |

**Instructions:** `csharp-diagnostics.instructions.md`, `csharp-tests.instructions.md` (auto-applied to `*.cs` files)
**Skills:** `checking-csharp-errors`, `writing-csharp-tests`

**Overview:** [`feature-overviews/csharp-development/csharp-development.md`](feature-overviews/csharp-development/csharp-development.md)

---

## Always-On Instructions

Instruction files that auto-apply to matching sessions without any invocation.

| File | Applies To | What It Does |
|------|------------|--------------|
| `general-agent-behavior.instructions.md` | `**` (all files) | Requires an Ambiguity Scan before acting on any non-trivial request; requires invoking `session-knowledge-harvest` at the end of any session where architectural or domain knowledge was gained |
| `csharp-diagnostics.instructions.md` | `**/*.cs` | Enforces the "Check Changed Files" VS Code task for error checking — never `dotnet build` or `get_errors` |
| `csharp-tests.instructions.md` | `**/*Tests.cs` | Injects baseline NUnit test conventions: naming pattern, no comments, Moq Verifiable, `[TestCase]` |

**Note:** The `session-knowledge-harvest` requirement is enforced by policy here but invoked via `/harvest` — see [Knowledge Management](#knowledge-management).

**Overview:** [`feature-overviews/always-on-instructions/always-on-instructions.md`](feature-overviews/always-on-instructions/always-on-instructions.md)

---

## Hooks

Small pre/post-turn scripts that run automatically during agent sessions.

| Hook | Trigger | Scope | What It Does |
|------|---------|-------|--------------|
| `ensure-freeform` | PreToolUse | Global (`hooks/ensure-freeform.json`) | Blocks agent sessions from locking into a rigid tool-use pattern; preserves freeform reasoning |
| `test-no-comments` | PostToolUse | Global (`hooks/test-no-comments.json`) | Checks that newly written test code doesn't contain comments (enforces commenting conventions) |
| `block-devops-fetch` | PreToolUse | Agent-scoped (inline in `REVIEW-RequirementsAuditor.agent.md`) | Prevents the Requirements Auditor from making external API/DevOps fetch calls during review |
| `check-auditor-output` | SubagentStop | Agent-scoped (inline in `REVIEW-ParallelAuditCoordinator.agent.md`) | Verifies each parallel code review auditor produced its expected output file |

**Overview:** [`feature-overviews/hooks/hooks.md`](feature-overviews/hooks/hooks.md)

---

## Lessons Learned System

A feedback loop built into every skill and agent workflow. After completing a session, the agent reflects on what was hard or surprising and appends findings to a `LessonsLearned.md` file alongside the relevant skill. Future sessions read it first to avoid repeating mistakes.

> **Scope:** Per-skill and per-agent feedback loops that keep individual workflows from repeating mistakes. For building a formal, AI-indexed architecture knowledge base per workspace, see [Knowledge Management](#knowledge-management).

| Invoke | How |
|--------|-----|
| `/fork-and-improve` | Capture a mid-session course correction — apply the config fix and write a LessonsLearned entry while context is fresh |
| `/review-lessons` | Scan all LessonsLearned files, identify escalation candidates (promote to SKILL.md or convert to hook), and surface a prioritized action list |

**Skills:** `lessons-learned`, `review-lessons`

**Overview:** [`feature-overviews/lessons-learned-system/lessons-learned-system.md`](feature-overviews/lessons-learned-system/lessons-learned-system.md)

---

## Knowledge Management

A suite of skills and prompts for building, reading, and maintaining a formal architecture knowledge base per workspace. Designed to be self-bootstrapping — a new cloner gets prompted to configure their docs directory on first use.

> **Scope:** Formal, AI-indexed architecture documentation per workspace. For per-skill feedback loops that keep agent workflows from repeating mistakes, see [Lessons Learned System](#lessons-learned-system).

| Invoke | How |
|--------|-----|
| `/harvest` | Run the session knowledge harvest at the end of a session |
| `/configure-docs` | Set or change the documentation directory for the current workspace, or opt out |
| `@KnowledgeDocsResearcher` | Answer a specific question from the knowledge base without reading entire files |

**Skills:**
- `session-knowledge-harvest` — mines a session for documentable knowledge (business rules, behavioral contracts, coding agent traps) and integrates findings into the formal knowledge base
- `configure-docs` — resolves the documentation directory for the current workspace from machine-local config (`workspace-docs.json`); handles first-time setup, opt-out (`DOCS_DISABLED`), and path changes; semantically discoverable by agents that need a docs path
- `create-knowledge-docs` — builds or extends a structured, AI-indexable knowledge base from any source material
- `read-knowledge-docs` — retrieves targeted information from a structured knowledge base without reading entire files

**Config:** `workspace-docs.json` (machine-local, gitignored) — maps workspace root paths to their documentation directories. Managed exclusively by the `configure-docs` skill.

**Always-on enforcement:** `general-agent-behavior.instructions.md` requires invoking `session-knowledge-harvest` at the end of any session where knowledge was gained.

**Overview:** [`feature-overviews/knowledge-management/knowledge-management.md`](feature-overviews/knowledge-management/knowledge-management.md)

---

## Temporary Debug Logging

A skill-driven workflow for instrumenting a C# codebase with exhaustive temporary debug logging. Output is structured for consumption by a coding agent — not a human — so the goal is completeness, not brevity. Produces correlated log files that let an agent reconstruct the full execution story across thousands of iterations.

| Invoke | How |
|--------|-----|
| Mention the skill | Describe the behavior or value under investigation |

**Skill:** `temp-debug-logging` — six-step workflow: clarify intent, research code, plan format and data, review the plan, implement, notify

**Overview:** [`feature-overviews/temp-debug-logging/temp-debug-logging.md`](feature-overviews/temp-debug-logging/temp-debug-logging.md)

---

## Paper Banana Infographic Prompts

Generates structured, high-quality prompts for [Paper Banana](https://paper-banana.org/) from a source markdown file. Auto-suggests all categories (topic, audience, intent, visual style, structure, key elements, exclusions) from the source content so the user reviews suggestions rather than answering open-ended questions. Directly addresses the "extra/missing information" problem by requiring explicit key elements and exclusions in every prompt.

| Invoke | How |
|--------|-----|
| Mention the skill | Provide a path to your source markdown file |

**Skill:** `paper-banana-infographics` — eight-step workflow: read source, auto-suggest all categories, confirm with user, distill key elements, identify exclusions, compose prompt, review, save

**Overview:** [`feature-overviews/paper-banana/paper-banana.md`](feature-overviews/paper-banana/paper-banana.md)

---

## LinkedIn Posts

Guides through creating a high-impact LinkedIn post from a concept, piece of content, or goal. Auto-suggests format and structure options so the user reviews choices rather than answering open-ended questions. Goal: posts that earn engagement (reactions, comments, DMs) — not just impressions.

| Invoke | How |
|--------|-----|
| Mention the skill | Describe the goal or provide source content |

**Skill:** `creating-linkedin-posts` — eight-step workflow: understand goal, understand content, ideate post types, select format, plan structure, write draft, review, save

**Overview:** [`feature-overviews/linkedin-posts/linkedin-posts.md`](feature-overviews/linkedin-posts/linkedin-posts.md)

---

## Summarize Meeting Transcripts

Two skills for summarizing recorded meeting transcripts, each tuned to a different capture environment.

| Invoke | Skill | For |
|--------|-------|-----|
| Mention the skill | `summarize-remote-meeting` | Remote meetings (Zoom, Teams, Meet) where each participant is on their own microphone |
| Mention the skill | `summarize-workshop-recording` | In-person workshops or classroom sessions captured by a room microphone |

**`summarize-remote-meeting`** — Detects and filters off-topic segments, field-issue interruptions, and social tangents. Produces a clean structured summary seeded only with relevant content. Output: `meeting-summaries/{YYYY-MM-DD}-{topic-slug}.md`

**`summarize-workshop-recording`** — Handles multi-group noise, classifies low-quality segments, produces a structured lesson overview with key takeaways, and critiques the session on pacing, engagement, and learning growth.

**Overview:** [`feature-overviews/summarize-meeting-transcripts/summarize-meeting-transcripts.md`](feature-overviews/summarize-meeting-transcripts/summarize-meeting-transcripts.md)

---

## VS Code Terminal Auto-Approve

A skill for adding or fixing VS Code auto-approval patterns for Copilot agent terminal commands. Eliminates repeated manual approval prompts by writing the correct `chat.tools.terminal.autoApprove` entries in `settings.json` — with the right matching mode for each command type.

| Invoke | How |
|--------|-----|
| Mention the skill | Describe the command that prompted for approval, or say "add to auto approve" / "it kept asking for approval" |

**Skill:** `vscode-terminal-auto-approve` — five-step workflow: read lessons, fetch official docs, understand the two matching modes, write a correctly scoped pattern, verify without side effects

**Overview:** [`feature-overviews/vscode-terminal-auto-approve/vscode-terminal-auto-approve.md`](feature-overviews/vscode-terminal-auto-approve/vscode-terminal-auto-approve.md)

