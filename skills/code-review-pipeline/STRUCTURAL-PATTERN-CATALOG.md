# Structural Pattern Catalog

> # ⚠️ GENERALIZATION RULE — NON-NEGOTIABLE
> **Every entry in this catalog — Signal, Review Question, Severity Guidance, What to Look For, and Origin — MUST be written at an abstract, language- and codebase-agnostic level.**
>
> **FORBIDDEN in any catalog entry:**
> - Class names, interface names, method names, or field names from any specific project or repository
> - File paths, namespace names, project names, or work item IDs
> - Names of any technology, SDK type, or API that would tie the entry to one specific codebase
>
> **The test:** Could this entry be published in a general software engineering book and apply equally to a payments system, a content-management system, or a logistics platform? If not, it is too specific and must be rewritten before being committed.
>
> **When to write vs. where to write:**
> - Generalizable structural patterns → this file
> - Codebase-specific false-positive suppressions → `LessonsLearned.md` (gitignored)
> - Agent-behavior observations across any codebase → `LessonsLearned.GLOBAL.md`

This catalog is read at runtime by `REVIEW-StructuralPatternsAuditor`. Each entry defines a named signal, a review question, and severity guidance.

**To add a new pattern**: Copy the template at the bottom and append it at the end of this file. Do not modify existing entries — only append.

Each pattern that an agent proposes (in its "Suggested New Catalog Entries" section) should be reviewed by the process owner and promoted here if approved.

---

## SP-001 — Numbered Step Comments

**Signal**: Method body contains inline comments that form a numbered progression: `// 1.`, `// 2.`, `// Step N`, `// Phase N`, `// N)`. The numbers appear sequentially inside a single method body.

**Review Question**: "Does each step have a name? Should the method be decomposed into named submethods or delegated to named services?"

**Severity Guidance**:
- **High** if the method also has >3 dependencies injected, spans multiple abstraction levels, or the comments are the only way to understand what the method does
- **Medium** if the method is otherwise clean but the numbered comments indicate a hidden multi-phase structure with distinctly named concerns
- **Low** if the comments are genuinely parallel labels in a fixed-format encoder or data layout (not a sequential workflow)

**What to Look For**:
```csharp
// 1. Validate input
var errors = Validate(request);
// 2. Fetch existing record
var existing = await _repo.GetAsync(id);
// 3. Apply update
existing.Apply(request);
// 4. Persist
await _repo.SaveAsync(existing);
```
The correct form extracts each step into a named method or delegates to a named collaborator. The comments become method names in the call chain.

**Origin**: Identified in a method whose sequential responsibilities were distinguished only by numbered comments, rather than being delegated to named collaborators. The numbered comments were the only documentation of the method's internal structure, signalling that the work belonged in separate, injected services.

---

## SP-002 — Domain Count SRP Violation

**Signal**: Constructor has more than 5 parameters AND the parameter types span 3 or more clearly unrelated infrastructure concerns (e.g., network client + database context + concurrency primitive + file system + event bus).

**Review Question**: "How many unrelated things does this class know about? Could any of these concerns be extracted into a collaborator that this class delegates to?"

**Severity Guidance**:
- **High** if >6 parameters and at least two clusters of fields never interact with each other (e.g., one field group used only by connection-related methods, another group used only by persistence-related methods) — a clear extraction boundary exists
- **Medium** if 5–6 parameters but several are closely related (e.g., two aspects of the same infrastructure concern)
- **Low** if the class is an explicit composition root, factory, or DI registration class where wide knowledge is expected by design

**What to Look For**:
- Constructor parameter list that reads like a dependency-injection shopping list for unrelated systems
- Fields that cluster into 2+ independent groups with no cross-group interaction
- Method-level field usage: if `MethodA` only touches fields 1–3 and `MethodB` only touches fields 4–6, the class has a seam

**Origin**: Identified in a class that mixed transport connection, background monitoring, concurrency control, eligibility evaluation, delay policy, HTTP communication, and database access all in a single constructor. Refactoring produced several focused collaborator types, each owning exactly one infrastructure concern.

---

## SP-003 — Concrete Infrastructure Injection

**Signal**: A constructor in a business-logic, domain, or application-layer class accepts concrete class types (not interfaces) for any dependency that touches I/O, process execution, database access, time, or external services.

**Review Question**: "Can this dependency be swapped in a unit test without a mocking framework or real filesystem/network access? If not, an interface is missing."

**Severity Guidance**:
- **High** in domain or application-layer classes — no interface means no testability and no runtime substitution via DI
- **Medium** in infrastructure-layer classes where the concrete type is already at the outermost integration boundary and a fake is unlikely to be needed
- **Low** if the concrete type is a value object, record, DTO, or configuration struct with no I/O behaviour

