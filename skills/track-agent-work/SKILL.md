---
name: track-agent-work
description: >
  Determines whether the current agent session represents trackable work
  (code change, investigation, planning, bug fix, refactor), then finds
  or creates a matching task in TaskTracker (prod) and marks it In Progress.
  Invoked automatically on the first prompt of each VS Code Copilot session
  via the UserPromptSubmit hook. Runs silently — surfaces only a one-line
  confirmation to the user.
applyTo: "**"
---

# Track Agent Work — SKILL.md

## Purpose

Every meaningful agent session should leave a trace in TaskTracker. This skill:

1. Evaluates the user's request to decide if it's real work or a casual query.
2. Synthesizes a concise task title and description from the request.
3. Searches the prod TaskTracker board for an existing task matching the work.
4. Claims the existing task (or creates a new one) and marks it In Progress using `session-start`.
5. Reports the result in one line and writes a session memory note.

The whole workflow runs in the background before the agent responds. It should be invisible to the user except for the one-line confirmation.

---

## Scripts

All CLI operations are wrapped in scripts located alongside this skill at:
`c:\Users\bmhanford\Repos\copilot-configs\skills\track-agent-work\`

| Script | Purpose |
|---|---|
| `Get-PendingTasks.ps1` | List all non-completed prod tasks as JSON |
| `Invoke-SessionStart.ps1 -TaskId <id>` | Claim an existing task (mark In Progress) |
| `New-TrackedTask.ps1 -Title … -Description … -Category … -Horizon … -Effort …` | Create a new task and immediately claim it |

Never write raw `tt` CLI invocations inline — use these scripts.

---

## Before Starting: Read Lessons Learned

Read both files before doing anything else:

1. `LessonsLearned.GLOBAL.md` — lives in this skill directory; always present.
2. `LessonsLearned.md` — local per-user file; skip silently if absent.

Apply any recorded watch-outs before proceeding.

---

## Execution Checklist

```
Track Agent Work:
- [ ] Phase 0 — Read LessonsLearned files
- [ ] Phase 1 — Determine trackability
- [ ] Phase 2 — Synthesize title and description
- [ ] Phase 3 — Search prod for existing task
- [ ] Phase 4 — Claim or create
- [ ] Phase 5 — Write session memory note
- [ ] Phase 6 — Lessons Learned gate
```

---

## Environment

All commands target **prod** (`:5000` / `tasktracker_prod`).

```powershell
$tt  = "D:\Repos_D\TaskTracker\src\TaskTracker.Cli\bin\Debug\net10.0\TaskTracker.Cli.exe"
$env:ASPNETCORE_ENVIRONMENT = "Production"
# ... run commands ...
$env:ASPNETCORE_ENVIRONMENT = ""
```

Always reset `$env:ASPNETCORE_ENVIRONMENT` after each command block.

---

## Phase 1 — Determine Trackability

Look at the user's request in the current conversation. Apply this decision table:

| Signal | Verdict |
|---|---|
| Implements, fixes, refactors, investigates, or designs something | **Trackable** |
| Creates or modifies files in the workspace | **Trackable** |
| Runs a build, migration, test, or deployment | **Trackable** |
| Planning a feature — produces a design doc, plan, or story | **Trackable** |
| Answers a question or explains code without making changes | **Not trackable** |
| Purely conversational ("thanks", "what does X mean?") | **Not trackable** |
| Simple single-step lookup or reformatting | **Not trackable** |

**If not trackable:**
- Write one line to session memory: `Task tracking: skipped — conversational request.`
- STOP this skill. Proceed with the user's request normally. Show nothing to the user.

**If trackable:** continue to Phase 2.

---

## Phase 2 — Synthesize Title and Description

Derive from the user's request:

**Title** (≤ 120 chars): Action-oriented and specific. Avoid vague verbs.
- ✅ `"Fix dispatch toggle resetting to OFF after navigation in Categories page"`
- ❌ `"Fix bug"` / `"Investigate issue"`

**Description** (2–4 sentences): What the work is, why it matters, what done looks like.
Write for a reader with no session context — as if they're reading the task card cold.

**Category slug**: Infer from request type.
| Request type | Suggested category |
|---|---|
| Code change, refactor, bug fix | `coding` |
| Infrastructure, deployment, Docker | `devops` |
| Planning, architecture, design | `admin` |
| Testing, quality | `coding` |
| Unknown | `coding` (safe default) |

**Horizon**: `ThisWeek` unless the request is clearly longer-term (planning a future feature → `Someday`). Default: `ThisWeek`.

**Effort**: `Small` for targeted single-file fixes; `Medium` for multi-file or multi-step work; `Large` for full features. Default: `Medium`.

Record:
```
Title: {synthesized title}
Description: {2-4 sentences}
Category: {slug}
Horizon: {ThisWeek|Today|Immediate|Someday}
Effort: {Small|Medium|Large}
```

---

## Phase 3 — Search Prod for Existing Task

List all non-completed tasks from prod and evaluate for a match:

```powershell
$skillDir = "c:\Users\bmhanford\Repos\copilot-configs\skills\track-agent-work"
$tasks = & "$skillDir\Get-PendingTasks.ps1" | ConvertFrom-Json
$tasks | Select-Object Id, Title, Status | Format-Table
```

Status values: `0` = Pending, `1` = QueuedForDispatch, `2` = InProgress, `3` = DispatchFailed, `4` = Completed.

**Match criteria:**

| Match type | Rule |
|---|---|
| **Strong match** | Core nouns + verb overlap, clearly same work → use this task |
| **Weak match** | Some overlap but different scope → treat as no match, create new |
| **No match** | Nothing close → proceed to Phase 4b |

If multiple candidates look plausible, pick the closest match and log the ambiguity in session memory.

---

## Phase 4a — Existing Task Found

| Task's current status | Action |
|---|---|
| `0` Pending | Run `Invoke-SessionStart.ps1` to claim it |
| `1` InProgress | Leave as-is (already claimed) — still report to user |
| `2` Blocked | Run `Invoke-SessionStart.ps1` to unblock and claim |
| `3` Completed | Treat as no match — work has resumed; go to Phase 4b |

```powershell
$skillDir = "c:\Users\bmhanford\Repos\copilot-configs\skills\track-agent-work"
& "$skillDir\Invoke-SessionStart.ps1" -TaskId "<found-task-id>"
```

Report to user (inline, before normal response):
> `📋 Claimed task "[title]" (#<short-id>) — In Progress.`

---

## Phase 4b — No Existing Task

Create the task in prod, then immediately claim it with `session-start`:

```powershell
$skillDir = "c:\Users\bmhanford\Repos\copilot-configs\skills\track-agent-work"
$result = & "$skillDir\New-TrackedTask.ps1" `
    -Title "<synthesized title>" `
    -Description "<synthesized description>" `
    -Category coding `
    -Horizon ThisWeek `
    -Effort Medium | ConvertFrom-Json

$taskId = $result.id
```

Report to user (inline, before normal response):
> `📋 Created task "[title]" — In Progress.`

---

## Phase 5 — Write Session Memory

Write a note so later skill invocations (or session harvest) have context:

```
Task tracking: [Claimed|Created] task <id> — "<title>"
```

Use the memory tool to create or update `/memories/session/task-tracking.md`.

---

## Phase 6 — Lessons Learned Gate

Reflect before closing:

- Was the trackability verdict correct for this request type?
- Did the fuzzy match work well, or did it false-positive / miss?
- Was the synthesized title accurate and specific enough?
- Did the CLI commands succeed on the first attempt?
- Were the category/horizon/effort values sensible?

If any of the above revealed a gap or surprise: write an entry to `LessonsLearned.md`.
If the lesson applies globally (not codebase-specific): also write to `LessonsLearned.GLOBAL.md`.
If nothing went wrong: confirm explicitly — "Lessons learned: nothing to report."

Do not silently skip this step.

---

## Taxonomy of Request Types (Reference)

Use this when Phase 1 is ambiguous:

| Request pattern | Trackable? | Suggested effort |
|---|---|---|
| "Fix [specific bug]" | ✅ Yes | Small |
| "Add [new feature]" | ✅ Yes | Medium–Large |
| "Refactor [component]" | ✅ Yes | Medium |
| "Investigate [behavior]" | ✅ Yes | Small–Medium |
| "Deploy / run migration" | ✅ Yes | Small |
| "Write tests for [X]" | ✅ Yes | Small–Medium |
| "Create a plan / design doc" | ✅ Yes | Small |
| "What does [X] do?" | ❌ No | — |
| "Explain [concept]" | ❌ No | — |
| "Is [X] correct?" | ❌ No | — |
| "Thanks / looks good" | ❌ No | — |
