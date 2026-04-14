---
name: code-review-pipeline
description: Multi-agent code review workflow covering requirements, correctness, test coverage, maintainability, testability, performance, and extensibility. Use when running a code review, invoking any REVIEW-* agent, or consulting patterns from past review sessions.
---

# Code Review Pipeline

Before beginning any review work, read [LessonsLearned.md](./LessonsLearned.md) if it exists alongside this file and apply any recorded patterns to the session.

## Overview

The code review pipeline is an 8-agent system that audits code changes across seven quality dimensions. Sequential audits establish requirements and correctness context; five specialist auditors then run in parallel as subagents. A dedicated synthesizer produces the final report.

For full architecture and usage details, see [feature-overviews/code-review-pipeline/code-review-pipeline.md](../../feature-overviews/code-review-pipeline/code-review-pipeline.md).

## Agent Roles

| Agent | Role | When Invoked |
|---|---|---|
| `REVIEW-CodeReviewOrchestrator` | Entry point; routes to sequential auditors | User invokes `/ReviewLocal` or `/PrepareCommitReview` |
| `REVIEW-RequirementsAuditor` | Extracts requirements, compares with work item | Sequential phase, first |
| `REVIEW-CodeCorrectnessAuditor` | Verifies functional correctness against requirements | Sequential phase, second |
| `REVIEW-ParallelAuditCoordinator` | Spawns the 5 parallel auditors as subagents | After user approves parallel phase |
| `REVIEW-UnitTestCoverageAuditor` | Test completeness and quality | Parallel phase |
| `REVIEW-MaintainabilityAuditor` | Readability, SRP, coupling | Parallel phase |
| `REVIEW-TestabilityAuditor` | DI boundaries, complexity, observability | Parallel phase |
| `REVIEW-PerformanceAuditor` | Memory, algorithms, concurrency | Parallel phase |
| `REVIEW-ExtensibilityAuditor` | OCP, extension points, future adaptability | Parallel phase |
| `REVIEW-FinalSynthesizer` | Reads all 7 audit reports, applies LessonsLearned, writes final-review.md | After parallel phase completes |

## Conventions

All agents are governed at runtime by `REVIEW-CONVENTIONS.instructions.md` (auto-injected via `applyTo: "**"`). Key conventions:

- Output directory: `/code-review/` in the reviewed repo
- Severity levels: Critical / High / Medium / Low
- Reports require specific file/line references with markdown links
- Recommendations must be specific, actionable, and justified

## Lessons Learned

The `LessonsLearned.md` alongside this file captures accumulated patterns from completed review sessions:

- Recurring codebase patterns that look wrong but are intentional conventions
- Known false positives to suppress or downgrade
- Missing coverage areas discovered after the fact
- Notes on what each auditor caught vs. missed

`REVIEW-FinalSynthesizer` reads this file before every synthesis to apply known patterns. Append a new entry after any session that surfaces something a future agent should know. See the `lessons-learned` skill for guidance on what to write and when.
