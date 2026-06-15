# LessonsLearned — REVIEW-ChangesetDispatcher (Global)

> **Recording rule**: Record only workflow process improvements. No codebase-specific knowledge, code patterns, or finding calibrations.

---

## 2026-06-15 — Cross-cutting changesets always exceed the 75% slice threshold

When a changeset spreads small changes across many source files (such as feature toggle cleanup or a cross-cutting rename), even aggressive exclusion of non-production files (test files, config, pure-enum files) removes only a small fraction of total lines — well below the 75% keep-threshold. For these changesets, skip writing slice files entirely and go straight to recording `changeset-full.md` for all auditors.

## 2026-06-15 — System/integration test files: route same as unit test files, except for ripple-effect

When a changeset includes files from a system or integration test framework (i.e., test files that reference symbols by string name rather than compiled identifiers), exclude them from testability, performance, extensibility, structural-patterns, and maintainability slices — same treatment as unit test files. Include them for ripple-effect (they reference removed symbols by name and are useful for verifying cleanup completeness) and unit-test-coverage (auditor awareness of system-level coverage, even if out of scope for unit gap analysis).
