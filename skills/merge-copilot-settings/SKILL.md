# Merge Copilot Settings — SKILL.md

## Purpose
Merges `settings.base.json` from `C:\Repos\copilot-configs\` into the local VS Code `settings.json`, preserving all machine-specific settings (connections, paths, terminal approvals) while applying the latest shared copilot configuration.

Use when: syncing copilot settings after a `git pull`, setting up a new machine, "merge my copilot settings", "apply base settings", "sync settings".

---

## What It Does

Reads `C:\Repos\copilot-configs\settings.base.json` and merges every key from it into `%APPDATA%\Code\User\settings.json`. Keys in `settings.base.json` **overwrite** matching keys in the local file. Keys that only exist locally are preserved untouched.

This is a **shallow merge of top-level keys only** — nested objects (like `chat.promptFilesLocations`) are replaced wholesale by the base value, not deep-merged.

---

## Execution Steps

### Step 1 — Run the merge script

```powershell
$basePath  = "C:\Users\$env:USERNAME\Repos\copilot-configs\settings.base.json"
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
- `chat.promptFilesLocations` contains both `~/Repos/copilot-configs/prompts` and `~/Repos/copilot-configs/agents`
- `chat.instructionsFilesLocations` contains `~/Repos/copilot-configs/instructions`
- `chat.useAgentSkills` is `true`
- `chat.useCustomAgentHooks` is `true`

---

## Notes
- Machine-specific settings (`mssql.connections`, `terminal.integrated.env`, `chat.tools.terminal.autoApprove`) are intentionally **not** in `settings.base.json` and will never be overwritten.
- If `settings.base.json` is updated in the repo, run this merge again after `git pull`.
- The merge is idempotent — running it multiple times is safe.
