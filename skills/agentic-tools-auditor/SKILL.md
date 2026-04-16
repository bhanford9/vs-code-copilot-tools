---
name: agentic-tools-auditor
description: "Audit VS Code Copilot agentic workspace configurations including Skills (SKILL.md), Custom Agents (.agent.md), Custom Instructions (.instructions.md, copilot-instructions.md, AGENTS.md), Prompt Files (.prompt.md), and Hooks (.github/hooks/*.json). Produces per-item AUDIT.md files and a synthesized recommendations report. Use when: reviewing skills, auditing copilot customization, analyzing agent configurations, improving agentic determinism, workspace agentic tools review, agentic environment audit."
---

# Agentic Tools Auditor

Before beginning any audit work, read [LessonsLearned.GLOBAL.md](./LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](./LessonsLearned.md).

## Purpose

This skill provides a systematic framework for auditing VS Code Copilot agentic tool configurations in any workspace. It identifies mismatches between the tool type currently used and the tool type that would produce better determinism, automation, and quality — and surfaces opportunities for hooks-based enforcement and LessonsLearned feedback loops.

---

## Documentation Sources

Always fetch and review the following URLs before auditing. These pages define the full range of customization mechanisms and are the authoritative reference for fit assessment:

| URL | Covers |
|---|---|
| https://code.visualstudio.com/docs/copilot/customization/custom-instructions | `.instructions.md`, `copilot-instructions.md`, `AGENTS.md`, `applyTo` globs, always-on vs file-scoped |
| https://code.visualstudio.com/docs/copilot/customization/custom-agents | `.agent.md`, `tools`, `agents`, `handoffs`, `hooks`, `user-invocable`, model selection |
| https://code.visualstudio.com/docs/copilot/customization/agent-skills | `SKILL.md` format, `description` matching, portability, `user-invocable`, `disable-model-invocation` |
| https://code.visualstudio.com/docs/copilot/customization/prompt-files | `.prompt.md`, slash commands, `agent`, `model`, `tools` in prompts |
| https://code.visualstudio.com/docs/copilot/customization/hooks | Hook lifecycle events, `PostToolUse`, `Stop`, `SessionStart`, hook JSON format, agent-scoped hooks |

---

## VS Code Tool Type Quick Reference

Use this table as the primary guide for fit assessment:

| Tool Type | Trigger | Best For | File Location |
|---|---|---|---|
| **Always-on Instructions** | Every chat request automatically | Project-wide coding standards, architecture invariants, tech stack conventions | `.github/copilot-instructions.md` or `AGENTS.md` at workspace root |
| **File-scoped Instructions** | Automatic when files match `applyTo` glob | Language/framework/pattern rules specific to a file type | `.github/instructions/*.instructions.md` |
| **Agent Skills** | On-demand: semantic matching or `/slash` command | Specialized procedural workflows, complex reference docs, portable multi-step capabilities | `.github/skills/{name}/SKILL.md` |
| **Custom Agents** | Explicit: user picks from dropdown (`@AgentName`) | Persistent persona with tool restrictions, specific model, handoffs between roles, scoped hooks | `.github/agents/*.agent.md` |
| **Prompt Files** | Explicit: user types `/prompt-name` | One-shot user-initiated tasks, scaffolding templates, direct-invocation workflows | `.github/prompts/*.prompt.md` |
| **Hooks** | Deterministic: lifecycle events (PostToolUse, Stop, etc.) | Automated linting/validation, enforcing binary rules, audit trails, LessonsLearned updates | `.github/hooks/*.json` |

### The LessonsLearned Feedback Loop Pattern

Each skill directory uses a **two-tier** system:
- `LessonsLearned.GLOBAL.md` — tracked in git; process/model notes applicable across any workspace
- `LessonsLearned.md` — gitignored, per-user; codebase-specific facts (type locations, naming conventions, team patterns)

Place both files next to any `SKILL.md`. The skill's workflow instructions and any companion agent's final phase should direct the agent to read `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md` and follow the two-tier feedback loop process. This pattern should be recommended for every skill-level workflow that involves complex multi-step procedures.

---

## Workspace Discovery Guide

When auditing a workspace, scan for all of the following before planning individual audits. Each type should be audited separately:

