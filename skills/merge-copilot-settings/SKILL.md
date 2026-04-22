---
name: merge-copilot-settings
description: Merge settings.base.json from ~/Repos/vs-code-copilot-tools into the local VS Code settings.json. Use when syncing copilot settings after a git pull, setting up a new machine, or when asked to merge or apply base settings.
---

# Merge Copilot Settings — SKILL.md

## Purpose
Merges `settings.base.json` from `C:\Users\<username>\Repos\vs-code-copilot-tools\` into the local VS Code `settings.json`, preserving all machine-specific settings (connections, paths, terminal approvals) while applying the latest shared copilot configuration.

Use when: syncing copilot settings after a `git pull`, setting up a new machine, "merge my copilot settings", "apply base settings", "sync settings".

---

## What It Does

Reads `C:\Repos\vs-code-copilot-tools\settings.base.json` and merges every key from it into `%APPDATA%\Code\User\settings.json`. Keys in `settings.base.json` **overwrite** matching keys in the local file. Keys that only exist locally are preserved untouched.

This is a **shallow merge of top-level keys only** — nested objects (like `chat.promptFilesLocations`) are replaced wholesale by the base value, not deep-merged.

---

## Execution Steps

### Step 1 — Run the merge script

```powershell
$basePath  = "C:\Users\$env:USERNAME\Repos\vs-code-copilot-tools\settings.base.json"
$localPath = "$env:APPDATA\Code\User\settings.json"

$base  = Get-Content $basePath  -Raw | ConvertFrom-Json
$local = Get-Content $localPath -Raw | ConvertFrom-Json

# Merge: base keys overwrite local keys
$base.PSObject.Properties | ForEach-Object {
    $local | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
}

$local | ConvertTo-Json -Depth 10 | Set-Content $localPath -Encoding UTF8
Write-Host "Merged $($base.PSObject.Properties.Count) base keys into settings.json"
```

### Step 2 — Reload VS Code

After the script completes, reload VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`) for the changes to take effect.

### Step 3 — Verify

Confirm in VS Code Settings UI or by checking `settings.json` that:
- `chat.promptFilesLocations` contains both `~/Repos/vs-code-copilot-tools/prompts` and `~/Repos/vs-code-copilot-tools/agents`
- `chat.instructionsFilesLocations` contains `~/Repos/vs-code-copilot-tools/instructions`
- `chat.agentFilesLocations` contains `~/Repos/vs-code-copilot-tools/agents`
- `chat.agentSkillsLocations` contains `~/Repos/vs-code-copilot-tools/skills`
- `chat.hookFilesLocations` contains `~/Repos/vs-code-copilot-tools/hooks`
- `chat.useAgentSkills` is `true`
- `chat.useCustomAgentHooks` is `true`

---

## Notes
- Machine-specific settings (`mssql.connections`, `terminal.integrated.env`, `chat.tools.terminal.autoApprove`) are intentionally **not** in `settings.base.json` and will never be overwritten.
- If `settings.base.json` is updated in the repo, run this merge again after `git pull`.
- The merge is idempotent — running it multiple times is safe.

## Feedback Loop

Before starting, read `~/Repos/vs-code-copilot-tools/skills/merge-copilot-settings/LessonsLearned.GLOBAL.md` and, if it exists on disk, `~/Repos/vs-code-copilot-tools/skills/merge-copilot-settings/LessonsLearned.md`. Apply any recorded watch-outs.

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, follow the two-tier feedback loop from `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md`:
- **Codebase findings** (machine-specific paths, local settings quirks) → write to `LessonsLearned.md`
- **Process findings** (merge workflow improvements) → write to `LessonsLearned.GLOBAL.md`

Both files are at `~/Repos/vs-code-copilot-tools/skills/merge-copilot-settings/`.
