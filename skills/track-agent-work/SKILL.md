---
name: track-agent-work
description: Track an agent coding session using the TaskTracker (tt) CLI — create a task, start it, do the work, and mark it complete.
applyTo: "**"
---

# track-agent-work Skill

## Purpose

Use the `tt` CLI to create, start, and complete a TaskTracker task that records this agent session. Provides an auditable history of agent work with full lifecycle visibility.

---

## Non-Negotiable Rules

### Rule 1 — Always Extract `.data` from CLI Responses

Every `tt` command returns a `{ "success": bool, "data": <object|array>, "error": string|null }` envelope. **Never** access properties directly on the raw JSON — always extract `.data` first:

```powershell
$raw  = tt add --title "..." | Out-String
$task = ($raw | ConvertFrom-Json).data   # object with PascalCase properties
$id   = $task.Id                         # Id, Title, Status, IsDeleted, ...

$raw  = tt list | Out-String
$list = ($raw | ConvertFrom-Json).data   # array of task objects
```

Writing `$result.Id` directly on the envelope silently returns `$null`. This is the most common failure pattern when scripting `tt`.

---

### Rule 2 — Use `session-start`, Not `start`

Always prefer `tt session-start --task-id <id>` over `tt start --id <id>`. Both transition the task to **InProgress** with no eligibility checks, but only `session-start` writes a `SessionStarted` history entry — the only record that an agent touched the task.

**Note the different parameter name:** `session-start` uses `--task-id`; `start` uses `--id`.

---

### Rule 3 — Always Target Production

This skill tracks **real agent work** on the live board. Always set `ASPNETCORE_ENVIRONMENT` to `Production` before each `tt` command and clear it afterward:

```powershell
$env:ASPNETCORE_ENVIRONMENT = 'Production'
$raw = tt add --title "Agent: ..." | Out-String
$env:ASPNETCORE_ENVIRONMENT = ''
```

Never use the Development database for task tracking — tasks created there do not appear on the live board and will not be visible in any human-facing review.

---

## Standard Workflow

| Step | Command |
|------|---------|
| 1. Create | `tt add --title "Agent: <description>" --horizon Today --effort <Low\|Medium\|High> --category <slug>` |
| 2. Start | `tt session-start --task-id <id>` |
| 3. Do the work | *(agent performs the task)* |
| 4. Complete | `tt done --id <id>` |
| 5. Block (if needed) | `tt block --id <id>` — sets `IsBlocked = true`, does not change status |

---

## Status Reference

```
0 = Pending
1 = QueuedForDispatch
2 = InProgress
3 = DispatchFailed
4 = Completed
```

`Blocked` was removed as a status value. Blocking is now an orthogonal boolean (`IsBlocked`) set via `tt block`. `CompletedAt != null` is the authoritative completion signal; status `4` is also reliable.
