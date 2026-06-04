# LessonsLearned.GLOBAL — REVIEW-CodeCorrectnessAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

### Parallel array + keyed dictionary over the same domain objects: rate High when a sync bug is confirmed

When a class exposes both an ordered array and a lookup dictionary representing the same domain concept, and a known production bug exists whose direct cause is that one structure was updated without the other, rate the DRY violation High (not Medium). The bug IS the DRY failure manifesting in production. The finding must include: (a) the crash mode (e.g., `KeyNotFoundException` when the array contains a key absent from the dictionary), (b) that any partial fix is dangerous (updating one but not both can crash), (c) the recommended refactor (single ordered array from which the dictionary is derived). Do not downgrade to Medium because the bug is already documented in a correctness audit — the confirmed correctness failure elevates the structural severity.

---

### ORM collection value comparer using count-only equality is a data-loss defect, not a micro-optimization

A value comparer that uses `Count`-only equality and a `Count`-based hash code will cause the ORM change tracker to miss content-level mutations to a collection property. If the list length stays the same but content changes (e.g., an item's name or flag is updated), `SaveChanges` silently skips the UPDATE. Flag any `a.Count == b.Count` comparer on a collection entity property as High — it is a data-loss defect disguised as an optimization. The correct comparer uses structural equality (e.g., `SequenceEqual` or equivalent).

---

### Parallel-looking loops with different iteration sources in state-mutation + audit method pairs

When a method contains two structurally similar loops — one mutating state by iterating a database-sourced collection, the other recording audit events by iterating caller-supplied input — verify that the two loops use the same iteration source and the same skip conditions. A common failure: the mutation loop iterates the persisted collection (skipping caller entries with no matching DB row) while the audit loop iterates the full caller-supplied list (writing records for every entry including skipped ones). This produces phantom audit records for no-op operations. Rate Medium when audit loop source diverges from mutation loop source.
