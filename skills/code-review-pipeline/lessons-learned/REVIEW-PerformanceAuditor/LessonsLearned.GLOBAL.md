# Lessons Learned: REVIEW-PerformanceAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

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

## 2026-04-24 — When new code is inserted inside an existing inner loop, check hoistability before writing the finding

**Observation**: A new `if` branch was added inside an existing nested loop. The branch introduced a LINQ query whose result depended only on the outer-loop context (the load combination key), not the inner-loop variable (the force output). Because it was inside the inner loop, it ran n_inner times with the same result every time — classic hoistable computation.

**Rule**: When reviewing any new code added inside an `if` block or nested loop, immediately ask: "Does any sub-expression depend only on outer-scope variables?" If yes, flag as a Medium hoisting opportunity. This is especially common when a developer adds a feature branch inside an existing loop without considering that the branch condition or its sub-computations could be evaluated once before the loop.

---

## 2026-04-22 — Small-n pre-existing framework patterns: do not escalate

**Context**: `SegmentedEdge.DistanceAlong` calls `_line.ToSegments()` multiple times without caching. `FitOuterLappedChordReinforcement` is created per-property-access in logic providers.

**Observation**: Both are pre-existing patterns not introduced by the change under review. n = 2–5 segments makes the repeated enumeration immeasurable. The finding is Low/pre-existing and worth noting but not escalating.

**Rule**: When raising a finding on a geometry framework helper, confirm whether it was introduced by the change or was already present. Pre-existing patterns at small fixed n should be Low at most, with a clear note that the change did not introduce them.

---

## 2026-04-29 — Expression-bodied logic-provider properties: resolve via GetStep memoization before flagging

**Observation**: A logic provider's expression-bodied property (`=>`) that creates new sub-flow instances on every access appeared to be a repeated-allocation concern because the property was referenced inside a loop construct. Reading the flow DSL's `GetStep` implementation revealed it memoizes by step name using a `HashSet` — the containing factory lambda is evaluated exactly once per `BuildFlow` call, making the property access happen exactly once per design run.

**Rule**: Before flagging "property creates instances on every access" in a flow-graph DSL: (a) locate the `GetStep` / `Flow` DSL method, (b) confirm whether it deduplicates by name, (c) confirm how many times `BuildFlow` is called per unit of work. Only raise a finding if all three confirm repeated evaluation. This avoids a false positive that looks compelling from call-site inspection alone.

---

## 2026-04-29 — Double-call pattern across adjacent pipeline steps: check for env-level result caching opportunity

**Observation**: In a stepped pipeline, two adjacent steps called the same O(members × load_cases) operation on identical inputs — one step used a filtered subset of the result, the next step used the complementary subset. Neither step stored the full result for the other to consume. The correct Medium finding is "redundant computation on shared inputs" with the recommendation to cache the result on the shared environment/context object between steps.

**Rule**: When a bump/retry loop contains two consecutive steps that call the same expensive method with the same parameters, flag as Medium. The fix pattern is: (a) identify the shared environment/context object, (b) add a nullable result field for the intermediate value, (c) first step populates it, second step reads it. Only apply if the work is genuinely meaningful (O(N) with non-trivial N) — not for O(1) lookups.
