# Lessons Learned: agentic-tools-auditor

> This file is updated automatically at the end of AgenticToolsAuditor sessions.
> Read it before starting any audit run to apply accumulated knowledge.

---

## User-Level Tools Audit — Session A (2026-04-13)

### False Negative: File Existence vs. Expected Content

The checking-csharp-errors SKILL.md was reported as entirely missing when it actually existed with different content than expected. The auditor should verify existence and content separately. Finding "no file" when a file exists is a High-confidence failure. Mitigation: add an explicit existence check step before evaluating content; report "file exists but lacks expected content" separately from "file not found."

### Preference Scope Extrapolation

When the user declined a hook for one specific item (#17 — orchestrator Stop hook for LessonsLearned), the agent extrapolated this as a general preference against hooks and segregated all subsequent hook proposals out of the main discussion. This was wrong. The user's reason was specific to that item (hook couldn't reason about session content; a flow step could). The agent should have recorded the reason and scope, then evaluated every subsequent hook proposal on its own merits. Rule added to SKILL.md: when a user declines a recommendation for one item, confirm scope explicitly before generalising.

### Architecture Proposals Need a Discussion Gate

Architecture proposals (agent splits, SessionStart hooks, phase-gate artifacts) were included in the roadmap without a collaborative review step. Some required a conversation before implementation (the Orchestrator split needed user confirmation of pain points). The user had to call this out. SKILL.md now requires architecture proposals to be held for explicit user discussion before being promoted to the roadmap.

### Roadmap Didn't Capture All Findings

Two clusters of findings (writing-csharp-tests improvements, REVIEW orchestration architecture proposals) fell outside the 20-item roadmap and were only caught in a separate cross-check pass at the end. The synthesis now includes a "Findings Outside the Roadmap" section to prevent this.

### Shared Severity Scale Required Across Auditors

"Medium" in one AUDIT.md was not comparable to "Medium" in another. The synthesis priority table was harder to trust as a result. SKILL.md now requires a severity calibration table in AUDIT-CONTEXT.md before individual auditors start.

### Structural Surgery Risk

When removing the synthesis section from the Orchestrator during A4, the closing `</workflow>` tag was silently lost. Not caught until the next session. When deleting multi-line regions from structured documents, explicitly verify that all paired open/close tags are intact afterward.

### Checklist Drift

Completed items were not always marked done immediately — items #7 and #8 were finished but the checklist wasn't updated until later. Checklists must be updated as each item completes, not batched.

---

## Initial Workspace Audit

### Most Common Issue Types

- **Always-on rules stored in skills** — appeared in 4 of 8 items (`coding-conventions`, `domain-modeling`, `unit-testing`, `tech-framework-skill`). Rules that should apply to every file of a given type (e.g., every `*.cs` file, every `*Tests.cs` file, every `*.xaml` file) were stored in skills that only load when semantically matched. Extract these into `.instructions.md` files with precise `applyTo` globs immediately — this is the highest-ROI change in almost every audit.

- **Zero automation (no hooks)** — all 8 skills audited had zero hook coverage. Binary rules stated in plain text are not enforced. Treat any rule labeled "critical" or "never do X" as an immediate hook candidate.

- **Missing LessonsLearned.md** — all 8 skills had no feedback loop file. Recommend creating one for every skill that covers a multi-step procedure.

- **Content defects** — 4 of 8 skills had content defects: truncated files, duplicated code blocks, missing examples for referenced variables, or broken references. Always perform a content integrity check (scan for truncation, duplication, dangling references) as the very first audit step before any dimension analysis.

### Documentation Notes

The documentation at the five URLs is accurate and current as of April 2026. Key capabilities to confirm on each audit run:
- Agent-scoped hooks (in `.agent.md` frontmatter `hooks:` field) are a Preview feature — check if they were promoted to stable.
- The `applyTo` field in `.instructions.md` controls automatic injection; confirm glob syntax hasn't changed.
- `user-invocable: false` on sub-agents prevents them from appearing in the chat dropdown — essential for the IndividualAuditor pattern.

### Hardest Dimension to Assess

**Dimension 7 (Cross-Skill Concerns)** was the hardest because it requires knowing the content of ALL other items, not just the one being audited. Sub-agents only have the inventory summary provided by the orchestrator. Fix: have the orchestrator include brief one-line summaries of EVERY other item's key rules in the invocation prompt, not just names. This significantly reduces false negatives in cross-skill conflict detection.

### Discovery Guide Updates Needed

- Add `**/*.chatmode.md` to the discovery scan — older VS Code versions used this extension for what are now `.agent.md` files. Workspaces being migrated may still have them.
- Check `~/.copilot/skills/` and `~/.copilot/agents/` for user-level configurations that affect all workspaces — these should be noted as out-of-scope for workspace audits but flagged if they duplicate workspace-level items.
- Skills in the workspace root (not under `.github/skills/`) are still valid if `chat.skillsLocations` is configured. Don't assume all skills live under `.github/skills/`.

### New Threshold / Vagueness Examples Found

The following terms from audited skills are reliable signals of low-determinism content. Flag all of these immediately during Dimension 2 analysis:
- "trivial" — used to excuse not performing a cleanup step
- "medium or larger" — used as a threshold with no definition (DataBuilder creation threshold)
- "if needed" — used to make optional something that should be conditional on a defined criterion
- "reasonable" — used in place of a concrete decision rule
- "appropriate" — synonym for "I haven't defined this"
- "some" — vague quantity with no bound

### Conflict Resolution Decisions Made

1. **Enum mapping strategy** — when `Enum.Parse` and Mapster `EnumMappingStrategy.ByName` both appear as alternatives in the same codebase, the Mapster approach is authoritative. `Enum.Parse` should be removed because it throws on unknown values and is case-sensitive. The skill with the more permissive suggestion should cross-reference the stricter skill.

2. **Mapper method naming** — apparent conflicts between `ToModel()`/`ToEntity()` (application-layer names) and `MapToDomain()`/`MapToStorage()`/`UpdateFrom()` (infrastructure-layer names) are NOT conflicts — they operate at different layers with different directionality. When both appear, verify direction before flagging as a conflict.

### Process Notes

- Sub-agent parallelism worked well up to 8 agents. For 9+ items, split into waves of 8. Attempting >10 parallel agents in one batch caused context management issues in this session.
- Sub-agent prompts need to include the file contents inline (not just the path). Sub-agents that only received a path spent context budget on file reads that the orchestrator already performed.
- The AUDIT-CONTEXT.md file (documentation summary written by the orchestrator) should be concise — a 2-paragraph summary per tool type. Full documentation dumps made sub-agents lose focus. The SKILL.md quick-reference table is sufficient for most fit assessment needs.
- When a skill is very large (>200 lines), include only the most relevant sections in the sub-agent prompt rather than the full file. The IndividualAuditor can read the complete file itself if needed.

---

## User-Level Tools Audit — Session B

### Most Common Issue Types

- **Skill directory name mismatch** — appeared in 4 of 5 skills. Directory uses Title Case+spaces; `name` frontmatter uses lowercase-hyphens. VS Code may silently fail to load these skills. This was the single highest-frequency finding in the session and affects ALL skills in the `~/.copilot/skills/` directory. Always check this FIRST before any other dimension analysis.

- **Hard-coded absolute paths in agent bodies** — appeared in 3 agents (AzureStoryCreation, UnitTestWriter, agentic-tools-auditor). All paths use `~/.copilot/skills/...` with spaces in the directory name, compensating for the directory name mismatch in Theme 1. Once directories are renamed, all hard-coded paths must be updated simultaneously.

- **Critical content defects** — 3 items had file-corrupting or runtime-breaking defects: (1) `CreatePlan.prompt.md` uses `${prompt}` (invalid — should be `${input:variableName}`); (2) `PrepareCommitReview.prompt.md` has truncated step + undefined variable; (3) `07-WorkItemCreator.md` has wrong extension (`.md` instead of `.agent.md`). These cause silent failures on every invocation.

- **Missing `disable-model-invocation: true` on sub-agents** — 6 of 9 code review pipeline agents lack this flag, allowing VS Code semantic matching to invoke pipeline-stage agents out of context.

- **Zero LessonsLearned for high-churn skills** — 4 of 5 skills had no LessonsLearned.md. The `writing-csharp-tests` skill generates the most session activity (UnitTestWriter references it 4+ times per session) and had the highest practical need.

### Documentation Notes

- All five documentation URLs are current and accurate as of 2026-04-10.
- **New finding vs. prior session:** VS Code now supports 8 hook lifecycle events (added `PreCompact`, `SubagentStart`, `SubagentStop`, `UserPromptSubmit`). Prior session only documented 4. Update SKILL.md reference table to include the 4 new events.
- **`infer` field is deprecated** — replaced by `user-invocable` + `disable-model-invocation`. Any `.agent.md` using `infer:` should be updated. Not found in this session's files but worth adding to checklist.
- **Agent-scoped hooks in frontmatter** remain in Preview (`chat.useCustomAgentHooks` required). The agentic-tools-auditor agent already uses them — flag this when the feature is stable.
- **Skills standard now open (agentskills.io)** — portability is a genuine feature, not aspirational. User-level skills at `~/.copilot/skills/` work across workspaces, confirmed.

### Hardest Dimension to Assess

**Dimension 5 (Automation Opportunities / Hooks)** was hardest for this session because the user's configuration has zero existing hooks (except one reminder-only Stop hook) — making it difficult to calibrate what level of hook automation is appropriate vs. over-engineered. The tension is real: PostToolUse hooks that run on every file edit add latency, but the "NEVER use get_errors" rule would benefit enormously from a hook. Resolution guidance: reserve PostToolUse hooks for rules labeled "NEVER" / "ALWAYS" / "Critical" in the source item — these signal binary enforcement is intended.

### Discovery Guide Updates Needed

- **Scan `~/.copilot/agents/` for .md files** — VS Code may detect plain `.md` files in the agents folder (per workspace-level docs about `.github/agents/`). Found `07-WorkItemCreator.md` in this folder — its detection status is ambiguous. Add to discovery scan.
- **Scan VS Code user data folder** (`AppData\Roaming\Code\User\prompts\` on Windows) — this is where VS Code stores user-level agents and prompts. On Windows, this is NOT the same as `~/.copilot/agents/`. Both locations had files; VS Code user data was the primary source.
- **Check for `.chatmode.md` files** (from prior session note) — not found in this session but still relevant for migration detection.
- **Multiple items in a single folder**: When there are >5 agents in one folder with no subfolder organization, audit them as functional groups (discovery pipeline, code review pipeline) rather than individually — this produces more actionable cross-pipeline findings.

---

## User-Level Tools Audit — Session C (2026-04-13)

### Most Common Issue Types

- **Missing `agents:` frontmatter on subagent-spawning agents** — appeared in 4 agents (InitialPlanner, RefinedPlanner, AzureStoryCreation, UnitTestWriter). All use the `agent` tool to spawn subagents but omit the `agents:` frontmatter list. Always check this when any agent has `agent` in its tools list.

- **Hard-coded absolute paths in agent bodies** — appeared in 3 agents (AzureStoryCreation, UnitTestWriter). All encode `~/.copilot/skills/...`. Replacing with `~/.copilot/skills/...` is the portable fix.

- **Missing `disable-model-invocation: true` on pipeline sub-agents** — the `Implementation` agent (full terminal access) and all discovery mid-pipeline agents lacked this flag. Always flag this for any agent with `edit` or terminal tools that is not an entry point.

- **Critical failure modes in LessonsLearned never promoted to SKILL body** — writing-csharp-tests had this. Recommend a "Known Failure Modes" section in every SKILL.md populated from LessonsLearned entries.

- **Broken skill reference** — `checking-csharp-errors` SKILL.md was entirely missing; only LessonsLearned.md existed. This causes silent failure on every skill load attempt. Always check for skill directories with ONLY a LessonsLearned.md.

### Documentation Notes (2026-04-13)

- All five documentation URLs are current and accurate as of April 2026. No changes from previous session's notes.
- **`infer` confirmed deprecated** — docs explicitly show migration path to `user-invocable` + `disable-model-invocation`. Flag any agent using `infer:`.
- **VS Code detects `.md` files in `~/.copilot/agents/`** — confirmed in docs for `.github/agents/` folder; behavior for `~/.copilot/agents/` is ambiguous. `07-WorkItemCreator.md` was present with wrong extension — may or may not load.
- **Agent-scoped hooks remain Preview** — `chat.useCustomAgentHooks: true` required.
- **All 5 REVIEW parallel auditors had `user-invocable: false`** — the task brief had this wrong (only MaintainabilityAuditor was observed to have it during inventory scan). Sub-agent reading the actual files was more accurate. Always trust actual file reads over inventory scan assumptions when inconsistencies appear.

### Hardest Dimension to Assess

**Dimension 3 (Correctness & Dependability)** was hardest for items with companion files (e.g., `creating-azure-stories` has TEMPLATE.md, FORMAT_RULES.md, EXAMPLES.md). The SKILL.md says "see TEMPLATE.md" but contradictions between companion files require reading ALL companion files, not just the SKILL.md. The sub-agent found a real format contradiction between TEMPLATE.md and FORMAT_RULES.md that wasn't visible from the SKILL.md alone. Fix: always instruct sub-agents to read companion files for skills with multiple reference documents.

### Process Notes

- 8-task parallel batch completed without context issues — confirmed the 8-batch limit holds.
- Sub-agents with grouped items (pipeline phases 1-4, 5-8, REVIEW orchestration, REVIEW auditors+prompts) produced better cross-pipeline findings than individual item audits would have.
- Task files with inline file contents landed sub-agents faster — they spent almost no budget on file reads.
- A sub-agent corrected an inventory mistake (user-invocable status on REVIEW parallel auditors). This confirms sub-agents should always read actual files rather than trusting the orchestrator's inventory table for correctness details.
- The `7 → 9 new hook lifecycle events` note from the previous session is already incorporated correctly — 8 was the correct number for this session too.

### New Threshold / Vagueness Examples Found

- `"85% confidence"` and `"90% confidence"` — both used without defining what constitutes evidence or how to count. Different numbers in different agents (AzureStoryCreation: 85%, UnitTestWriter: 90%, each secondary gate: 70%). Inconsistent thresholds with no shared definition.
- `"Read ALL files in [directory]"` — in AzureStoryCreation agent. Undefined agent behavior — agents cannot list directories. Should always be explicit file paths.  
- `"research-driven, thorough, methodical"` — personality tag language that is pure atmosphere with no behavioral specification. Flag all personality descriptors as Dimension 2 vagueness markers.

### Conflict Resolution Decisions Made

1. **Azure DevOps story format conflict**: `creating-azure-stories` skill (H2 Markdown sections) vs. `WorkItemCreator` agent (inline Key:Value with `*` bullets). **Decision: creating-azure-stories skill is authoritative.** The skill has full structural documentation (FORMAT_RULES.md, TEMPLATE.md, EXAMPLES.md). The WorkItemCreator approach lacks companion guidance and predates the dedicated skill. `CreateWorkItems.prompt.md` should route to `AzureStoryCreation` agent.

2. **Heading level conflict within `creating-azure-stories` skill**: SKILL.md uses H2 (`## Blocked By`); TEMPLATE.md uses H3 (`### Blocked By`). **Decision: H2 is authoritative.** SKILL.md and FORMAT_RULES.md both use H2, and H2 matches Azure DevOps section rendering expectations. TEMPLATE.md is the outlier to fix.

3. **"Start Implementation" handoff target**: Planning pipeline agents handoff to `agent: agent` (generic built-in). **Decision: `agent: Implementation` is authoritative.** The `08-Implementation` agent exists specifically for this purpose and provides guardrails (GapFinder handoff, context awareness, quality emphasis) that the generic agent does not.

### Process Notes

- **31-item audit in 4 parallel waves worked well** using groups: Wave 1 (5 skills + 3 agents), then 4 remaining items in parallel. Total individual audit invocations: 12 (batching pipeline items as groups significantly reduced overhead).
- **Discovery required two folder systems on Windows**: `~/.copilot/skills/` and `AppData/Roaming/Code/User/prompts/`. The `~/.copilot/agents/` directory EXISTS but its files are synced from the VS Code user data folder — it's a read replica. Always use VS Code user data as the canonical source for agents/prompts.
- **Inventory context in sub-agent prompts paid off**: Including brief descriptions of cross-pipeline interactions (e.g., "UnitTestWriter references this skill 4 times per session") helped sub-agents produce higher-quality Dimension 7 (cross-skill) analysis without needing to read other files.
- **Grouping pipeline items into one audit prompt was effective**: The discovery pipeline (7 agents) and review pipeline (9 agents) were each audited in single sub-agent calls, which surfaced pipeline-level defects (missing step 07, wrong handoff targets) that per-item audits would have missed.

---

## Hook scripts: tilde path fails on Windows with `-File` (2026-04-13)

**Issue:** A hook configured with `powershell -NoProfile -File "~/.copilot/hooks/scripts/script.ps1"` fails on Windows with:
> The argument '~/.copilot/hooks/scripts/script.ps1' to the -File parameter does not exist.

**Cause:** PowerShell's `-File` parameter does not expand `~`. The tilde is only resolved interactively by the shell, not when passed as a literal path argument.

**Fix:** Use separate `windows` and `command` keys. On `windows`, replace `~` with `$env:USERPROFILE`:

```json
{
  "type": "command",
  "windows": "powershell -NoProfile -File \"$env:USERPROFILE/.copilot/hooks/scripts/script.ps1\"",
  "command": "powershell -NoProfile -File \"~/.copilot/hooks/scripts/script.ps1\"",
  "timeout": 10
}
```

**Audit check:** When auditing hook JSON on Windows, flag any `command` or `windows` value that passes a `~`-prefixed path to `powershell -File`. The non-Windows `command` field may keep `~` since POSIX shells expand it correctly.

---

## copilot-configs Workspace Audit — Session D (2026-04-21)

### Both disable-model-invocation AND user-invocable: false = completely unreachable agent
`individual-auditor.agent.md` had BOTH `user-invocable: false` AND `disable-model-invocation: true`. Per VS Code docs, the combination makes the agent unreachable via any mechanism: not from the picker, not via handoff, not via agent tool. `AgenticToolsAuditor` had `agents: [individual-auditor]` and called it via agent tool — all those invocations fail silently. When auditing sub-agents, always check that parallel/programmatic sub-agent targets have `user-invocable: false` ONLY (no `disable-model-invocation`).

### Hook exit-code mismatch: script says blocking but exits 0
`check-test-comments.ps1` had a code comment stating "exits 2 (blocking) if comments are found" but the actual exit code was 0 in the violation path. The hook ran and reported findings but never blocked anything. When auditing hook scripts, always verify the exit code in the actual violation branch — a comment claiming blocking behavior is not the same as actually blocking. Add exit code checks to the Dimension 6 structural checklist.

### Prompts driving multi-step workflows silently fail without `mode: agent`
`review-lessons.prompt.md` and `fork-and-improve.prompt.md` both contained instructions to read files and make edits, but had no `mode: agent` or `agent:` frontmatter. In default (ask/chat) mode, the agent reads the prompt but cannot execute file operations. No error is shown — it just doesn't work. When auditing prompts, always check: if the body contains "read", "edit", "write", or "run", it needs `mode: agent`.

### grep_search may return stale results for deleted files
`grep_search` returned a match for `skills/summarize-meeting-transcript/SKILL.md` which did not exist on disk (verified via `Test-Path`). This is a VS Code search cache artifact. Always verify existence with a terminal command when a grep hit seems unexpected. The discovery guide should note this caveat.

### Process: Explore sub-agents cannot write files; use unnamed sub-agents for file creation
`runSubagent` with `agentName: "Explore"` returns results but cannot create files — the Explore agent is read-only. Use `runSubagent` without `agentName` (or with a file-writing capable agent) when AUDIT.md files need to be written. Useful pattern: use Explore for analysis tasks that return summaries, use unnamed sub-agents for tasks that must create files.

### 54-item audit with 6 parallel waves completed without context issues
Full workspace audit of 54 items (23 agents, 18 skills, 8 prompts, 3 instructions, 2 hooks) completed in 6 parallel sub-agent waves. Waves were sized 5-13 items. No context management issues. Inline file contents in sub-agent prompts were effective for agent bodies; sub-agents instructed to read skill SKILL.md files themselves (too large to inline) was also effective.

### SessionStart Path Injection Is Not Feasible for Multi-Workspace Configs

A `SessionStart` hook to write the copilot-configs root path to a temp file was explored as an alternative to hard-coded install paths. It was rejected because:

- copilot-configs is loaded as a **secondary** skills/agents/hooks source into other workspaces via VS Code settings — agents run in the context of the active project workspace, not the copilot-configs directory.
- The hook fires in the active workspace context, making `$PSScriptRoot` and workspace-relative paths unreliable for identifying where copilot-configs itself lives.
- A per-session temp file could be made workspace-specific to avoid multi-session collisions, but the workspace context problem remains unsolvable without VS Code exposing the secondary config root as a variable.

**Rule:** Do not propose `SessionStart` hooks for path injection in multi-workspace configurations. The documented install location (`~/Repos/copilot-configs/`) is the correct and sufficient constraint. Hard-coded paths are intentional, not a defect.

---


---

## Review Pipeline Handoff Breakage (2026-04-14)

### user-invocable: false breaks handoff buttons - never set this on handoff targets

user-invocable: false makes an agent reachable only "as a subagent or programmatically" per VS Code docs. Handoff button clicks are user-initiated transitions, NOT programmatic invocations - VS Code cannot switch to an agent with this flag when the user clicks a handoff button. The button renders but does nothing; the active agent silently retains control and processes the next prompt itself.

Affected agents during this incident: REVIEW-RequirementsAuditor, REVIEW-CodeCorrectnessAuditor, REVIEW-FinalSynthesizer - all had user-invocable: false, so every handoff in the sequential pipeline was broken.

Rule: Any agent that appears as a handoffs.agent target must NOT have user-invocable: false. Use disable-model-invocation: true instead if you want to prevent unintended semantic invocation while keeping handoffs functional.

### disable-model-invocation: true blocks subagent invocation - never set this on parallel-auditor agents

disable-model-invocation: true prevents the agent from being invoked as a subagent by other agents. For agents that a coordinator must launch via the agent tool (the 5 REVIEW parallel auditors), this flag makes coordinator invocation silently fail.

Rule: Agents intended as subagent targets must NOT have disable-model-invocation: true. Use user-invocable: false alone to hide them from the picker while keeping them invocable.

### Correct flag matrix for review pipeline

| Agent role | user-invocable | disable-model-invocation | Rationale |
|---|---|---|---|
| Entry point (Orchestrator, Coordinator) | default (true) | optional | Visible in picker; flag acceptable if semantic cold-start is undesirable |
| Sequential handoff targets (RequirementsAuditor, CorrectnessAuditor, FinalSynthesizer) | default (true) | true (acceptable) | Reached via handoff buttons; flag prevents unintended semantic invocation |
| Parallel auditors (5 agents) | false | **must be absent** | Hidden from picker; must be invocable via agent tool by Coordinator — flag would break all invocations |

### Blanket Policy: Never Use `tools:` Restrictions on Agents

User policy (2026-04-21): **Do not add or recommend `tools:` frontmatter lists on agents.** Tool names change frequently in VS Code, making these lists a constant maintenance burden. The performance difference between restricted and unrestricted tool access is negligible. Agents should run with all available tools.

**Audit implication:** Never flag a missing `tools:` list as a defect. Never recommend adding one. If a `tools:` list already exists and is causing breakage (e.g., a renamed tool no longer resolves), recommend removing it rather than updating it.

---

### Policy: Use `disable-model-invocation: true` Only in Special Situations

User policy (2026-04-21, revised): **Use `disable-model-invocation: true` only when intentionally preventing semantic/unintended invocation for agents that are reached exclusively via handoff buttons or direct user switching** — never add it reflexively.

What this flag actually prevents:
- VS Code from semantically matching and suggesting the agent out of context
- Other agents from invoking it via the `agent` tool (subagent invocation)

What this flag does NOT prevent:
- Handoff button clicks (user-initiated transitions — these work fine)
- A user manually switching to the agent in the picker

**When it is appropriate:** Mid-pipeline stage agents (e.g., GapFinder, GapResolver, ArchitecturalDesigner, Implementation, review pipeline sequential stages) that should not be cold-started by semantic matching. These are reachable via handoff buttons and not invoked via agent tool — the flag is safe and intentional.

**When it is NOT appropriate:**
1. **Never** use it on agents that another agent must invoke via the `agent` tool (parallel sub-agents, individual auditors). It will silently block all agent-tool invocations.
2. **Never** combine it with `user-invocable: false` — that combination makes the agent completely unreachable.

**Audit implication:** Do not flag the presence of `disable-model-invocation: true` as an automatic defect. Evaluate intent: if the agent is a pipeline stage reached only via handoffs, the flag is correct. If the agent needs to be launched via agent tool, it must be removed. If both flags are present together, that is always a defect.

The access-control flag `user-invocable: false` remains for agents hidden from the picker (parallel sub-agents invoked exclusively via the `agent` tool).
