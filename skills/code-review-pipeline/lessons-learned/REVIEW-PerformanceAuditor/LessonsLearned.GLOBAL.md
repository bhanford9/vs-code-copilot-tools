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

## 2026-05-19 — Full-Project Reviews: Skip the session-config.json base-branch step entirely

When the user specifies "full-project review" (entire codebase, not a diff), the standard `git diff base...HEAD` workflow step is meaningless. Do NOT read or reference `session-config.json` — it may not exist and the base branch concept doesn't apply. Instead, enumerate all source files directly (file search + read all) and treat every file in scope as "changed." Adjust the audit summary wording from "Changes Analyzed" to "Files Analyzed."

---

## 2026-05-19 — Synchronous EF Core calls inside async methods are invisible to the compiler

Synchronous EF Core calls (`.Any()`, `.ToList()`, `.Count()`, `.First()`, `.FirstOrDefault()` without the `Async` suffix on a DbSet) compile without warnings inside async methods. They are easy to miss on a scan. When reviewing repository/service layers, explicitly grep for these suffixless patterns on DbSet-typed variables — do not rely on noticing them while reading code linearly.

---

## 2026-05-19 — ExecuteUpdateAsync always requires a post-load round-trip — do not over-rate it

When `ExecuteUpdateAsync` is used for optimistic concurrency, the code must always reload the entity afterward if any of its fields are needed for subsequent operations (history, response building, etc.). This is the inherent design cost of bypassing the change tracker — it is not a bug. Rate this pattern Medium (not High/Critical) and recommend the explicit trade-off analysis: switch to tracked optimistic concurrency vs. accept the extra round-trip.

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

## 2026-05-14 — For "private method → factory" refactorings, verify allocation equivalence before rating factory overhead

**Observation**: A refactoring that extracts a private method into a factory class (implementing a new interface) was flagged as "one new transient object per request." Reading the factory's `Build()` method revealed it creates the exact same objects as the removed private method. The factory itself is the only new allocation, and at one-per-request frequency it is categorically Low.

**Rule**: When auditing a "private method extracted to factory" pattern: (1) confirm `Build()` creates the same objects as the old method (correctness audit gives this for free), (2) count total DI resolutions before vs. after (usually +1 factory object only), (3) verify DI lifetime direction (Transient factory → Singleton/Transient services is safe), (4) confirm call frequency against the enclosing `new ClassName()` call site. If all four confirm, the correct rating is Low or N/A — not Medium+.

---

## 2026-05-18 — Computed ViewModel properties that call each other multiply materialization cost non-linearly

**Observation**: In an MVVM ViewModel, a computed property (`FilteredEntries`) was called by: a `GroupedEntries` getter (1×), five stat-property getters (5×), and directly via `OnPropertyChanged` (1×). A single refresh method triggering all of these caused 7+ materializations of the same filtered list. The individual getters looked cheap in isolation; the cost was invisible until the call graph was traced.

**Rule**: For any computed property that re-runs a LINQ filter/sort/materialize on every access, trace all callers before rating severity. If the same property is accessed by multiple sibling properties AND those siblings are notified in the same refresh call, multiply the cost accordingly. Rate as High if k × n > ~1,000 for typical data sizes. The fix is always: cache in a backing field, rebuild once, expose the cache.

---

## 2026-05-18 — Fire-and-forget async in a message handler is a dual-risk: exception loss AND thread safety

**Observation**: A `Receive()` message-handler method dispatched an async operation as fire-and-forget (`_ = DoSomethingAsync()`). This introduced two distinct risks: (1) exceptions are silently swallowed, causing stale state with no diagnostic signal; (2) in UI frameworks that dispatch messages on the sender's thread (not the UI thread), the async continuation runs off the UI thread and can trigger invalid cross-thread property-change notifications.

**Rule**: When auditing message handler implementations in MVVM ViewModels: always check (a) whether async is fire-and-forgotten, (b) which thread the message bus delivers on, and (c) whether the async continuation touches UI-bound properties. Flag fire-and-forget in message handlers as High when: the ViewModel has UI-thread-only observable properties AND the message bus does not guarantee UI-thread delivery. Recommend both `try/catch` wrapping and explicit UI-thread dispatch.

---

## 2026-05-16 — Interface contracts in pure domain layers encode performance anti-patterns before any implementation is written

**Observation**: In a code review of a pure contract/domain layer (no EF, no HTTP, no I/O), the most impactful findings were in the interface method signatures, not the runtime method bodies. Specifically: list-returning methods with no pagination parameter force O(n) memory materialization in every compliant implementation; single-ID service methods on a hot loop path encode an N+1 database pattern that no implementation can avoid without violating the contract.

**Rule**: When auditing a domain/contract layer, evaluate every list-returning interface method for: (a) presence of a `skip`/`take`, cursor, or date-range parameter; (b) whether the call site is inside a loop (N+1 risk). A method signature like `GetAllAsync()` returning `IReadOnlyList<T>` with no pagination is a performance bug baked into the contract — it must be fixed before implementations are written because retrofitting pagination after the fact is significantly more expensive. Do not limit performance audits of contract layers to the bodies of the few runtime classes that exist.

---

## 2026-05-16 — "Shared folder as database" architecture: cloud-sync latency replaces HTTP network latency

