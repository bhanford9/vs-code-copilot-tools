---
name: code-review-pipeline
description: Multi-agent code review workflow covering requirements, correctness, test coverage, maintainability, testability, performance, and extensibility. Use when running a code review, invoking any REVIEW-* agent, or consulting patterns from past review sessions.
---

# Code Review Pipeline

Before beginning any review work, read [LessonsLearned.GLOBAL.md](./LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](./LessonsLearned.md). Apply any recorded patterns to the session.

## Overview

The code review pipeline is an 8-agent system that audits code changes across seven quality dimensions. Sequential audits establish requirements and correctness context; five specialist auditors then run in parallel as subagents. A dedicated synthesizer produces the final report.

For full architecture and usage details, see [feature-overviews/code-review-pipeline/code-review-pipeline.md](../../feature-overviews/code-review-pipeline/code-review-pipeline.md).

## Related Skills

The **`fetch-azure-devops-work-item`** skill is used by the Requirements Auditor to automatically retrieve work item details from Azure DevOps via REST API. It lives in the reviewed repo at `.claude/skills/fetch-azure-devops-work-item/`. The `REVIEW-RequirementsAuditor` gracefully falls back to asking the user if the skill is not configured.

## Agent Roles

| Agent | Role | When Invoked |
|---|---|---|
| `REVIEW-CodeReviewOrchestrator` | Entry point; routes to sequential auditors | User invokes `/ReviewLocal` or `/PrepareCommitReview` |
| `REVIEW-RequirementsAuditor` | Extracts requirements; auto-fetches work item via API or prompts user | Sequential phase, first |
| `REVIEW-CodeCorrectnessAuditor` | Verifies functional correctness against requirements | Sequential phase, second |
| `REVIEW-ParallelAuditCoordinator` | Spawns the 5 parallel auditors as subagents | After user approves parallel phase |
| `REVIEW-UnitTestCoverageAuditor` | Test completeness and quality | Parallel phase |
| `REVIEW-MaintainabilityAuditor` | Readability, SRP, coupling | Parallel phase |
| `REVIEW-TestabilityAuditor` | DI boundaries, complexity, observability | Parallel phase |
| `REVIEW-PerformanceAuditor` | Memory, algorithms, concurrency | Parallel phase |
| `REVIEW-ExtensibilityAuditor` | OCP, extension points, future adaptability | Parallel phase |
| `REVIEW-FinalSynthesizer` | Reads all 7 audit reports, applies LessonsLearned, writes final-review.md | After parallel phase completes |

## Conventions

All REVIEW-* agents must explicitly read `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/CONVENTIONS.md` before performing any audit work. The `<conventions>` block in each agent provides a quick inline summary, but the full file is the source of truth. Key conventions:

- Output directory: `/code-review/` in the reviewed repo
- Severity levels: Critical / High / Medium / Low
- Reports require specific file/line references with markdown links
- Recommendations must be specific, actionable, and justified

## Lessons Learned

This skill uses a per-auditor LessonsLearned structure. Each parallel auditor maintains its own independent LL directory:

```
skills/code-review-pipeline/lessons-learned/
  REVIEW-MaintainabilityAuditor/   LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-TestabilityAuditor/       LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-PerformanceAuditor/       LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-ExtensibilityAuditor/     LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-UnitTestCoverageAuditor/  LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-FinalSynthesizer/         LessonsLearned.GLOBAL.md + LessonsLearned.md
```

The pipeline-level `LessonsLearned.GLOBAL.md` / `LessonsLearned.md` (this directory) are shared by the Orchestrator, Coordinator, RequirementsAuditor, and CorrectnessAuditor.

**Rules:**
- Each parallel auditor reads and writes only its own directory — auditors do not read each other's LL files
- `REVIEW-FinalSynthesizer` reads all 6 per-auditor LL files for cross-auditor context, writes findings to its own directory, and promotes to the pipeline-level LL only when a finding applies to the entire pipeline
- Per-auditor LL entries may conflict — FinalSynthesizer is expected to reconcile them
- `*.md` (gitignored) — codebase-specific patterns; `*.GLOBAL.md` (tracked) — cross-codebase process/model patterns
- **`*.GLOBAL.md` files are committed to a shared repo used by all users. NEVER write class names, method names, type names, project names, or any codebase-specific content to them.** Strip all workspace context before writing. If uncertain which file to use, write to `*.md` (local) instead.

See the `lessons-learned` skill for guidance on which tier to write to and when.
