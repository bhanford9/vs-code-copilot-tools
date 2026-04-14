# VS Code Copilot Tools

Shared configuration for VS Code GitHub Copilot across machines — agents, prompts, instructions, skills, and hooks — managed as a git repo.

---

## Structure

```
copilot-configs/
  agents/          ← *.agent.md  (custom agents invokable with @AgentName)
  prompts/         ← *.prompt.md (slash-command prompts, e.g. /CreatePlan)
  instructions/    ← *.instructions.md (auto-attached context rules)
  skills/          ← SKILL.md subfolders (domain knowledge loaded by agents)
  hooks/           ← *.json + scripts (pre/post-turn automation)
  settings.base.json  ← shared VS Code copilot settings (no machine-specific values)
  .gitignore
  README.md
```

---

## How We Got Here

### What we used to do — zip file transfer

Configuration was split across two locations:
- `%APPDATA%\Code\User\prompts\` — prompts and agents
- `%USERPROFILE%\.copilot\` — skills, hooks, instructions

Syncing between machines meant running a `copilot-tools-packager` skill to zip everything up, physically copying the zip to the other machine, then running a `copilot-tools-unpackager` skill to restore it. This was fragile, had no history, and created constant drift between machines.

### Lessons learned (so you don't repeat them)

**1. Don't use `%USERPROFILE%\.copilot\agents\` as a storage location.**
VS Code does not load agents from there. Agents must be in a directory registered under `chat.agentFilesLocations` (or `chat.promptFilesLocations`). We wasted time moving files in and out of that folder before discovering this.

**2. VS Code does not allow absolute paths in location settings.**
Settings like `chat.promptFilesLocations` reject `C:/Users/...` style paths. Use `~/` relative paths instead (e.g. `~/Repos/copilot-configs/agents`). This is why the repo lives at `~/Repos/copilot-configs` — it maps cleanly to `~` on any Windows machine regardless of username.

**3. `settings.json` contains machine-specific values that must not be shared.**
Connection strings, terminal auto-approve entries, and absolute file paths are all machine-specific. Only the copilot/chat settings belong in `settings.base.json`. Use the `merge-copilot-settings` skill to apply base settings on top of your local file without overwriting the machine-specific parts.

**4. All 5 VS Code location settings must be explicitly configured.**
It's not enough to set `chat.promptFilesLocations`. VS Code has separate settings for each type:
- `chat.promptFilesLocations` — prompts
- `chat.agentFilesLocations` — agents
- `chat.instructionsFilesLocations` — instructions
- `chat.agentSkillsLocations` — skills
- `chat.hookFilesLocations` — hooks

If any of these are missing, that type of config simply won't load — no error, just silence.

**5. Don't mix prompts and agents into the same `%APPDATA%\Code\User\prompts\` folder.**
It works, but it's impossible to manage cleanly. Keeping them in separate directories under this repo makes git history readable and avoids confusion about what belongs where.

---

## First-Time Setup on a New Machine

### 1. Clone the repo

The repo **must** live at `~/Repos/copilot-configs` (i.e. `C:\Users\<you>\Repos\copilot-configs`). The `~/` paths in VS Code settings resolve relative to your home directory, so this location is required.

```powershell
git clone https://github.com/bhanford9/vs-code-copilot-tools "$env:USERPROFILE\Repos\copilot-configs"
```

### 2. Apply the shared settings

Use the `merge-copilot-settings` skill, or run this directly:

```powershell
$basePath  = "$env:USERPROFILE\Repos\copilot-configs\settings.base.json"
$localPath = "$env:APPDATA\Code\User\settings.json"

$base  = Get-Content $basePath  -Raw | ConvertFrom-Json
$local = Get-Content $localPath -Raw | ConvertFrom-Json

$base.PSObject.Properties | ForEach-Object {
    $local | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
}

$local | ConvertTo-Json -Depth 10 | Set-Content $localPath -Encoding UTF8
Write-Host "Settings merged."
```

This overwrites only the copilot-related keys. All your machine-specific settings (connections, terminal approvals, etc.) are preserved.

### 3. Reload VS Code

`Ctrl+Shift+P` → `Developer: Reload Window`

Verify in the Settings UI that all 5 location settings are populated and pointing to `~/Repos/copilot-configs/{type}`.

---

## Ongoing Workflow

```powershell
# Before starting work — pull latest
git pull --rebase

# After making changes — push
git add -A
git commit -m "Brief description of what changed"
git push
```

`REVIEW-LessonsLearned.md` (in `agents/`) is the most frequently updated file. Pull before editing it to avoid merge conflicts.

---

## What Is NOT in This Repo

| Excluded | Why |
|---|---|
| `*.log`, `*.zip` | Machine-local runtime data |
| `command-history-state.json` | Machine-local |
| `config.json` | Machine-local |
| Machine-specific `settings.json` entries | Managed locally per machine; `settings.base.json` covers only shared values |
