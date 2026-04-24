---
name: temp-debug-logging
description: Instrument a C# codebase with exhaustive temporary debug logging to capture runtime behavior across complex, high-iteration execution flows. Output is consumed by a coding agent for diagnosis. Use when investigating a runtime bug, unexpected value, wrong branch, or mysterious behavior in code that runs thousands of iterations.
---

# Temporary Debug Logging

> This skill is intentionally not a "less-is-more" skill. The goal is to capture everything a coding agent would need to reconstruct the full story of what happened at runtime. Clean code, test coverage, and log hygiene are explicitly out of scope.

## Quick Checklist

Copy when starting a debug logging session:

```
Debug Logging Session:
- [ ] Read LessonsLearned.GLOBAL.md for process notes
- [ ] Read LessonsLearned.md for codebase-specific patterns (if it exists)
- [ ] Step 1: Clarify intent — understand what data is under investigation
- [ ] Step 2: Research code — read relevant source to understand the full flow
- [ ] Step 3: Plan logging — decide format, data, metadata, and linking strategy
- [ ] Step 4: Review the plan — verify coverage of all paths and connections
- [ ] Step 5: Implement the logging
- [ ] Step 6: Notify the user to run and share results
```

---

## Step 1: Clarify Intent

Before touching any code, understand what question needs to be answered at runtime.

Confirm with the user:
1. What specific behavior, value, or outcome is under investigation?
2. What code path, feature area, or class is suspected?
3. Are iterations expected? If so, what drives them (a loop over members, a collection, a recursive call, etc.)?
4. Is there a known "bad case" to look for, or is this exploratory?

**If the data shape is not immediately obvious from the user's description, ask before proceeding to Step 3:**
> "Is this mostly per-iteration data (same fields each time), a flow trace (sequence of events across components), or both? That determines whether to log to a CSV, an event log, or both."

A clear intent statement prevents both irrelevant logging and missing the crucial data.

---

## Step 2: Research the Code

Read the relevant source files before planning anything. Identify:

- **Entry points**: What triggers this code path? What calls into it?
- **Key decision points**: Conditionals, switches, early returns — anything that determines which branch executes
- **Data flow**: How values are computed, passed between methods, and transformed
- **Component boundaries**: Where does ownership of the data change hands? (e.g., resolver → designer → validator)
- **Loop structure**: What collection is iterated? Is there nesting? What is the loop variable?
- **State that outlives one iteration**: Any accumulator, running total, or cached result that carries across iterations
- **Exception paths**: What happens on failure? Are there silent catch blocks that swallow errors?

Do not finalize the log format until the code structure is well understood.

---

## Step 3: Plan the Logging

### Choose the Right Format

The format is driven by the shape of the data being captured.

| Data Shape | Recommended Format | Reason |
|---|---|---|
| Many iterations of the same computation — same fields per item | **CSV** | Easy to sort, filter, and compare across rows |
| Event sequences, branching flows, method entry/exit | **Sequential event log** (structured text) | Preserves causal and temporal order |
| Nested or hierarchical data with varying structure | **JSON lines** (one JSON object per line) | Parseable, handles irregular or optional fields |
| High-iteration data *and* surrounding context events | **Two files**: CSV for per-item data + event log for surrounding flow | Separates dense iteration data from contextual flow events |

**When it is not obvious which format to use, ask the user.** Guessing wrong means the agent consuming the logs may not be able to reconstruct the story.

### Define the Log Directory

Always write to `_debug_logs/` at the **repo root** (not the project or bin directory). Create the directory programmatically. Add it to `.gitignore` if not already present.

Use a **descriptive filename** that identifies the feature or component, not just "debug.csv". If logging from multiple components, use separate files per component (e.g., `load-resolver.log`, `design-engine.csv`) — they are linked via CorrelationId.

### Plan the Data Fields

Capture two categories of fields on every log entry:

**1. Metadata (context fields) — always include all of these:**

| Field | Purpose |
|---|---|
| `Timestamp` | Absolute time (ISO 8601); enables cross-file ordering |
| `IterationIndex` | Relative sequence within a run |
| `ThreadId` | Required when code is parallel or async |
| `Phase` / `Component` | Identifies which part of the codebase the entry is from |
| `CallerMethod` | Identifies the exact method where the log is written |
| `CorrelationId` | Links entries from different log points for the same unit of work |

**2. Subject data (the values under investigation):**
- All input parameters to the method at the log point
- Computed intermediate values — especially values that feed into conditionals
- The condition value *and* which branch was taken (log both)
- Output or result values
- Any relevant flags, enum values, or state that drives the logic
- Anything surprising or non-obvious that affects the outcome

### Define the CorrelationId