| Pattern | Tool Type | Notes |
|---|---|---|
| `**/SKILL.md` | Agent Skill | Each must be in a directory whose name matches the `name` frontmatter field |
| `.github/agents/*.agent.md` or `**/*.agent.md` | Custom Agent | Also check `~/.copilot/agents/` for user-level agents |
| `.github/copilot-instructions.md` | Always-on Instructions | Single workspace-wide file |
| `**/AGENTS.md` | Always-on Instructions | Workspace root and optionally subfolders |
| `.github/instructions/*.instructions.md` | File-scoped Instructions | May be nested in subdirectories |
| `.github/prompts/*.prompt.md` | Prompt File | May be nested in subdirectories |
| `.github/hooks/*.json` | Hooks | Also check `.claude/settings.json` |
| `**/LessonsLearned.GLOBAL.md` | Feedback loop (global) | Note which skills have them and which are missing |
| `**/LessonsLearned.md` | Feedback loop (local) | Note which skills have a local file (gitignored, per-user) |

---

## Architectural Reference

Use this section during **Dimension 9** brainstorming. The goal is to identify how tool mechanisms can be combined — sometimes in unconventional ways — to reduce reliance on the agent remembering steps and add automation, determinism, and stability.

### Tool Mechanism Summary

| Mechanism | When It Fires | What It Can Enforce / Automate |
|---|---|---|
| **`Stop` hook** | Agent session ends | Run scripts, append logs, trigger cleanup, record metrics |
| **`PostToolUse` hook** | After any tool call | Lint / format changed files, validate outputs |
| **`PreToolUse` hook** | Before any tool call | Block dangerous operations, require confirmation, modify input |
| **`SessionStart` hook** | New session begins | Inject context, validate environment, log session start |
| **`SubagentStart/Stop` hooks** | Sub-agent spawned / completes | Initialize resources, aggregate results, validate sub-agent outputs |
| **Handoffs** | Explicit agent transition | Chain workflows, enforce ordered execution |
| **`disable-model-invocation`** | Prevents semantic loading | Ensure an agent only runs via explicit invocation, never by semantic match |
| **File-scoped Instructions** | Auto on file match | Inject always-true rules without requiring skill loading |
| **`applyTo` glob** | Pattern-matched file context | Scope rules precisely to affected file types |
| **Sub-agents** | Parallel or sequential delegation | Isolate context, enable parallelism, scope tool access |
| **Agent split + handoff** | Handoff from agent A → agent B | Create a seam between phases where hooks can fire deterministically |

### Guiding Questions for Dimension 9

When analyzing any item, ask:

- **What happens if the agent ignores a step?** — If important work is skipped silently, consider a hook or structural split that makes that step unavoidable.
- **Are there steps that always happen at a session boundary?** — Start/stop hooks can enforce boundary steps without depending on the agent's memory.
- **Are there rules labeled "always," "never," or "critical"?** — These are hook candidates: binary rules are better enforced by code than by instruction text.
- **Could this workflow be split into two agents with a handoff?** — If the first agent's "done" state is the second agent's "start" state, the split creates a seam where hooks fire deterministically.
- **Does this item duplicate content from another?** — Could a file-scoped instructions file with `applyTo` serve both and eliminate drift?
- **What context does the agent currently have to discover itself?** — `SessionStart` hooks can inject that context automatically.
- **Which steps are left to agent judgment but could be validated algorithmically?** — `PostToolUse` hooks can verify outputs immediately after tool calls.
- **What unconventional tool combinations might produce a more deterministic result?** — Think beyond their intended use; the goal is to find architectures that reduce reliance on agent recall.

---

## Audit Dimensions

Evaluate every item against all eight dimensions. Be specific — quote actual content from the file when identifying issues.

### 1. Fit Assessment

Is this content in the right tool type, or would a different type produce better results?

Key questions:
- Does this skill contain always-on rules that should be a `.instructions.md` with `applyTo` globs? (e.g., rules that apply to every `.cs` file should not require skill loading)
- Could a Custom Agent with tool restrictions and a scoped Stop hook serve this workflow better?
- Would a Prompt File make this user-initiated workflow more ergonomic than a skill?
- Could any part of this be mechanically enforced by a Hook instead of instruction text?
- Is the description written well enough for reliable semantic matching?
- Does any content here duplicate an existing `.instructions.md` with an `applyTo` glob? If so, the skill should cross-reference it and remove the redundant content.

