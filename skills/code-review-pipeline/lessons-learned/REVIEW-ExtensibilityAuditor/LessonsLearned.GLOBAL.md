# Lessons Learned: REVIEW-ExtensibilityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future extensibility reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## Boolean Flag Parameters on Resolver Methods Signal Incomplete Extensibility

**Date**: 2026-04-28
**Category**: Process/Model

When a private method on a resolver/calculator accepts a `bool` parameter that selects between two fundamentally different fallback or strategy paths (e.g., `bool useW2Fallback`), treat it as a Medium extensibility finding. The flag signals that the method is doing two different jobs unified by a boolean rather than by abstraction. The correct severity is Medium (not Low) when the method has exactly two states and a third variant is plausible in the domain context. The correct recommendation is a `Func<...>` strategy parameter or two separate methods, not an enum — enums require modification too. Only escalate to High if a third variant is explicitly planned or if the boolean selects between behaviors with different correctness consequences (not just different fallback values).

---

## Entry: C# Default Interface Members — Overrides Dispatch Correctly Through Interface References

**Date**: 2026-04-22
**Category**: Process/Model

When a C# 8+ interface uses default property/method implementations that `new` up concrete types, those defaults CAN be overridden in implementing classes — and the override WILL be called as long as the consumer holds an interface reference (not a concrete reference). Do NOT flag this pattern as "defaults are not overridable" or "tightly coupled to concrete types at the interface level" when the calling code uses the interface reference. The extension point is real and functional. Severity should not exceed Low unless the implementing class is also `sealed` and no alternative implementation path exists.

---

## 2026-04-22 — Feature Toggle Severity Depends on Toggle Lifetime

**Finding**: When auditing toggle-duplicated dispatch logic, check `appsettings.shared.json` (or the equivalent default configuration file) to determine whether a feature toggle is a **temporary safe-release flag** or a **long-lived opt-in flag**. A toggle set to `"Off"` globally with no documented retirement plan is permanent. Permanent toggle duplication should be rated High severity; temporary safe-release toggles are Medium. The two look identical in code — only the config file reveals intent.

**Pattern**: Search for the toggle name in the app settings file early in the review. If the toggle is "Off" in shared/production settings, treat the duplication as long-lived.

---

## 2026-04-24 — Dual-Track Enum Mapping Creates Silent Divergence Risk

**Finding**: When a codebase has two independent code paths that both map the same enum (e.g., old-path switch statement, new-path attribute-based lookup), adding a new enum value will silently break only the path that uses the switch. The failure mode is not an exception — the switch falls to `default → null` and skips the affected behavior. This is an extensibility risk that is easy to miss because the two paths are often in different files and activated by different conditions.

**Heuristic**: When you find a switch statement that maps one enum to another, search for alternative mapping approaches for the same enum pair elsewhere in the codebase. If they coexist, flag the switch as "closed for extension" at High severity and recommend a shared utility.

---

## 2026-04-24 — Two-Toggle Mutual Exclusivity Invariants Need Explicit Documentation

**Finding**: When a new toggle is introduced to replace an older one (new mechanism supersedes old mechanism), and the old mechanism has a bypass that prevents double-application, the bypass code has a hidden invariant: "the bypass must remain as long as both toggles can be independently on." This is a **toggle retirement trap**. After the new toggle is promoted, the bypass looks like dead code — but it is not. Removing it silently reintroduces the original defect.

**Pattern**: When auditing two overlapping toggles, check:
1. Is there a bypass in the old code path that references the new toggle by name?
2. Is the bypass's purpose to prevent double-application?
3. Is there a test that verifies the bypass?

If (3) is missing, flag High. If (2) is present with no retirement comment, recommend adding a `// RETIREMENT NOTE` comment at the bypass site.

---
## 2026-04-29 — Exclusion-Accumulation Naming on Public Interfaces Is a Medium Finding

**Finding**: When a public interface method uses a naming pattern that accumulates excluded types in the method name (e.g., `HasAnyCheckOutputIgnoringX` → `HasAnyCheckOutputIgnoringXAndY` → ...), flag it as Medium severity. Each new excluded type requires renaming the public interface member, which is a breaking change for any external callers and forces updates at the interface declaration, implementation, all callers, and all test mocks. The violation compounds on public interfaces because name stability is an API contract.

**Pattern**: Look for method names containing `Ignoring`, `Excluding`, `Without`, or similar words followed by a list of concrete type names. If the name grew from a previous version (prior rename), rate the finding Medium. The fix is to replace the exclusion list in the name with a parameterized predicate (`Func<T, bool>` include-filter or an exclusion enum/set). This keeps the method name stable as the exclusion set evolves.

**When NOT to flag**: Internal methods (not on a public interface) with exclusion-list names are Low severity — renaming is contained within the assembly. Only escalate to Medium when the exclusion-accumulation pattern is on a `public` interface member.

---
## 2026-04-24 — Optional `IToggles? toggles = null` Accumulates as a Silent Opt-Out Pattern

**Finding**: An optional toggle parameter with a null default (`IToggles? toggles = null`) is a backward-compatibility shim that becomes a liability as more toggle-gated features use the same method. Any caller that omits the parameter silently opts out of all toggle-gated behavior — not just the original one. The failure mode is incorrect results (not exceptions), making it hard to diagnose.

**Pattern**: Flag `IToggles? toggles = null` as a Medium finding when it appears on a method that has more than one toggle-gated branch. The recommendation should be to make the parameter required and provide an explicit "all-off" value for callers that need legacy behavior.
