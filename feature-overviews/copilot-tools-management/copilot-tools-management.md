# Copilot Tools Management

Two skills for keeping this repo's configuration synchronized across machines. One pulls the latest changes and decides what needs to happen. The other applies shared VS Code settings without overwriting machine-specific ones.

## The Problem It Solves

This repo lives on multiple machines. When changes are pushed from one machine, the other needs to pull them — but a raw `git pull` isn't enough. Some changes require follow-up actions: settings keys need to be merged, hook script paths may need validation. Without a systematic process, it's easy to end up with stale settings or broken hooks after a sync.

## The Two Skills

### `/update-copilot-tools`

The primary sync workflow. Pulls the latest from remote, analyzes every changed file, and determines what action (if any) each change requires.

The key insight: not all changes are equal. Agent files, prompts, instructions, and skills are auto-discovered by VS Code — pulling them is enough. But `settings.base.json` changes require an explicit merge step, and hook changes require path validation. This skill categorizes each changed file and surfaces only what actually needs attention.

**Safeguards built in:**
- Checks for uncommitted local changes before pulling — stops if any are found to prevent conflicts
- Validates hook script paths after hook file changes — flags broken paths before they silently fail
- Shows the raw settings diff before asking whether to merge — no surprises

After surfacing required actions, it hands off to `merge-copilot-settings` if a settings merge was approved.

### `/merge-copilot-settings`

Merges `settings.base.json` into the local `settings.json`. Shared settings (agent locations, skill paths, hook config) overwrite local equivalents. Machine-specific settings (database connections, terminal approvals, environment paths) are untouched because they're never in `settings.base.json`.

The merge is a shallow overwrite of top-level keys — intentionally simple and idempotent. Running it multiple times is safe.

Can be invoked standalone (e.g., after setting up a new machine) or as part of the `update-copilot-tools` flow.

## Typical Flow

```
/update-copilot-tools
  → git pull --rebase
  → analyze changed files
  → flag settings.base.json changes → merge-copilot-settings
  → validate hook paths → surface any broken paths
  → report summary
```

## Reference Files

| File | Role |
|------|------|
| [`skills/update-copilot-tools/SKILL.md`](../../skills/update-copilot-tools/SKILL.md) | Full sync workflow with file classification table and step-by-step execution |
| [`skills/update-copilot-tools/LessonsLearned.GLOBAL.md`](../../skills/update-copilot-tools/LessonsLearned.GLOBAL.md) | Accumulated watch-outs from past sync sessions |
| [`skills/merge-copilot-settings/SKILL.md`](../../skills/merge-copilot-settings/SKILL.md) | Settings merge workflow, merge script, and verification steps |
| [`skills/merge-copilot-settings/LessonsLearned.GLOBAL.md`](../../skills/merge-copilot-settings/LessonsLearned.GLOBAL.md) | Accumulated watch-outs from past merge sessions |
| [`settings.base.json`](../../settings.base.json) | The shared settings that get merged into local settings.json |