Every entry across every file must carry a shared CorrelationId so a coding agent can group all log entries belonging to one logical unit of work.

Choose based on what defines "one unit":

| Scenario | CorrelationId to use |
|---|---|
| Iterating a list of design members | The member ID or member index |
| Processing a load case or job | The job/case ID |
| Recursive calls | The root input identifier |
| No natural key exists | A static counter incremented at the outermost entry point, threaded down as a parameter or field |

If the CorrelationId must be threaded through methods that don't currently accept it, add it as a parameter. This is temporary code — don't worry about the API change.

### Plan the File Header / Entry Format

**CSV**: Define all column names up front. Write the header row once on file creation.

**Event log**: Use a consistent prefix on every line:
```
[ISO-timestamp] [Component] [CorrelationId] [CallerMethod] Message text with values
```

**JSON lines**: Every object on its own line with consistent top-level keys (`Timestamp`, `Phase`, `CorrelationId`, then data fields).

---

## Step 4: Review the Plan

Before writing any code, verify the plan covers:

- [ ] All conditional branches that affect the value under investigation have a log entry capturing which branch was taken
- [ ] Both the happy path and exception/edge-case paths are covered
- [ ] Every log point carries the CorrelationId
- [ ] Every log point identifies its Component/Phase
- [ ] A coding agent can reconstruct the execution sequence for one logical unit solely from the log entries
- [ ] Log entries at component boundaries capture the handoff value (what was passed in, what comes back)
- [ ] Logging inside tight inner loops is either bounded or summarized — for very high iteration counts inside an inner loop (e.g., 10,000+ per outer iteration), log a per-iteration *summary* or the first/last N, rather than every single entry

If a gap is found, revise the plan before implementing.

---

## Step 5: Implement the Logging

### Placement Rules

Log at each of the following:
- **Decision points** — capture the condition and which branch was taken (`if`, `switch`, early `return`)
- **Intermediate computations** — capture values before and after any non-trivial transformation
- **Method exit** — capture what is returned or set (skip if already captured at the computation site)
- **Exception handlers** — log the exception message and any context, even if swallowed

---

## Step 6: Notify the User

After implementing, tell the user:

1. Which files were modified with logging instrumentation
2. The full path to the log output directory and file(s): `_debug_logs/<filename>`
3. What to run (which test, entry point, or scenario) to produce the output
4. What to share back for analysis (the log file contents or path)

Example:
> "Logging has been added to `DesignEngine.cs` and `LoadResolver.cs`. Run the `[SpecificTest]` test (or trigger the relevant workflow). The output will be written to `_debug_logs/design-engine.csv` and `_debug_logs/load-resolver.log` at the repo root. Please share those file contents when done."

---

## Critical Rules

**✅ DO:**
- Log more than you think you need — the consumer is an agent, not a human skimming a file
- Include CorrelationId on every single entry so entries from different files can be linked
- Use ISO 8601 timestamps (`DateTime.UtcNow.ToString("o")`)
- Write to `_debug_logs/` at the repo root
- Create nested directory structure if it helps organize by feature/component (`_debug_logs/design-engine/`, `_debug_logs/load-resolver/`)
- Add `_debug_logs/` to `.gitignore` if not already present
- Use `File.AppendAllText` (append) so multiple runs accumulate; the user can delete the file between runs to reset
- Use `Interlocked.Increment` for counters in concurrent code
- Log at component handoff points — the input going in and the result coming back out

**❌ DON'T:**
- Introduce logging libraries (NLog, Serilog, Microsoft.Extensions.Logging) — `File.AppendAllText` only
- Log inside tight inner loops without bounding or summarizing (risk: multi-GB files for thousands×thousands iterations)
- Remove or alter the functionality of code under investigation before getting log results — log alongside it
- Commit the log files or the instrumentation code
- Open a `StreamWriter` without closing it — prefer `File.AppendAllText` for simplicity unless performance is a problem

---

## Feedback Loop

Before starting, read `~/Repos/vs-code-copilot-tools/skills/temp-debug-logging/LessonsLearned.GLOBAL.md` and, if it exists on disk, `~/Repos/vs-code-copilot-tools/skills/temp-debug-logging/LessonsLearned.md`. Apply any recorded patterns to this session.

When this workflow is complete, **proceed directly into the lessons learned reflection** — do not ask for permission first. Follow the two-tier feedback loop from `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md`:
- **Codebase findings** (log path adjustments, CorrelationId choices, component-specific patterns) → write to `LessonsLearned.md`
- **Process findings** (format decisions that worked well, agent consumption insights, workflow gaps) → write to `LessonsLearned.GLOBAL.md`

Both files are at `~/Repos/vs-code-copilot-tools/skills/temp-debug-logging/`.