**Observation**: A codebase that used `System.IO` to read all data from a shared OneDrive folder presented the same performance concerns as a chatty HTTP API — but the transport was the OS cloud-sync client, not a network socket. Files that were locally cached were fast; files that hadn't been synced yet triggered cloud downloads at 100–2000 ms each. The standard "N+1 reads per navigation" pattern applied directly, but the fix is an in-memory TTL cache (read once, hold in memory), not batching or compression.

**Rule**: When reviewing a "shared folder as database" design (local OneDrive, Dropbox, network share), apply the same N+1 detection heuristic as for HTTP: count file reads per user action, not just whether individual reads are "fast on local disk." Recommend a service-level TTL cache before any parallelization — parallelizing cloud-synced reads can overwhelm the sync client and make things worse, not better.

---

## 2026-05-16 — Blazor expression-bodied IEnumerable properties double-enumerate in templates with empty-state guards

**Observation**: A Blazor page declared a `FilteredPackages` property returning `IEnumerable<T>` (lazy LINQ). The template had a standard pattern: `@if (!FilteredPackages.Any())` (empty-state guard) followed by `@foreach (var x in FilteredPackages)` (render). This double-enumerates the lazy LINQ on every render cycle, running the predicate twice per render.

**Rule**: When a Blazor template has both an empty-state guard and a `@foreach` on the same computed sequence, flag the property as double-enumerated. The fix is to materialize to a `List<T>` backing field that is recomputed only when source data or filter state changes. This is a common Blazor gotcha whenever someone adds an "empty results" UX pattern after the fact.

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

## 2026-05-13 — Native graphics libraries: factory methods returning IDisposable do not transfer ownership to the renderer

**Observation**: A `CreatePath()` helper returned a `new SKPath()` (SkiaSharp unmanaged resource). Two call sites (`DrawPolygon`, `DrawGhostLayer`) passed the path to `canvas.DrawPath(...)` without `using var` or `.Dispose()`. The canvas copies/uses the path data immediately and does not take ownership. Each call leaked a native handle.

**Rule**: When reviewing code that uses a native/unmanaged graphics library (SkiaSharp, Direct2D, OpenGL wrappers), verify that `IDisposable` types returned from factory helpers are disposed at the call site. The key signals: (1) a factory method returns `new SKPath()` / `new SKBitmap()` / etc., (2) the result is passed to a draw method, (3) there is no `using` or explicit `.Dispose()`. Draw methods (`canvas.DrawPath`, `canvas.DrawBitmap`) copy/consume the content but do not own or dispose the source object. This is the most common SkiaSharp resource leak pattern.

---

## 2026-04-29 — Double-call pattern across adjacent pipeline steps: check for env-level result caching opportunity

**Observation**: In a stepped pipeline, two adjacent steps called the same O(members × load_cases) operation on identical inputs — one step used a filtered subset of the result, the next step used the complementary subset. Neither step stored the full result for the other to consume. The correct Medium finding is "redundant computation on shared inputs" with the recommendation to cache the result on the shared environment/context object between steps.

**Rule**: When a bump/retry loop contains two consecutive steps that call the same expensive method with the same parameters, flag as Medium. The fix pattern is: (a) identify the shared environment/context object, (b) add a nullable result field for the intermediate value, (c) first step populates it, second step reads it. Only apply if the work is genuinely meaningful (O(N) with non-trivial N) — not for O(1) lookups.

---

## 2026-05-07 — Captive dependency investigation: verify lifetime first, then verify implementation cost before rating

**Observation**: A Singleton service captured another service (IToggles) in its constructor. The question "is this a captive dependency?" was raised as the primary concern. The correct process is two sequential checks:
1. **Verify registration lifetime**: Look for `AddSingleton/AddTransient/AddScoped` across all DI container files. If both sides are Singleton, it is definitionally safe — stop and record "no defect."
2. **If safe, verify per-call cost**: If the captured service is called inside a hot-path LINQ predicate, open the concrete implementation and trace the call chain to the leaf. In this case: Singleton → dictionary TryGetValue — O(1), no I/O, no locks — also safe.

**Rule**: Do not guess the lifetime from the class name or from convention. Grep for the actual registration. For any captured service called in a hot-path predicate, read the implementation before opining on cost. A service can be Singleton-safe but still have hidden per-call overhead (e.g., a lock, a file read) that makes it unsuitable for tight LINQ loops.

---

## 2026-05-06 — `static` property returning `new(...)` is a factory, not a singleton — inspect constructor for hidden overhead before rating

**Observation**: A codebase used a static `get`-only property (`public static T Foo => new(...)`) as a convenient shorthand for a well-known key value. The pattern looked like a constant/singleton at the call site but was a factory allocating a new class instance on every access. Worse, the class constructor called into a global lock-based registry (`KeyIndexer.NextKey`), making each access incur a heap allocation PLUS a lock acquisition. The property appeared inside a hot inner loop, resulting in hundreds of thousands of lock acquisitions per unit of work that could have been reduced to one with a simple hoist.

**Rule**: When reviewing a `static` property (not field) of the form `=> new(...)` accessed inside a loop:
1. Confirm it is a property (arrow getter) not a field — a field would be set once at class initialization
2. Open the type's constructor and check for global registries, locks, or caches
3. If the constructor has side effects (dictionary write, lock, counter), rate the finding at least Medium if accessed in an inner loop
4. The fix is always a local hoist: `var cached = SomeClass.TheProperty;` before the loop

This is distinct from the "struct vs class" lesson — even if allocation cost alone is small, a hidden lock in the constructor escalates severity. Read the constructor, not just the allocation type.
