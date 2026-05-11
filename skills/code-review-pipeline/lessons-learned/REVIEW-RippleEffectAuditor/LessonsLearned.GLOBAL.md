# Lessons Learned: REVIEW-RippleEffectAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future ripple-effect reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-08 — ViewModel-Mirror Anti-Pattern

**Pattern**: When a ViewModel is a full property-for-property mirror of a domain entity, there are typically TWO separate "copy entity fields" paths: a factory/constructor for initial load and an `UpdateXxx()` method for in-place refresh. These are parallel implementations of the same projection logic. **Both must be found and enumerated** as ripple targets when the entity gains a new field. Searching only for the factory and missing the update method is a common false-completeness error.

**Heuristic**: For any entity-to-ViewModel class pair, always search for both (a) a `FromX()` or `CreateFromX()` factory and (b) an `UpdateX()` or `SyncFrom()` method. If both exist without shared code, flag them as co-evolution risk.

## 2026-05-08 — Flat-Parameter Interface as Blast-Radius Amplifier

**Pattern**: When a service interface method enumerates an entity's mutable fields as individual parameters (e.g., `Add(string title, string desc, Enum horizon, Enum effort, bool flag, int score, Enum? override)`), every entity field addition requires: interface signature change + implementation change + every caller change. The interface acts as a blast-radius multiplier, not an abstraction. **Always check** whether callers use named arguments; positional-only calls are an additional silent-failure risk when parameters are reordered or inserted.

**Heuristic**: Count the parameters on service interface methods. More than 4–5 parameters that map directly to entity properties is a signal to recommend a request/command object.

## 2026-05-08 — Hardcoded Enum Enumeration in UI Components

**Pattern**: When UI components declare `private static readonly SomeEnum[] ValidValues = [A, B, C]` or equivalent dictionaries keyed by an enum, they silently become stale when a new enum value is added. These arrays never fail to compile — they simply omit the new value from the rendered output. This is one of the highest-risk silent failure patterns for enum extension.

**Heuristic**: When analyzing ripple effects of adding an enum value, search for static arrays and dictionaries whose keys are the enum type — these are the most likely silent-omission sites, more dangerous than switch statements (which at least can be made exhaustive with warnings).

## 2026-05-08 — "Critical" Severity for Blast-Radius Findings Gets Resolved Down to High in Synthesis

**Pattern**: The Ripple Effect Auditor appropriately uses "Critical" to signal "the blast radius of this common change scenario is dangerously wide with silent failure modes." However, the Final Synthesizer uses "Critical" to mean "current data corruption or confirmed runtime bug." These scales do not align, and the mismatch causes final-report inflation.

**Heuristic**: When assigning severity in the Ripple Effect audit, annotate findings that are future-change concerns (no current bug) vs. findings where the silent failure mode is already triggered by the current codebase. This annotation helps the synthesizer apply the correct resolution: pure blast-radius findings → resolve to High; currently-triggered silent failure → keep as Critical.
