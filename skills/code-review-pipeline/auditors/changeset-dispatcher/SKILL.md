# SKILL: Changeset Dispatcher

## Purpose

Read `code-review/changeset-full.md`, classify the diff content per parallel auditor using the relevance table below, write per-auditor slice files to `code-review/slices/`, and produce `code-review/auditor-input-index.md`.

The index file is the single source of truth for what each auditor reads. After you write it, every parallel auditor reads it first to discover its input manifest.

---

## Input

- `code-review/prelim-classify.json` — grep-based per-file auditor flags (written by `build-changeset.ps1` → `build-prelim-classify.ps1`)
- `code-review/changeset-sections-AB.md` — Sections A+B only extract (written by the same script; no Section C content)
- `code-review/session-config.json` — for `securitySurface` and `sectionCMode`

You do NOT read `changeset-full.md` directly. You run in parallel with the Requirements Auditor.

---

## Task

### Step 1 — Read session-config.json

Read `code-review/session-config.json` in a single call. Note `securitySurface` (omit security row if false) and `sectionCMode`.

### Step 2 — Read pre-classified inputs

Read each of these two files in ONE call each (both are small, bounded artifacts):

- `code-review/prelim-classify.json` — grep-based per-file auditor flags produced by `build-prelim-classify.ps1`. Use as your starting point.
- `code-review/changeset-sections-AB.md` — Sections A and B only, pre-extracted by `build-prelim-classify.ps1`. Contains commit messages and per-file diff CHUNKs, but NO Section C content. Read this file in full. Do NOT read `changeset-full.md`.

### Step 3 — Classify per auditor and decide Section C inclusion

For each changed file in `prelim-classify.json`, decide per auditor whether to include in the manifest. Start from the JSON pre-classification. Review Section B CHUNK content to refine.

Additionally decide whether each file warrants Section C inclusion for each relevant auditor:
- **Section C = YES (static):** structural-patterns, maintainability — always include Section C
- **Section C = NO (default):** ripple-effect, unit-test-coverage, extensibility (usually), performance (usually)
- **Section C = YES (LLM decides):** when the diff alone is insufficient to understand full method structure, class hierarchy, or DI pattern being changed

Apply the relevance table below. When uncertain about a file, include it.

### Step 4 — Write dispatch-manifest.json

Write `code-review/dispatch-manifest.json` as compact JSON (no embedded content — just file lists and flags):

```json
{
  "auditors": {
    "unit-test-coverage": {
      "files_B": ["File1.cs", "File2.cs"],
      "files_C": [],
      "include_section_D": false,
      "include_section_E": true
    },
    "ripple-effect": {
      "files_B": ["ChangedInterface.cs"],
      "files_C": [],
      "include_section_D": true,
      "include_section_E": false
    },
    "maintainability": {
      "files_B": ["File1.cs", "File2.cs"],
      "files_C": ["File1.cs", "File2.cs"],
      "include_section_D": false,
      "include_section_E": false
    }
  }
}
```

Omit the security auditor entry if `securitySurface=false`.

### Step 5 — Run build-slices.ps1

```powershell
powershell -File "$env:USERPROFILE/Repos/vs-code-copilot-tools/skills/code-review-pipeline/scripts/build-slices.ps1"
```

This script assembles all slice files from the CHUNK markers in `changeset-full.md`, measures each slice ratio (threshold = 0.75), and writes `code-review/auditor-input-index.md`. Your job is done after this script completes.

---

## Per-Auditor Relevance Table

These principles are language/framework agnostic. Apply them to the actual diff structure of the changeset being reviewed.

| Auditor | Include | Exclude |
|---------|---------|---------|
| **unit-test-coverage** | All changed production source files (need to know what should be covered); all changed test files (need to know what coverage was added or modified) | Non-code assets (configs, markup, CSS, migration scripts) |
| **testability** | All changed production source files: class declarations, constructor signatures, dependency injection patterns, interface definitions, static members, method visibility | Test files (testability evaluates *whether* code can be tested, not whether tests exist); non-code assets |
| **performance** | Files containing loops, I/O operations, async/await chains, database or network calls, in-memory collection operations, object allocations in hot paths | Pure data model / DTO files with no behavior; configuration-only files; pure UI rendering with no data transformation |
| **extensibility** | Changed interfaces and abstract types; DI registration files; public method signatures; files with hardcoded literals that could be constants; new public entry points; files where the diff introduces type-check conditionals branching on a discriminator (OCP violation signal), direct instantiation of a concrete type inside a method body rather than through injection (DIP violation signal), or method overrides that silently change contract behavior (LSP violation signal) | Method body changes that are pure behavioral refactors with no structural implications (e.g., loop rewrites, null guards, logging); pure data model / DTO files where all changed lines are declarations only (no executable logic); pure markup / template files; test files |
| **structural-patterns** | Class and interface declarations; constructor signatures; inheritance and composition changes; DI registrations; access modifier changes | Method body internals (only the structural skeleton matters); test files |
| **maintainability** | All changed method bodies in full (not just diff lines — include the complete method when any line inside it changed); deleted members; files with duplication candidates | Non-code assets; test files |
| **ripple-effect** | Files containing changed symbol declarations (method/class/interface names that were renamed, removed, or had signature changes); other files in the diff that reference those same symbols | Files with no symbol overlap with the changed declarations |
| **security** | Files handling authentication, authorization, input validation, external service calls, data persistence, encryption, or session management | Pure UI rendering files with no data processing; configuration-only files; test files. **Omit row entirely if `securitySurface=false` in session-config** |

---

## Lessons Learned

Before starting, read:
- `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/changeset-dispatcher/LessonsLearned.GLOBAL.md`

After completing, append any new insights to that file. Examples of lessons worth recording:
- Auditors that consistently hit the 75% threshold (may need exclusion rule updates)
- Auditor slice headers where "Dispatcher Coverage Note" was triggered in a review (false negatives — update the relevance table row)
- Diff structures that made classification ambiguous
