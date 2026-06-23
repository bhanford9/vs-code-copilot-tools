# Lessons Learned (Global): code-review-pipeline

> Pipeline-process observations applicable to any review session.
> **Recording rule**: Record only workflow process improvements. No codebase-specific knowledge, code patterns, or finding calibrations.

---

### Correctness auditor: cross-check session-config.json commits vs. changeset.md commits before auditing

If a new commit is pushed AFTER the requirements audit runs, `changeset.md` is regenerated but `session-config.json` is not updated. This creates a silent scope mismatch. On every correctness audit, compare the commit list in `session-config.json` against the commit log in `changeset.md`. Any commit in `changeset.md` absent from `session-config.json` was added post-requirements-audit — flag it as Critical until the product decision is confirmed.

---

### Manual orchestration bypasses the Orchestrator's file routing — invoke as a subagent instead

When a user says "let's review this commit" conversationally, invoke `REVIEW-CodeReviewOrchestrator` as a subagent. Manual orchestration requires replicating the Orchestrator's file routing by hand and is error-prone.

---

### Cross-check the Agent Roles table in SKILL.md against the deployed agents list before starting the parallel phase

If they disagree, fix SKILL.md first. When a new auditor is added, update all of these in one commit: (1) Overview "N-agent system" count, (2) "M specialist auditors" count, (3) Coordinator/FinalSynthesizer row descriptions, (4) LL directory tree, (5) LL rules.

---

### Parallel phase: call all auditors directly in a single parallel block

There is no Coordinator intermediary. Call all specialist auditors via one parallel `runSubagent` block from the Orchestrator. Calling auditors sequentially defeats parallelism and costs unnecessary tokens for each sequential invocation.

---

### Write `parallel-brief.md` before launching the parallel phase

Before the parallel phase, the Orchestrator writes `code-review/parallel-brief.md` — a 400-500 word compressed summary of change intent, key correctness findings, and risk areas. Each parallel auditor reads this instead of independently re-processing raw diffs. If missing, each of 8 auditors re-reads the same diff independently, multiplying context costs by 8.

---

### Stale `code-review/` artifacts must be deleted before any new pipeline run

When cherry-picked commits contain `code-review/*.md` files from a prior session, they land in the working tree and corrupt all subsequent stages.
- Run immediately after cherry-picking: `Remove-Item code-review\*.md -ErrorAction SilentlyContinue`
- When the diff shows `code-review/` files: delete them immediately
- At no point should `code-review/*.md` exist in the working tree when a new run begins

---

### Auto-start lessons learned after the final review report — do not prompt

Once `final-review.md` is written and presented, start lessons learned in the same turn. Do not print a trigger phrase and wait.

---

### Session continuation across token limit: conversation summary contains full continuation state

When a long pipeline run hits the token limit mid-session, the conversation summary contains the full state needed to resume. On continuation: (1) read "Active Work State" and "Continuation Plan" sections first, (2) verify partially-written artifacts match what the summary says, (3) complete partial artifacts before moving to the next stage. Do not re-run earlier stages.

---

### Complete file replacement: delete then create — do not patch large files in place

When a review artifact from a prior session must be fully replaced, use `Remove-Item` then `create_file`. Piecemeal `replace_string_in_file` on multi-hundred-line files produces partial matches, orphaned sections, and duplicate blocks.

---

### Dead code search on Windows: use `Get-ChildItem | Select-String` — `Select-String -Recurse` is not valid

```
Get-ChildItem <path> -Recurse -Include "*.cs" | Select-String -Pattern <symbol>
```

---

### Multiple auditors flagging the same finding: de-duplicate and take the highest severity

When two or more auditors independently flag the same code element from different analytical angles, produce one finding and take the highest severity any auditor cited. Cite all flagging auditors. Convergence from independent auditors is never a false positive.

---

### Empirical validation data supersedes code-tracing for Critical findings

When the developer provides a same-day validation or characterization test run, analyze its output before writing any Critical finding. Rate Critical only when the data confirms the gap, or when no validation data is available.

---

### Test strategy doc vs. committed tests: search by behavior, not planned method name