Typical finding: Skills frequently contain 30–50% of content that should be in always-on or file-scoped instruction files.

### 2. Determinism Analysis

How precisely is behavior specified? Identify every point where an agent could interpret rules differently on two separate runs.

Patterns to flag:
- Subjective thresholds: "small," "medium," "simple," "complex," "appropriate," "if needed"
- Decision branches with no tiebreaker rule or decision tree
- Rules that say "prefer X" without defining when X is mandatory vs. optional
- Missing concrete examples for non-obvious patterns
- Procedures that rely on agent judgment when a concrete algorithm could replace it
- Referenced files or types that have no path (agent must search)

Assign a determinism score: **High** (behavior is predictable), **Medium** (some interpretation required), **Low** (significant agent discretion at multiple decision points).

### 3. Correctness & Dependability

Can an agent implement correctly from this content without needing additional context?

Check for:
- Code examples with undeclared variables or missing initialization (silent compilation failures)
- Rules that conflict with other known skills or instructions in the workspace
- Missing prerequisites (what must be true before starting)
- Incomplete procedures (steps end without specifying how to validate completion)
- Edge cases that are common but unaddressed
- Truncated, cut-off, or duplicated content (file editing defects)

### 4. Feedback Loop Opportunities

Where could a LessonsLearned.md feedback loop create continuous improvement?

**Existence check:**
- Is there a `LessonsLearned.md` alongside this skill or agent? If not, should there be?
- Does the skill/agent workflow include a read step at the start and an update step at the end?

**Health check** (for existing LessonsLearned files):
- **Escalation candidates**: Does the same topic appear across 3+ separate entries? Flag for promotion to SKILL.md or conversion to a hook.
- **Category routing**: Are entries tagged `Codebase` vs. `Process/Model`? `Codebase` entries must be in `LessonsLearned.md` (gitignored). `Process/Model` entries must be in `LessonsLearned.GLOBAL.md`. If any `Codebase` entries are found in `LessonsLearned.GLOBAL.md`, flag as a content leak.
- **Cross-skill duplicates**: Does a pattern in a LessonsLearned file also appear in another skill's file? It may belong in a shared instruction instead.

**Seeding new LessonsLearned files**: Use the failure modes identified in Dimensions 2 and 3. The `lessons-learned` skill (`~/Repos/copilot-configs/skills/lessons-learned/SKILL.md`) defines how the two-tier system works, including the escalation path from guidance to enforcement. Seed `LessonsLearned.GLOBAL.md` with process/model observations; `LessonsLearned.md` should be seeded only by the user locally (it is gitignored).

### 5. Automation Opportunities (Hooks)

Which rules in this item are binary (either violated or not) and therefore hookable?

For each candidate rule:
- State the hook event type (`PostToolUse`, `Stop`, `PreToolUse`, `SessionStart`)
- Describe what the hook script would check
- Note the tradeoff (per-edit hooks add latency; Stop hooks batch it at session end)

Common high-value hook candidates:
- File header requirements (SQL, license headers)
- Banned code patterns (direct casts, banned imports, deprecated APIs)
- Alphabetical ordering constraints
- Naming convention enforcement
- Cross-file consistency checks (version numbers must match)
- Run tests after test file edits
- Run static analysis (ReSharper, ESLint, etc.) at session end

### 6. Structural Issues

Is the file well-formed for its expected tool type?

For **Skills** (`SKILL.md`):
- `name` field: lowercase, hyphens, ≤64 chars, must match the parent directory name exactly
- `description` field: ≤1024 chars, descriptive enough for semantic matching, includes "Use when:" trigger phrases
- `argument-hint`: present if this is a user-invocable slash command that benefits from hints
- `user-invocable` and `disable-model-invocation`: set appropriately

For **Custom Agents** (`.agent.md`):
- `name`: matches intended invocation name
- `description`: clear purpose statement
- `tools`: minimal necessary set (principle of least privilege)
- `agents`: lists sub-agents that can be spawned
- `hooks`: scoped Stop hook for LessonsLearned if this agent handles complex workflows
- `user-invocable: false` for sub-agents

