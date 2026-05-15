# Lessons Learned — track-agent-work (GLOBAL)
#
# Scope: Process and model observations — applies across all workspaces and users.
# Do NOT write codebase-specific content here (no class names, file paths, task IDs).
# For codebase-specific notes, use LessonsLearned.md (gitignored, per-user).

## Test Raw CLI Output Before Writing Wrapper Scripts
Category: Process/Model

When a skill wraps a CLI tool in a helper script, the first step must be to run the CLI raw and inspect the exact output — envelope shape, field names, casing — before writing any parsing logic. Skipping this step reliably produces bugs that only surface at runtime (wrong property path, missed envelope, wrong filter predicate). A single `$raw | ConvertFrom-Json | ConvertTo-Json` call costs two seconds and prevents an entire class of wrapper bug.

**Watch out for:** Wrapper scripts that were written based on an old response format (e.g., `{ "data": { ... } }` envelope) when the actual CLI outputs the object at the top level with no wrapper. This class of bug silently produces `$null` IDs and exits with code 1 — the task still gets created but the script can't return its ID.

---

## Distinguish "Claim for Human Session" from "Dispatch for Agent Execution"
Category: Process/Model

Many task systems have two distinct "start" operations:
1. **Human-session claim** — simple status set, no preconditions. Tells the board "a human is working on this now."
2. **Agent dispatch** — gated claim with eligibility checks (approval, workspace binding, priority threshold). Tells the dispatch system "this task is ready for autonomous execution."

When a skill needs to mark a task In Progress for tracking purposes (not dispatch), always use the simple claim command. Using the dispatch command when the task is not fully configured will block it rather than start it, and the failure message may look like success (the API call succeeds; only the resulting status reveals the error).

DO verify after any "start" operation that the returned status is `InProgress` (not `Blocked` or `DispatchFailed`).

---

## `read_file` Tool Can Return Stale Cached Content
Category: Process/Model

The `read_file` tool can return a cached version of a file that differs from what is currently on disk. This is particularly dangerous when diagnosing crashes or verifying a recent code change — the cached version may show the old code while the terminal crash reveals behavior matching the new code. 

**DO:** When a diagnosis depends on knowing the exact current state of a file (e.g., which enum values exist, which constructor signature is in use), verify with a terminal `Get-Content` command rather than trusting `read_file` alone. Use `read_file` for general context; use the terminal when precision matters.
