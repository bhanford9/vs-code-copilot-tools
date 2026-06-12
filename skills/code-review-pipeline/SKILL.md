---
name: code-review-pipeline
description: Multi-agent code review workflow covering requirements, correctness, test coverage, maintainability, testability, performance, and extensibility. Use when running a code review, invoking any REVIEW-* agent, or consulting patterns from past review sessions.
---

# Code Review Pipeline

Before beginning any review work, read [LessonsLearned.GLOBAL.md](./LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](./LessonsLearned.md). Apply any recorded patterns to the session.

## Overview

The code review pipeline is a 6-agent system that audits code changes across eight quality dimensions. Sequential audits establish requirements and correctness context; a generic `REVIEW-Auditor` agent runs four batches in parallel, each executing one or more auditor-specific SKILL.md files in sequence. A dedicated synthesizer produces the final report.

For full architecture and usage details, see [feature-overviews/code-review-pipeline/code-review-pipeline.md](../../feature-overviews/code-review-pipeline/code-review-pipeline.md).

> **First time using this pipeline on a new repo?** See [SETUP.md](./SETUP.md) for the one-time per-repo configuration steps (artifact exclusions, captive dependency script). The pipeline works without any setup — configuration only improves diff quality and audit accuracy.

## Related Skills

The **`fetch-azure-devops-work-item`** skill is used by the Requirements Auditor to automatically retrieve work item details from Azure DevOps via REST API. It lives in the reviewed repo at `.claude/skills/fetch-azure-devops-work-item/`. The `REVIEW-RequirementsAuditor` gracefully falls back to asking the user if the skill is not configured.

## Agent Roles

| Agent | Role | When Invoked |
|---|---|---|
| `REVIEW-CodeReviewOrchestrator` | Entry point; routes to sequential auditors; launches 4 parallel REVIEW-Auditor batches | User invokes `/ReviewLocal` or `/PrepareCommitReview` |
| `REVIEW-RequirementsAuditor` | Extracts requirements; auto-fetches work item via API or prompts user | Sequential phase, first |
| `REVIEW-CodeCorrectnessAuditor` | Verifies functional correctness against requirements | Sequential phase, second |
| `REVIEW-Auditor` | Generic auditor; reads one or more auditor SKILL.md files and executes them in sequence | Parallel phase (4 batches) |
| `REVIEW-FinalSynthesizer` | Reads all 10 audit reports, applies LessonsLearned, writes final-review.md | After parallel phase completes |

### Parallel Batch Assignments

The Orchestrator launches 4 `REVIEW-Auditor` batches simultaneously:

| Batch | Auditor Skills Assigned |
|---|---|
| A | unit-test-coverage, testability |
| B | extensibility, structural-patterns, maintainability |
| C | ripple-effect |
| D | performance [+ security if surface detected] |

Each auditor skill lives at: `skills/code-review-pipeline/auditors/{name}/SKILL.md`

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
When a repo uses git worktrees and the current branch IS the base branch (`HEAD -> main`), `git log main..HEAD` returns nothing — there is no divergence. **`build-changeset.ps1` handles this automatically**: it detects the empty diff and falls back to `git show $cfg.targetCommit` (single-commit mode). The `reviewMode` field in `session-config.json` will be `"single-commit"`. Always pass `-TargetCommit` to `detect-base-branch.ps1` when reviewing a specific already-merged commit.

### Agent frontmatter: `user-invocable: false` vs. `disable-model-invocation: true`
`disable-model-invocation: true` prevents ALL programmatic invocation of an agent — including by an Orchestrator that lists it in its `agents:` frontmatter array. Any REVIEW-* agent meant to be called by the Orchestrator or Coordinator must use `user-invocable: false` instead. Reserve `disable-model-invocation: true` only for agents that must never be invoked by any agent under any circumstances.

### changeset-full.md: the primary context file for all auditors
After running `build-changeset.ps1`, `code-review/changeset-full.md` contains five sections:

| Section | Content | Primary consumers |
|---|---|---|
| A — Commit messages | Full commit bodies | Requirements, Correctness |
| B — Diff hunks | `--unified=10` diff for all changed files | All auditors |
| C — Full source (size-gated) | Complete current content of ≤20 non-test source files | Structural, Maintainability, Testability, Extensibility, Performance |
| D — Symbol reference index | File:line:content for every reference to each changed public symbol | RippleEffect (replaces all grep calls) |
| E — Test file index | Changed source → expected test file + existence check | UnitTestCoverage, Testability |

**Auditors should read `changeset-full.md` as their first action** (after LessonsLearned). They should use the sections appropriate to their audit and only perform additional `read_file` calls for targeted investigation after the index points them to specific locations.

### Security surface classification: skip batch D security audit when not applicable
`detect-base-branch.ps1` writes `securitySurface: true/false` to `session-config.json` by scanning changed file paths for controller/auth/input/external integration patterns. The Orchestrator reads this before launching the parallel phase. When `securitySurface = false`, write the security-audit.md stub directly (no subagent dispatch) and omit security from Batch D's prompt.

## Lessons Learned

This skill uses a per-auditor LessonsLearned structure. Each parallel auditor maintains its own independent LL files under `auditors/`:

```
skills/code-review-pipeline/auditors/
  audit-report-template.md             shared compact report format
  ripple-effect/       SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  unit-test-coverage/  SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  testability/         SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  extensibility/       SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  structural-patterns/ SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  maintainability/     SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  performance/         SKILL.md + LessonsLearned.GLOBAL.md + LessonsLearned.md
  security/            SKILL.md + LessonsLearned.GLOBAL.md

skills/code-review-pipeline/lessons-learned/
  REVIEW-CodeCorrectnessAuditor/       LessonsLearned.GLOBAL.md + LessonsLearned.md
  REVIEW-FinalSynthesizer/             LessonsLearned.GLOBAL.md + LessonsLearned.md
```

The pipeline-level `LessonsLearned.GLOBAL.md` / `LessonsLearned.md` (this directory) are shared by the Orchestrator, RequirementsAuditor, and CorrectnessAuditor.

**Rules:**
- Each parallel auditor reads and writes only its own directory — auditors do not read each other's LL files
- `REVIEW-FinalSynthesizer` reads all 8 per-auditor LL files for cross-auditor context, writes findings to its own directory, and promotes to the pipeline-level LL only when a finding applies to the entire pipeline
- Per-auditor LL entries may conflict — FinalSynthesizer is expected to reconcile them
- `*.md` (gitignored) — codebase-specific patterns; `*.GLOBAL.md` (tracked) — cross-codebase process/model patterns
- **`*.GLOBAL.md` files are committed to a public shared repo. NEVER write class names, method names, type names, project names, domain abbreviations, or any codebase-specific content to them.** Strip all workspace context before writing. If uncertain which file to use, write to `*.md` (local) instead.
- **SANITIZATION GATE — required before every GLOBAL write:** (1) List every capitalized identifier and domain abbreviation in the proposed entry. (2) Classify each as standard framework type or project-specific. (3) Replace all project-specific identifiers with generic placeholders. (4) Re-read the entry — if it requires knowing the project to make sense, move it to `*.md`. This gate applies to illustrative examples too: the most common violation is writing an abstract lesson with a concrete project-specific example. Remove or generalize the example.

See the `lessons-learned` skill for guidance on which tier to write to and when.
