# LessonsLearned.GLOBAL — REVIEW-CodeCorrectnessAuditor



## Parallel ordered-array + keyed-dictionary over same domain objects is High when a bug confirms the sync failure
**Category**: Process/Model

When a class exposes two static data structures that represent the same ordered domain concept — e.g., an `ItemType[]` array for iteration order plus a `Dictionary<ItemType, ...>` for attribute lookup — and a known production bug exists whose direct cause is that one structure was updated without the other, rate the DRY violation as **High** (not Medium). The bug IS the DRY failure manifesting in production. The finding should include: (a) the crash mode (e.g., `KeyNotFoundException` when the array contains a key absent from the dictionary), (b) that any partial fix is dangerous (updating one but not both can crash), and (c) the recommended refactor (a single ordered array of tuples from which the dictionary is derived). Do NOT downgrade to Medium because the bug is already documented in a correctness audit — the maintainability severity is elevated BY the confirmed correctness failure.

---



## Lesson 006 — EF Core Count-Only Value Comparer Is a Correctness Bug, Not a Performance Win

A `ValueComparer` that uses `Count`-only equality and a `Count`-based hash code will
cause EF Core's change tracker to miss content-level mutations to a collection property.
This pattern looks like a "fast" shortcut but is actually broken: if the list length
stays the same but content changes (e.g., permission name or allow/deny flag updated),
SaveChangesAsync silently skips the UPDATE.

**Rule:** Any `ValueComparer` for a `IReadOnlyList<T>` (or similar collection) on an EF
Core entity MUST use structural equality (SequenceEqual or equivalent), not size-only
equality. Flag any `v => v.Count` or `(a, b) => a.Count == b.Count` pattern as High
severity — it is a data-loss defect disguised as a micro-optimization.

---

## Parallel-looking loops with different iteration sources in state-mutation + audit method pairs

**Date**: 2026-05-31
**Category**: Process/Model

When a method contains two structurally similar loops — a primary loop that mutates state by iterating a database-sourced collection, and a secondary loop that records audit/observability events by iterating caller-supplied input — verify that the two loops use the **same iteration source** and the **same skip conditions**. A common failure mode is: the primary loop iterates the persisted collection (skipping caller entries with no matching DB row), while the audit loop iterates the caller-supplied list (writing records for every entry including those skipped by the primary loop). This produces phantom audit/observability records for cases where the primary loop executed a no-op (e.g., the DB row was deleted between a read and a write operation). **Rule:** For any method containing both a state-mutation loop and an audit-write loop, check that the audit loop's iteration source matches the state-mutation loop's iteration source, and that its skip conditions mirror the primary skip conditions. If they diverge, rate the finding as **Medium** — the record produced for a no-op event is factually incorrect.

---

