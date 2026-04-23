# Lessons Learned: REVIEW-PerformanceAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future performance reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-04-22 — Verify struct vs class before flagging as allocation concern

**Observation**: When a method creates a `new SomeType(...)` inside a loop or hot path, it looks like a heap allocation — but if the type is a struct it is a stack allocation with no GC cost. False positives are common for auditors unfamiliar with geometry and math libraries whose core types are value types.

**Rule**: Always confirm `struct` vs `class` — look at the type definition or docs — before writing any allocation/GC finding. One lookup prevents a false positive that may look convincing in a report.

---

## 2026-04-22 — Read the implementation before claiming computational cost

**Observation**: A method called inside a retry/bump loop was flagged as Medium based on its name and loop position alone. Reading the actual implementation showed it received pre-computed results as a parameter and only recomputed check ratios — the expensive estimation step was not re-run. The name implied far more work than the code performed.

**Rule**: For any Medium+ performance finding about a method call inside a loop, open the implementation and trace the actual execution path before writing the finding. "Sounds expensive" is not sufficient. Verify: (a) what inputs does the method receive — already-computed results or raw inputs? (b) is there a cache layer (`??=`, dictionary, factory) that short-circuits work? A wrong cost claim corrected by a developer during code review damages report credibility.

---

## 2026-04-22 — Small-n pre-existing framework patterns: do not escalate

**Context**: `SegmentedEdge.DistanceAlong` calls `_line.ToSegments()` multiple times without caching. `FitOuterLappedChordReinforcement` is created per-property-access in logic providers.

**Observation**: Both are pre-existing patterns not introduced by the change under review. n = 2–5 segments makes the repeated enumeration immeasurable. The finding is Low/pre-existing and worth noting but not escalating.

**Rule**: When raising a finding on a geometry framework helper, confirm whether it was introduced by the change or was already present. Pre-existing patterns at small fixed n should be Low at most, with a clear note that the change did not introduce them.
