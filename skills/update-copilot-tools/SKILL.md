---
name: update-copilot-tools
description: Pull the latest copilot-tools repo, analyze every changed file, identify any required manual actions (settings merge, hook path validation, etc.), and end with a Lessons Learned session. Use when: syncing copilot tools, "pull my copilot tools", "update my skills", "get latest agents", "sync copilot configs", after receiving word that the other machine pushed changes.
---

# Update Copilot Tools — SKILL.md

## Purpose
Pulls `~/Repos/copilot-configs` from the remote, analyzes exactly what changed, flags any manual actions required to keep the local VS Code setup in sync, and ends with a Lessons Learned reflection.

---

## Execution Steps

### Step 0 — Read LessonsLearned
Read `LessonsLearned.GLOBAL.md` alongside this SKILL.md, and if it exists on disk, `LessonsLearned.md`. Apply any recorded watch-outs to this session.

### Step 1 — Check for uncommitted local changes
```powershell
cd "$env:USERPROFILE\Repos\copilot-configs"
git status --short
```
If any files are modified or staged, **stop and tell the user** — they may have unsaved edits that could be lost or conflict during the rebase. Ask whether to stash, commit, or abort before continuing.

### Step 2 — Record current HEAD and pull
```powershell
cd "$env:USERPROFILE\Repos\copilot-configs"
$beforeHead = git rev-parse HEAD
git pull --rebase
$afterHead = git rev-parse HEAD
```
- If the output contains `"Already up to date."` and `$beforeHead -eq $afterHead` — tell the user nothing changed and skip to Step 5 (Lessons Learned).
- If `git pull` exits non-zero, stop and report the error to the user. Do not continue.

### Step 3 — Identify what changed
```powershell
$changedFiles = git diff $beforeHead..$afterHead --name-only
$commits      = git log $beforeHead..$afterHead --oneline
Write-Host "Commits pulled:"; $commits
Write-Host "Files changed:"; $changedFiles
```

### Step 4 — Analyze changes and flag required actions
For each changed file, apply the rules in this table:

| Changed file(s) | Classification | Action |
|---|---|---|
| `settings.base.json` | **Manual action** | Show the key-level diff (see below), then ask the user: "Run merge-copilot-settings skill now?" |
| `hooks/*.json` | **Validate** | Read each changed hook JSON; check that every script path in the `windows` key resolves to a real file on disk (see below). Flag any that are broken. |
| `hooks/scripts/*.ps1` | Informational | No action — scripts load automatically |
| `agents/*.agent.md` | Informational | No action — VS Code auto-discovers |
| `prompts/*.prompt.md` | Informational | No action — VS Code auto-discovers |
| `instructions/*.instructions.md` | Informational | No action — VS Code auto-discovers |
| `skills/**` | Informational | No action — VS Code auto-discovers |
| `README.md` | Informational | Note it; optionally ask if the user wants a summary |
| `.gitignore` | Informational | No action |
| Any other file | **Flag for review** | Unexpected — describe the file and ask the user what to do |

**Showing the settings.base.json diff:**
```powershell
git diff $beforeHead..$afterHead -- settings.base.json
```
Display the raw diff so the user can see exactly which keys changed before deciding whether to merge.

**Validating hook script paths:**
For each changed `hooks/*.json`:
```powershell
$hook = Get-Content "C:\Users\$env:USERNAME\Repos\copilot-configs\hooks\<filename>.json" -Raw | ConvertFrom-Json
$hooks = $hook.hooks
$hooks.PSObject.Properties.Value | ForEach-Object { $_ } | ForEach-Object {
    $ps1Path = [regex]::Match($_.windows, '(?<=")[^"]+\.ps1(?=")').Value
    if ($ps1Path) {
        $resolved = $ps1Path -replace '\$env:USERPROFILE', $env:USERPROFILE
        $exists = Test-Path $resolved
        Write-Host "$resolved -> $exists"
    }
}
```
If any path returns `False`, flag it as broken and surface it in the Step 5 summary.

### Step 5 — Report summary
Present the user with:
- **Commits pulled:** list of commit messages
- **Files changed:** grouped by type (agents, prompts, skills, hooks, settings, other)
- **Required actions:** numbered list of everything the user must do (e.g., merge settings, fix a broken hook path)
- **Informational changes:** brief bullet list of auto-applied changes

### Step 6 — Execute approved actions
If the user approved the settings merge in Step 4, invoke the `merge-copilot-settings` skill now.

If any hook paths were flagged as broken, show the exact path that failed and ask the user how to resolve it before continuing.

### Step 7 — Lessons Learned
**Tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, follow the two-tier feedback loop: write process/model findings to `LessonsLearned.GLOBAL.md`, codebase findings to `LessonsLearned.md` alongside this SKILL.md.

---

## Notes
- The repo path is always `C:\Users\$env:USERNAME\Repos\copilot-configs` on Windows.
- VS Code auto-reloads agents, prompts, instructions, and skills from the filesystem — no VS Code reload needed for those. A reload **is** recommended after a settings merge or hook JSON change.
- If `settings.base.json` changed, always run `merge-copilot-settings` **before** reloading VS Code — otherwise the reload picks up stale location settings.
- `ORIG_HEAD` is unreliable when rebasing local commits on top of remote changes. Always capture `$beforeHead` before the pull instead.
