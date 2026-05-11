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

## 2026-05-06 — Fallback / recovery paths have fundamentally different performance profiles than hot loops

**Observation**: A restore step used O(n) + O(k) traversals (IndexOf scan + linked-list walk). Taken in isolation it looks like a Medium algorithmic concern. But the step ran at most once per design session — only when the entire search loop had already exhausted all options. That upstream exhaustion loop had already done far more work.

**Rule**: Before rating any O(n+) operation, establish call frequency. "At most once per session/request/user-action" is categorically different from "once per inner-loop iteration." If the path is a last-resort fallback that fires only after a preceding loop has already exhausted all options, the fallback's algorithmic cost is almost never the bottleneck — the upstream exhaustion is. Rate such findings Low or omit them unless n is large and unbounded.

---

## 2026-05-06 — In flow-graph or step-graph patterns, distinguish construction-time from execution-time allocations

**Observation**: Default interface implementations of the form `IFlowAction SomeStep => new SomeStep()` looked like per-iteration object creation. Reading the flow builder revealed that step lambdas (`() => [flow.Do(...)]`) are lazy initializers called once during graph construction (via a name-keyed cache), not once per execution. The `new SomeStep()` ran once per flow instance, not once per design iteration.

**Rule**: In rule-engine, flow-graph, or pipeline-builder patterns, check whether object-creating expressions are called at construction time or execution time before writing any allocation finding. Look for: named-step caching (`GetStep(name, () => [...])`), lazy initialization patterns, or builder DSLs. If the lambda runs once to build a graph and the graph is then executed repeatedly, only allocations inside `ExecuteStep`/`Execute`/`Run` methods (not the graph-building lambda) contribute to per-execution cost.

---

## 2026-05-06 — Check if the target property is itself an allocating expression before writing an O(n) finding

**Observation**: A `FirstOrDefault(...)` call looked like an O(n) linear search concern. Reading the preceding property revealed it was expression-bodied and called `.Concat().ToList()` on every access — the heap allocation was the actual concern, not the scan length. The linear scan over small fixed-n (10–40 items) is negligible; the per-call allocation in a hot calculation loop is the real finding.

**Rule**: When flagging a `FirstOrDefault`/`.Where()`/`.Select()` call as an O(n) concern, immediately also check the type returned by the preceding property/accessor. If that accessor is expression-bodied and calls `.ToList()` / `.ToArray()` / `.Concat().ToList()`, the allocation dominates the cost — write the finding about the allocation, not just the scan. The fix is typically to target a pre-allocated typed sub-collection directly (reducing both allocation and scan scope in one change).

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

## 2026-05-08 — In MVVM+Blazor codebases, distinguish PropertyChanged frequency from render-relevant property changes

**Observation**: Board sub-components subscribed to `ViewModel.PropertyChanged` with no filter, calling `StateHasChanged` on every property change. The tempting interpretation is "anything could affect the view" — but in practice, ViewModel properties divide into two groups: task-data properties (mutations to the `Tasks` collection or scored fields) that do need re-renders, and UI-state properties (`EditingTaskId`, `IsLoading`, `CurrentView`) that trigger re-renders in components that have no dependency on those properties. The correct fix is property-name filtering in the handler, not full re-render on every signal.

**Rule**: When reviewing a `PropertyChanged` subscription in a Blazor component that calls `StateHasChanged` unconditionally, always check: (a) which ViewModel properties does this component's template actually read? (b) which `PropertyChanged` signals are actually mutation-relevant? If the component only renders task-list data, filter out `EditingTaskId`, modal state, and filter selections that belong to sibling components.

---

## 2026-05-08 — Expression-bodied properties that call ToList() are double-materialization risks in Blazor templates

**Observation**: A `private IReadOnlyList<T> WhatNowItems => source.ToList()` pattern looked like a single materialization. Reading the Razor template showed it was referenced twice (`!WhatNowItems.Any()` guard + `@foreach`) — producing two full LINQ pipeline executions per render. This is a common Blazor pattern-mistake because expression-bodied properties feel like computed values but actually execute on each access.

**Rule**: When reviewing a Blazor component's code-behind for `IEnumerable<T>` or `IReadOnlyList<T>` expression-bodied properties that call `.ToList()`, immediately check the razor template for multiple access points (`.Any()` + `foreach`, `.Count` + `foreach`, etc.). If found, flag as a medium allocation/compute finding. The fix is always to assign to a field in the lifecycle method, not a property getter.

---

## 2026-04-29 — Double-call pattern across adjacent pipeline steps: check for env-level result caching opportunity

**Observation**: In a stepped pipeline, two adjacent steps called the same O(members × load_cases) operation on identical inputs — one step used a filtered subset of the result, the next step used the complementary subset. Neither step stored the full result for the other to consume. The correct Medium finding is "redundant computation on shared inputs" with the recommendation to cache the result on the shared environment/context object between steps.

**Rule**: When a bump/retry loop contains two consecutive steps that call the same expensive method with the same parameters, flag as Medium. The fix pattern is: (a) identify the shared environment/context object, (b) add a nullable result field for the intermediate value, (c) first step populates it, second step reads it. Only apply if the work is genuinely meaningful (O(N) with non-trivial N) — not for O(1) lookups.
