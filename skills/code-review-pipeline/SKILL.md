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
| `REVIEW-SecurityAuditor` | OWASP Top 10, injection, access control, sensitive data | Parallel phase |
| `REVIEW-RippleEffectAuditor` | Incomplete propagation, missing companion logic, asymmetric paths | Parallel phase |
| `REVIEW-FinalSynthesizer` | Reads all 9 audit reports, applies LessonsLearned, writes final-review.md | After parallel phase completes |

## Conventions

All REVIEW-* agents must explicitly read `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/CONVENTIONS.md` before performing any audit work. The `<conventions>` block in each agent provides a quick inline summary, but the full file is the source of truth. Key conventions:

- Output directory: `/code-review/` in the reviewed repo
- Severity levels: Critical / High / Medium / Low
- Reports require specific file/line references with markdown links
- Recommendations must be specific, actionable, and justified

## Pipeline Setup Patterns

The following patterns recur during review initialization and agent configuration. Knowing them before the first `git diff` prevents a failed or misscoped run.

### Base branch detection: strip the full ref prefix atomically
`git symbolic-ref refs/remotes/origin/HEAD` returns the **full ref path** (e.g., `refs/remotes/origin/main`), not just the branch name. If this raw value is written to session config before stripping, all subsequent `git diff main...HEAD` commands fail or produce wrong results. Fix: strip inline in the same command — e.g., `-replace '.*/',''` (PowerShell) or `sed 's|.*origin/||'` (bash). Never split detection and strip into two sequential commands — the intermediate wrong value propagates silently to every downstream auditor.

### Worktree-as-main/master: "all changes since main" requires fallback
When a repo uses git worktrees and the current branch IS the base branch (`HEAD -> main`), `git log main..HEAD` returns nothing — there is no divergence. Correct fallback: (1) detect the empty diff, (2) fall back to explicit commit(s) from the session config or user request, (3) write `reviewMode = 'single-commit'` so downstream auditors know the scope. Do NOT silently use the empty diff — that produces a review of nothing. Always surface the scope explicitly so the user can confirm.

### Agent frontmatter: `user-invocable: false` vs. `disable-model-invocation: true`
`disable-model-invocation: true` prevents ALL programmatic invocation of an agent — including by an Orchestrator that lists it in its `agents:` frontmatter array. Any REVIEW-* agent meant to be called by the Orchestrator or Coordinator must use `user-invocable: false` instead. Reserve `disable-model-invocation: true` only for agents that must never be invoked by any agent under any circumstances.

## Lessons Learned

This skill uses a per-auditor LessonsLearned structure. Each parallel auditor maintains its own independent LL directory:

```
skills/code-review-pipeline/lessons-learned/
  REVIEW-MaintainabilityAuditor/   LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-TestabilityAuditor/       LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-PerformanceAuditor/       LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-ExtensibilityAuditor/     LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-UnitTestCoverageAuditor/  LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-SecurityAuditor/          LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-RippleEffectAuditor/      LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-FinalSynthesizer/         LessonsLearned.GLOBAL.md + LessonsLearned.md
```

The pipeline-level `LessonsLearned.GLOBAL.md` / `LessonsLearned.md` (this directory) are shared by the Orchestrator, Coordinator, RequirementsAuditor, and CorrectnessAuditor.

**Rules:**
- Each parallel auditor reads and writes only its own directory — auditors do not read each other's LL files
- `REVIEW-FinalSynthesizer` reads all 6 per-auditor LL files for cross-auditor context, writes findings to its own directory, and promotes to the pipeline-level LL only when a finding applies to the entire pipeline
- Per-auditor LL entries may conflict — FinalSynthesizer is expected to reconcile them
- `*.md` (gitignored) — codebase-specific patterns; `*.GLOBAL.md` (tracked) — cross-codebase process/model patterns
- **`*.GLOBAL.md` files are committed to a public shared repo. NEVER write class names, method names, type names, project names, domain abbreviations, or any codebase-specific content to them.** Strip all workspace context before writing. If uncertain which file to use, write to `*.md` (local) instead.
- **SANITIZATION GATE — required before every GLOBAL write:** (1) List every capitalized identifier and domain abbreviation in the proposed entry. (2) Classify each as standard framework type or project-specific. (3) Replace all project-specific identifiers with generic placeholders. (4) Re-read the entry — if it requires knowing the project to make sense, move it to `*.md`. This gate applies to illustrative examples too: the most common violation is writing an abstract lesson with a concrete project-specific example. Remove or generalize the example.

See the `lessons-learned` skill for guidance on which tier to write to and when.
