# Temporary Debug Logging

A skill-driven workflow for instrumenting a C# codebase with exhaustive temporary debug logging, designed to capture runtime behavior across complex, high-iteration execution flows. Output is intended to be consumed by a coding agent — not a human — so the goal is completeness, not brevity.

## The Problem It Solves

Bugs in complex codebases with thousands of iterations are often invisible at the source level. You can read the code and understand what *should* happen, but not what *did* happen for a specific input at runtime. Printf-style debugging tends to miss the story because it's added hastily, lacks context, and produces disconnected fragments rather than a traceable timeline. This workflow produces structured, correlated log files that give a coding agent everything it needs to reconstruct the full execution story.

## How It Works

The workflow moves through six stages before any log data is collected:

```
Clarify intent → Research code → Plan format and data → Review the plan → Implement → Run
```

1. **Clarify intent** — Establishes exactly what question needs to be answered at runtime. Ambiguous intent produces logs that capture the wrong things. The agent confirms: what's under investigation, what code is suspected, whether iterations are expected, and whether this is a known-bad-case or exploratory.

2. **Research the code** — Reads the relevant source before touching anything. Maps entry points, decision points, data flow, component boundaries, loop structure, cross-iteration state, and exception paths. The log format cannot be finalized until the code structure is understood.

3. **Plan format and data** — Selects the right file format based on the shape of the data (CSV for uniform per-iteration data, event log for flow traces, JSON lines for hierarchical data, or two files when both are needed). Defines all required metadata fields and the CorrelationId strategy that links entries across files and components.

4. **Review the plan** — Verifies that all conditional branches, component handoffs, and exception paths are covered before a single line of logging code is written. A gap found here is cheap; a gap found after a long test run is not.

5. **Implement** — Adds logging at method entry, decision points, intermediate computations, method exit, and exception handlers. All log entries carry timestamp, iteration index, thread ID, component/phase, caller method, and CorrelationId. Log files go to `_debug_logs/` at the repo root (gitignored, never committed).

6. **Notify** — Tells the user which files were instrumented, what to run, and what to share back for analysis.

## Design Principles

**Exhaust the log.** The consumer is a coding agent that can parse structure quickly. Missing data is far more costly than extra data.

**Correlation is mandatory.** Every log entry across every file carries a CorrelationId. Without it, a consuming agent cannot group entries belonging to the same logical unit of work, and the timeline becomes meaningless.

**Format follows data shape.** The wrong format forces the agent to fight the structure rather than read through it. Choosing between CSV, event log, and JSON lines is a deliberate decision, not a default.

**Temporary by design.** No logging libraries, no config, no test coverage, no clean code constraints. Plain `File.AppendAllText`. The code will be removed after diagnosis.

## Log Output

All files are written to `_debug_logs/` at the repo root. The directory is gitignored. Files are appended on each run so multiple runs accumulate; delete the file to reset before a clean run.

## Reference Files

| File | Role |
|------|------|
| [`skills/temp-debug-logging/SKILL.md`](../../skills/temp-debug-logging/SKILL.md) | Full workflow, format selection guide, metadata field definitions, CorrelationId strategy, placement rules |
| [`skills/temp-debug-logging/LessonsLearned.GLOBAL.md`](../../skills/temp-debug-logging/LessonsLearned.GLOBAL.md) | Process/model findings from past sessions (tracked in git) |
| [`skills/temp-debug-logging/LessonsLearned.md`](../../skills/temp-debug-logging/LessonsLearned.md) | Codebase-specific discoveries: log path depth, CorrelationId choices, component patterns (gitignored, local) |
