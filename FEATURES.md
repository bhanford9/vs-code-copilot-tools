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

---

## Code Review Pipeline

A multi-agent pipeline that runs a structured audit of code changes across seven quality dimensions: requirements, correctness, test coverage, maintainability, testability, performance, and extensibility. Sequential audits establish context; five specialty auditors then run in parallel as subagents. Produces per-dimension reports and a synthesized final review with merge recommendation.

| Invoke | How |
|--------|-----|
| `/PrepareCommitReview` | Create an isolated review branch from a set of commit SHAs |
| `/ReviewLocal` | Review uncommitted local changes |
| `/CleanupCommitReview` | Restore the repo and remove temp branches after review |

**Agents involved:** `REVIEW-CodeReviewOrchestrator` → `REVIEW-RequirementsAuditor` → `REVIEW-CodeCorrectnessAuditor` → `REVIEW-ParallelAuditCoordinator` (spawns 5 parallel auditors) → final synthesis

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

Instruction files that apply to every chat session regardless of context.

| File | Applies To | What It Does |
|------|------------|--------------|
| `general-agent-behavior.instructions.md` | `**` (all files) | Requires clarifying questions any time confidence is below 90% |
| `REVIEW-CONVENTIONS.instructions.md` | `**/code-review/*.md` | Injects shared code review conventions (severity levels, output format, actionable recommendations) when working inside the `/code-review/` output directory |

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

**Skill:** `lessons-learned`

**Overview:** [`feature-overviews/lessons-learned-system/lessons-learned-system.md`](feature-overviews/lessons-learned-system/lessons-learned-system.md)