Before reporting a test as missing, open the test file and search for the behavior — tests are frequently delivered under a different label but cover the required behavior.

---

### fetch-ado-workitem fails silently on new worktrees — check for .env before invoking

The `fetch-ado-workitem` skill requires a `.env` file in the skill directory alongside `SKILL.md`. On first use in a worktree that was cloned or created fresh, this file does not exist. The script exits with a clear error, but the requirements auditor should detect this immediately and proceed with commit-log-based inference rather than prompting the user for a PAT interactively. Record this as a non-blocking condition: infer requirements from commits and note "ADO PAT not configured" in the audit report.

---

### Requirements audit without a work item: group by feature area, not by file

Structure the audit around intent-grouped feature areas inferred from the diff: (1) foundational abstractions, (2) refactors, (3) new entry points, (4) downstream behavior changes. This ordering surfaces Critical gaps that a file-by-file scan would miss.

---

### Section C slice bloat: structural/maintainability auditors hit the threshold when large implementation files are included in full

When a changeset contains large implementation files (>300 lines) in Section C, structural-patterns and maintainability auditors often see slices that exceed the 75% threshold, triggering full-changeset fallback. Root cause: these auditors care about class shape and naming patterns, not method-body implementation details past the first ~300 lines.

`build-slices.ps1` now applies a 300-line per-file cap for these auditors. With the cap, their slices drop to ~73% of full changeset (measured against a PR with a 1,318-line SkiaSharp renderer). Performance and ripple-effect auditors remain uncapped — they need full implementation bodies.

Diagnostic signal: if structural-patterns or maintainability show "100% (threshold)" in `auditor-input-index.md`, they fell back to full changeset. The cap in `build-slices.ps1` prevents this for any file under 300 lines; for larger files, a `<!-- SECTION-C-TRUNCATED -->` marker tells the auditor content was capped.

---

### Filter-removal: two mandatory companion checks

When a `.Where()` guard is removed: (1) check whether downstream code relied on it as a safety net against `.First()` / `.Single()` throws on empty sequences — trace the full call chain; (2) verify a new test documents the now-inclusive behavior. The previously-excluded case is by definition untested with the old code.

---

### parallel-brief.md: include confirmed-correct patterns as explicit "do not flag" notes for other auditors

When a correctness audit resolves an ambiguous pattern as intentional and safe, document the resolution in `parallel-brief.md` with a clear "confirmed correct — not a defect" note. This prevents other auditors from independently re-investigating the same pattern.

---

### Standing reviews: read architecture docs before source; flag doc-drift in its own section

In standing reviews (no diff): read architecture docs first to extract behavioral contracts, then validate against source. If docs say a feature is "not yet implemented" but code has delivered it, put this in a "Documentation Drift" section — not in the Gaps list.

---

### Refactoring PRs: verify every new class instantiation has a resolvable class definition

When a refactor introduces new class names, grep the full source tree for each new class name. A class instantiated in a constructor but with no implementation file will cause a compile error that static analysis may not catch in large solutions.

---

### Context accumulation, not output, is the primary cost driver — route each auditor to its slice

In a multi-agent code review, the input:output token ratio is typically 97:3. Cost is almost entirely from context size, not findings volume. When a parallel auditor reads the full changeset early in its turn, that context persists across every subsequent LLM call — multiplied by the number of tool calls it makes. The solution is to route each auditor to a targeted slice written by a dedicated dispatcher agent. Key design decisions:

- **75% threshold:** if a candidate slice would be ≥75% of the full file by line count, point the auditor at the full file instead
- **Dispatcher runs in Stage 2 parallel with Requirements** — it does NOT need `requirements-audit.md`
- **Requirements and Correctness genuinely need the full diff** — they cannot be sliced
- **`auditor-input-index.md` is the control plane** — the dispatcher writes it; every auditor reads it first; the orchestrator gate-checks it alongside `parallel-brief.md` before Stage 5

---

### Compound risk: two Medium findings can combine into a High

After listing all findings, second-pass: "If finding X is triggered, does it make finding Y exploitable in a way it otherwise would not be?" If yes, cross-reference both and upgrade the combined severity to High if the exploit path is realistic.