For **Instructions** (`.instructions.md`):
- `applyTo`: glob pattern that correctly and precisely matches the intended files
- `name` and `description`: informative for the UI

For **Hooks** (`.json`):
- `type: "command"` present on all entries
- OS-specific `windows`/`linux`/`osx` commands where needed
- `timeout` set for slow operations
- Scripts referenced by hooks use relative paths and exist in the repo

### 7. Cross-Skill / Cross-Config Concerns

Does this item duplicate, conflict with, or silently depend on another item?

Look for:
- The same rule stated in two files that could drift out of sync
- Inter-skill dependencies with no cross-references (workflow A requires workflow B but never mentions it)
- Conflicting rules between items (different tools suggesting different approaches for the same pattern)
- Shared knowledge that could be extracted to a single always-on instruction file
- Content in this item that has been superseded by an existing `.instructions.md` file — if an instructions file now covers a rule, the skill should defer to it (and remove the duplicate) rather than restating it

### 8. Recommended Refactoring

Provide specific, actionable, prioritized recommendations.

For each recommendation include:
- **What**: the specific change to make
- **Why**: how it improves determinism, dependability, or automation
- **Where**: the exact file location(s) affected
- **Example**: inline example if the recommendation involves a new file or frontmatter

### 9. Architectural Opportunities

Using the Architectural Reference section above, brainstorm how this item — or its relationship with other items — could be restructured to be more deterministic, automated, or maintainable.

Ask the guiding questions against this item's specific context. Produce concrete proposals, not generic advice. For each proposal:
- Name the mechanism(s) involved (e.g., "Stop hook + agent split", "applyTo instruction extraction")
- Describe the specific workflow change
- State what failure mode or reliance on agent judgment it eliminates

This dimension is for ideation — proposals here do not need to be final recommendations. Surface possibilities so the orchestrator can reason across the full system.

---

## AUDIT.md Output Format

Each individual audit produces a file named `AUDIT.md` placed in the same directory as the audited file's primary artifact:

```markdown
# Audit: {item-name}

## Summary
2–3 sentence executive summary.

## Fit Assessment
...

## Determinism Analysis
...

## Correctness & Dependability
...

## Feedback Loop Opportunities
...

## Automation Opportunities (Hooks)
...

## Structural Issues
...

## Cross-Skill / Cross-Config Concerns
...

## Recommended Refactoring
Numbered prioritized list with What / Why / Where / Example for each.

## Architectural Opportunities
Concrete proposals for how tool mechanisms could be combined or restructured to improve determinism, automation, or stability. Each entry names the mechanisms involved, the workflow change, and the failure mode it eliminates.

## Priority Rating
**High / Medium / Low** — one-sentence justification.
```

---

## Synthesis Report Format

The final synthesis report is saved to `{WORKSPACE_ROOT}/AUDIT-SYNTHESIS.md`:

