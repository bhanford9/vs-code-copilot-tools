# Lessons Learned: REVIEW-PerformanceAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future performance reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-04-22 — MathNet.Spatial `struct` types: verify before flagging as allocation concerns

**Context**: Auditing a structural engineering design engine (JEDI v2) that uses MathNet.Spatial.

**Observation**: `Line2D`, `Point2D`, and `Vector2D` in MathNet.Spatial are **value types (structs)**. A `new Line2D(p1, p2)` call is a stack allocation, not a heap allocation. Do not flag these as GC pressure sources without first confirming the type is a class.

**Rule**: When reviewing geometry-heavy C# code using MathNet.Spatial, check whether the type is a struct before raising a memory/allocation finding. False positives here are common for auditors unfamiliar with the library.

---

## 2026-04-22 — Small-n pre-existing framework patterns: do not escalate

**Context**: `SegmentedEdge.DistanceAlong` calls `_line.ToSegments()` multiple times without caching. `FitOuterLappedChordReinforcement` is created per-property-access in logic providers.

**Observation**: Both are pre-existing patterns not introduced by the change under review. n = 2–5 segments makes the repeated enumeration immeasurable. The finding is Low/pre-existing and worth noting but not escalating.

**Rule**: When raising a finding on a geometry framework helper, confirm whether it was introduced by the change or was already present. Pre-existing patterns at small fixed n should be Low at most, with a clear note that the change did not introduce them.
