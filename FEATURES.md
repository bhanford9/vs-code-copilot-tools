# Feature Map

A conceptual index of every tool in this repo. Each entry describes what the tool does from a user perspective, not how it is implemented.

---

## Planning Pipeline

A multi-agent workflow for turning a vague feature idea into a fully structured implementation plan with gap analysis and work breakdown.

| Invoke | How |
|--------|-----|
| `/CreatePlan` | Start the pipeline — describe a feature or task |
| `/CreateWorkItems` | Convert a completed plan into Azure DevOps stories |

**Agents involved:** `InitialPlanner` → `GapFinder` → `GapResolver` → `RefinedPlanner` → `ArchitecturalDesigner` → `WorkPlanner` → `Implementation`

---

## Code Review Pipeline

A multi-agent pipeline that runs a structured audit of code changes across six quality dimensions: requirements, correctness, test coverage, maintainability, testability, performance, and extensibility. Produces per-dimension audit reports and a final synthesized summary.

| Invoke | How |
|--------|-----|
| `/PrepareCommitReview` | Create an isolated review branch from a set of commit SHAs |
| `/ReviewLocal` | Review uncommitted local changes |
| `/CleanupCommitReview` | Restore the repo and remove temp branches after review |

**Agents involved:** `REVIEW-CodeReviewOrchestrator`, seven specialist auditors, `REVIEW-ParallelAuditCoordinator`, `REVIEW-FinalSynthesizer`

---

## Unit Test Writer

An agent that writes comprehensive NUnit unit tests through methodical code and pattern analysis — reads existing test structure, resolves types and interfaces, and never guesses.

| Invoke | How |
|--------|-----|
| `@UnitTestWriter` | Describe the class or method to test |

**Skill:** `writing-csharp-tests` — conventions, common pitfalls, known project helpers

---

## Azure DevOps Story Creation

An agent that produces correctly structured Azure DevOps work items with required sections (Blocked By, Backing Content, Goal, Details, Acceptance Criteria) through codebase research and user collaboration.

| Invoke | How |
|--------|-----|
| `@AzureStoryCreation` | Describe the work or feature needing a story |
| `/CreateWorkItems` | Run from a completed plan |

**Skill:** `creating-azure-stories` — format rules, templates, examples

---

## Copilot Tools Management

Tools for keeping this repo's configuration in sync across machines.

| Invoke | How |
|--------|-----|
| `/update-copilot-tools` | Pull latest, analyze changes, handle follow-up steps |
| `/merge-copilot-settings` | Apply `settings.base.json` on top of local `settings.json` |

**Skills:** `update-copilot-tools`, `merge-copilot-settings`

---

## Agentic Tools Auditor

An orchestrated audit of all VS Code Copilot agentic tool configurations in the current workspace. Discovers every config item, runs parallel per-item auditors, and synthesizes findings into recommendations.

| Invoke | How |
|--------|-----|
| `@AgenticToolsAuditor` | Run from any workspace to audit its agentic setup |

**Agent:** `individual-auditor` (sub-agent, spawned per config item)
**Skill:** `agentic-tools-auditor`

---

## C# Development Assistance

Auto-attached rules and skills that improve C# coding workflows without requiring explicit invocation.

| What | Description |
|------|-------------|
| C# error checking | Always uses the "Check Changed Files" VS Code task — never `dotnet build` or `get_errors` |
| C# test conventions | NUnit naming patterns, Moq mocking conventions, parameterized test guidance |

**Instructions:** `csharp-diagnostics.instructions.md`, `csharp-tests.instructions.md` (auto-applied to `*.cs` files)
**Skills:** `checking-csharp-errors`, `writing-csharp-tests`

---

## Hooks

Small pre/post-turn scripts that run automatically during agent sessions.

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `ensure-freeform` | PreToolUse | Blocks agent sessions from locking into a rigid tool-use pattern; preserves freeform reasoning |
| `test-no-comments` | PostToolUse | Checks that newly written test code doesn't contain comments (enforces commenting conventions) |
| `block-devops-fetch` | PreToolUse | Prevents the Requirements Auditor from making external API/DevOps fetch calls during review |
| `check-auditor-output` | SubagentStop | Verifies each parallel code review auditor produced its expected output file |

---

## Lessons Learned System

A feedback loop built into every skill and agent workflow. After completing a session, the agent reflects on what was hard or surprising and appends findings to a `LessonsLearned.md` file alongside the relevant skill. Future sessions read it first to avoid repeating mistakes.

**Skill:** `lessons-learned`
