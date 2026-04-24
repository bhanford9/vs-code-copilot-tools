# VS Code Terminal Auto-Approve

A skill for adding or fixing VS Code auto-approval patterns so that Copilot agent terminal commands run without prompting for manual approval. Handles both simple commands and the PowerShell call-operator pattern (`& "path\script.ps1"`) that requires a different matching mode.

## The Problem It Solves

Every terminal command an agent runs requires user approval unless a matching pattern exists in `chat.tools.terminal.autoApprove` in `settings.json`. Getting patterns wrong is common: the wrong format, the wrong matching mode, a missing `^` anchor, or insufficient regex escaping can all cause VS Code to silently skip the pattern and keep prompting. This skill documents how the setting actually works and walks through writing a pattern that matches.

The failure mode that makes this non-obvious: commands using PowerShell's call operator (`& "C:\...\script.ps1"`) are **not recognized as standard subcommands** by VS Code's parser. A correct-looking pattern with `true` as the value will never match. These commands require `matchCommandLine: true` in the value object, which bypasses the parser and matches the raw command string instead.

## How It Works

```
Read lessons → Fetch official docs → Understand setting → Write pattern → Verify
```

1. **Read lessons** — Reads `LessonsLearned.GLOBAL.md` (and the local `LessonsLearned.md` if present) for any known pitfalls or version-specific quirks from past sessions.

2. **Fetch official docs** — Reads the live VS Code documentation for `chat.tools.terminal.autoApprove` before writing any patterns. The setting behavior and format have evolved across VS Code versions; the official docs are the ground truth.

3. **Understand the setting** — Distinguishes between the two matching modes and selects the right one:

   | Mode | Value format | When to use |
   |------|-------------|-------------|
   | **Subcommand matching** (default) | `true` or `false` | Most commands: `dotnet`, `git`, `mkdir`, etc. |
   | **Full command line matching** | `{"approve": true, "matchCommandLine": true}` | Any command starting with `&` (PowerShell call operator), or when subcommand parsing would miss the match |

4. **Write the pattern** — Scopes the pattern to the specific skill directory or command, anchors with `^`, escapes backslashes for JSON, and uses the correct value format for the selected mode. Covers any subcommands the script might call (e.g., `dotnet`, `docker`) that would still prompt if not separately approved.

5. **Verify** — Confirms the entry is syntactically valid in `settings.json`. Does not re-run the triggering script to test (scripts can have side effects). Instead, waits for the next natural invocation or constructs a harmless `echo`/`Write-Host` command with the same prefix.

## Pattern Format Quick Reference

```jsonc
"chat.tools.terminal.autoApprove": {
  // Simple subcommand match
  "dotnet build": true,

  // Regex with subcommand matching
  "/^git (status|show\\b.*)$/": true,

  // Full command line match — required for & "path\script.ps1"
  "/^& \".*\\\\skills\\\\my-skill\\\\scripts\\\\.*\\.ps1\"/": {
    "approve": true,
    "matchCommandLine": true
  }
}
```

Key rules:
- Wrap regex patterns in `/` delimiters
- Always include `^` to anchor to the start of the command
- Each literal `\` in the regex requires `\\` in the JSON key
- Scope patterns to the skill's directory, not a blanket `.ps1` match

## Reference Files

| File | Role |
|------|------|
| [`skills/vscode-terminal-auto-approve/SKILL.md`](../../skills/vscode-terminal-auto-approve/SKILL.md) | Full workflow, matching mode explanation, format examples, verification procedure |
| [`skills/vscode-terminal-auto-approve/LessonsLearned.GLOBAL.md`](../../skills/vscode-terminal-auto-approve/LessonsLearned.GLOBAL.md) | Process/model findings from past sessions: pattern format gotchas, VS Code version behavior, matching engine quirks (tracked in git) |