**What to Look For**:
- `HttpClient` injected directly (not behind a typed client interface or `IHttpClientFactory`)
- `DbContext` subclass injected directly into a business-logic class
- `Process`, `FileInfo`, `DirectoryInfo` as constructor parameters
- Sealed third-party SDK types injected directly into a consumer class rather than behind an abstraction interface (e.g., a real-time connection client, an SDK session type, a device handle, a vendor-provided request client)
- `DateTime.Now` or `Environment.TickCount` used inline (implicit concrete dependency on system clock)

**Origin**: Identified when a consumer class accepted a sealed third-party connection type directly in its constructor, making the underlying transport un-replaceable without modifying the consumer's production code and preventing unit isolation.

---

## SP-004 — Tell-Don't-Ask on Strategy/Policy Objects

**Signal**: Code calls `x.Build(...)` or `x.GetX(...)` immediately followed by passing the result directly as an argument to `y.Execute(result)` or `y.Do(result)`, where both x and y participate in the same logical operation and are both owned by the same caller.

**Review Question**: "Should `x` own the full operation, so the caller never needs to bridge x's output into y? Can `x.ExecuteWith(context)` replace the two-call chain?"

**Severity Guidance**:
- **High** if the bridging logic is duplicated at multiple call sites or contains conditional logic that the consumer shouldn't know about
- **Medium** if the bridge is a single clean pass-through — still a smell because it leaks the internal two-step structure, but lower urgency
- **Low** if x and y are genuinely from separate layers (e.g., x builds a transport-agnostic message; y is an unrelated serializer from a different library)

**What to Look For**:
```csharp
// Ask the policy object for the intermediate request, then hand it to the runner
var request = _policy.Build(context);               // ask: get intermediate data
var rawResult = await _runner.RunAsync(request, ct); // tell: pass data across boundary
return _policy.Parse(rawResult);                    // ask: interpret the result
```
Correct form: `await _policy.ExecuteAsync(context, ct)` — the policy object owns the full round trip; the caller never sees or bridges the intermediate representation.

**Origin**: Identified in a strategy interface that exposed both a "build" and a "parse" method as separate interface members, requiring the coordinator to bridge the two calls — leaking the internal intermediate representation to a caller that should not know about it. Resolved by collapsing to a single execute-style method that the strategy owns end-to-end.

---

## SP-005 — Gate Misplacement

**Signal**: A concurrency gate (`SemaphoreSlim.WaitAsync`, `lock`, `Interlocked.CompareExchange`, quota/rate-limit check) appears in a method that has already performed an irreversible or difficult-to-reverse side effect earlier in the same logical operation (HTTP resource claim, database insert, external message publish, payment charge).

**Review Question**: "Is there a commitment made before this gate that cannot be undone if the gate blocks or rejects? Should the gate move to before the side effect, or should the side effect be made reversible with explicit compensation?"

**Severity Guidance**:
- **Critical** if the pre-gate side effect is non-reversible in practice (task claim with no un-claim API, payment charge, downstream-triggered workflow)
- **High** if the pre-gate side effect is technically reversible but no compensation path is implemented in the codebase
- **Medium** if the gate is advisory/soft (quota warning, not a hard block) so the race window has limited real-world impact

**What to Look For**:
```csharp
// WRONG: irreversible commitment happens before the concurrency gate
var handle = await _resourceService.AllocateAsync(id, ct);  // commitment first
await _semaphore.WaitAsync(ct);                              // gate AFTER commitment
```
```csharp
// CORRECT: gate before commitment
await _semaphore.WaitAsync(ct);                              // gate first
var handle = await _resourceService.AllocateAsync(id, ct);  // commitment only if slot is available
```

**Origin**: Identified in a dispatch loop where the concurrency semaphore was acquired after an external resource had already been committed. When the semaphore was at capacity, the resource remained allocated but the work was never performed — a permanent resource loss with no compensation or recovery path.

---

## Pattern Template

Copy this template and append above this line to add a new pattern.

```markdown
## SP-NNN — {Pattern Name}

**Signal**: {Describe the syntactic or structural feature to look for — be as specific as possible so the agent can search for it.}

**Review Question**: "{The question the reviewer should ask when the signal is detected. Frame as a direct question that reveals whether a real problem exists.}"

**Severity Guidance**:
- **Critical/High/Medium/Low** if {condition}
- (add more tiers as needed)

**What to Look For**:
{Code example (preferred) or prose description of the concrete signal. Show both the problematic form and the correct form where applicable.}

**Origin**: {Describe the class of situation where this pattern was first identified. **MANDATORY**: Do NOT include any specific class names, interface names, method names, field names, file paths, repository names, project names, or work item IDs. Write only in terms of abstract roles: "a consumer class", "a strategy interface", "a dispatch loop", "a transport layer". The entry must apply equally to any codebase in any domain.}
```
