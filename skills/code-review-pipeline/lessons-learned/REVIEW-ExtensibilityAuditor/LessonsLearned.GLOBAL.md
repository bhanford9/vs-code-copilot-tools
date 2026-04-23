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

## Entry: C# Default Interface Members — Overrides Dispatch Correctly Through Interface References

**Date**: 2026-04-22
**Category**: Process/Model

When a C# 8+ interface uses default property/method implementations that `new` up concrete types, those defaults CAN be overridden in implementing classes — and the override WILL be called as long as the consumer holds an interface reference (not a concrete reference). Do NOT flag this pattern as "defaults are not overridable" or "tightly coupled to concrete types at the interface level" when the calling code uses the interface reference. The extension point is real and functional. Severity should not exceed Low unless the implementing class is also `sealed` and no alternative implementation path exists.

---

## 2026-04-22 — Feature Toggle Severity Depends on Toggle Lifetime

**Finding**: When auditing toggle-duplicated dispatch logic, check `appsettings.shared.json` (or the equivalent default configuration file) to determine whether a feature toggle is a **temporary safe-release flag** or a **long-lived opt-in flag**. A toggle set to `"Off"` globally with no documented retirement plan is permanent. Permanent toggle duplication should be rated High severity; temporary safe-release toggles are Medium. The two look identical in code — only the config file reveals intent.

**Pattern**: Search for the toggle name in the app settings file early in the review. If the toggle is "Off" in shared/production settings, treat the duplication as long-lived.