```markdown
# Agentic Tools Audit — Synthesis Report

**Date**: {date}
**Scope**: All agentic configurations in {workspace}

## Executive Summary
...

## Individual Item Priority Summary
| Item | Type | Priority | Primary Issue |
...

## Cross-Cutting Themes
(Themes appearing in 3+ items — address at the shared level, not per-item)

## Conflict Resolution
(Rules that conflict between items — explicit resolution for each)

## Shared Abstractions Worth Extracting
(Patterns that could be pulled into shared instruction files)

## Architecture Ideation
(Cross-system proposals for restructuring tools to improve automation, determinism, or stability. Sourced from Dimension 9 findings across all items. Each proposal names the mechanism combination and the specific failure mode or reliance on agent judgment it would eliminate.)

## Findings Outside the Roadmap

For any audited item whose findings were not promoted to the roadmap, include a brief entry here with the reason:

```markdown
| Item | Finding | Why not in roadmap |
|---|---|---|
| {item} | {brief description} | {reason: low ROI / user context / superseded / already handled elsewhere} |
```

This section prevents findings from silently disappearing between the individual audit and the final roadmap.

## Redundancy Collapse
Before sequencing the roadmap, review all recommendations together and ask: does implementing one recommendation make another unnecessary or conflicting? For each such pair, collapse or reorder them: note which recommendation is superseded and remove or deprioritize it. A recommendation that adds content that another recommendation would then delete should not appear in the final roadmap.

## Architecture Proposals — Pending Discussion

Do NOT sequence architecture-tier proposals directly into the implementation roadmap. Instead, list them here under a separate heading and **stop to discuss them with the user** before Phase 5 is finalized. Architecture proposals require collaborative review because:
- They involve creating or splitting agent files, which is harder to reverse than a frontmatter change
- The user may have context about intent that changes whether a proposal is warranted
- Agent splits, hook additions, and SessionStart changes interact with each other and need sequencing decisions the user should make

For each architecture proposal, present it to the user with:
1. The failure mode it solves (be specific — cite the actual instance where this failure occurred or is likely)
2. The mechanism involved
3. The effort level
4. Any interactions with other proposals

Only add architecture proposals to the roadmap after the user has confirmed each one individually.

**Preference scope rule**: When the user declines a recommendation for one specific item, record the reason and explicitly confirm the scope before moving on. Do NOT apply that reasoning to other items unless the user explicitly generalizes it. If uncertain whether a preference is scoped or general, ask.

## Implementation Roadmap

Use a checklist table so status can be tracked as items are implemented:

```markdown
| # | Phase | Item | Status | Notes |
|---|---|---|---|---|
| 1 | Defect Fix | {specific change, file} | ⏳ Pending | |
| 2 | Defect Fix | {specific change, file} | ⏳ Pending | |
| 3 | LessonsLearned | {skill name} | ⏳ Pending | |
| 4 | Instruction Extraction | {rule → applyTo glob} | ⏳ Pending | |
| 5 | Hook | {event, trigger, what it enforces} | ⏳ Pending | |
```

Status values: `⏳ Pending` → `🚧 In Progress` → `✅ Done` → `⏭️ Skipped`

## Post-Implementation Verification Checklist

After completing roadmap items, verify the changes work as intended:

- [ ] Renamed skills: confirm `name` frontmatter matches directory name exactly; test semantic matching with a relevant prompt
- [ ] New `.instructions.md` files: open a matching file type in VS Code and confirm the instructions appear in the agent context
- [ ] Pruned skill content: confirm the skill still covers its full workflow; nothing needed was removed
- [ ] New `LessonsLearned.GLOBAL.md` files: confirm seeded content is accurate and contains only `Process/Model` entries (no codebase-specific content)
- [ ] Feedback loop wiring: trigger the agent through one session and confirm it reaches the LessonsLearned update step and routes to the correct file based on category
- [ ] `disable-model-invocation` on sub-agents: confirm the agent does not appear when semantically matching a relevant prompt
- [ ] Hook scripts: test the hook fires by checking the GitHub Copilot Chat Hooks output channel
- [ ] Fixed handoffs: confirm the target agent name in `agent:` matches an existing agent's `name` frontmatter exactly

## Per-Item Audit File Index
| Item | Type | Audit File |
...
```

---

## Severity Calibration

Before individual auditors begin, define the severity thresholds that will be used consistently across all items. Include this table in `AUDIT-CONTEXT.md` so every sub-agent uses the same scale:

| Severity | Definition | Examples |
|---|---|---|
| **High** | Broken or non-functional today; actively causes failures or wrong behavior | Missing referenced file, wrong file extension preventing load, broken handoff target name |
| **Medium** | Works today but creates real failure risk on the next change; significantly impairs the intended workflow | Hard-coded paths, missing `agents:` on a spawning agent, no feedback loop on a complex skill |
| **Low** | Improvement opportunity with no current failure risk; quality or discoverability concern | Missing `name`/`description` frontmatter, vague thresholds, content that could be extracted |

---

## Deployment Note

When moving this skill to a target project, place files as follows:
- `SKILL.md` + `LessonsLearned.md` → `.github/skills/agentic-tools-auditor/`
- `agentic-tools-auditor.agent.md` → `.github/agents/agentic-tools-auditor.agent.md`
- `individual-auditor.agent.md` → `.github/agents/individual-auditor.agent.md`
