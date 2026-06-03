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

## SP-006 — Closed Stage List

**Signal**: A result type (record, class, or struct) has multiple fields of the same concrete type, where each field name is a stage name, criterion name, or gate name rather than a data category name. This is paired with a single evaluation method that assigns each field via sequential conditional logic — one block per named stage.

**Review Question**: "When a new evaluation stage is needed, how many separate types and methods must change? If the result type itself must grow a new named field every time a stage is added, the stage set is baked into the type contract — making every extension a structural breaking change."

**Severity Guidance**:
- **High** if the stage count is ≥4, the result type lives in a shared contract or domain layer, or there is documented expectation that stages will grow over time
- **Medium** if stages are stable but the monolithic evaluation method prevents per-stage unit testing without running all stages
- **Low** if ≤3 stages with no indication of growth and the evaluation method is short enough to remain readable without extraction

**What to Look For**:
```csharp
// SMELL: result record encodes stage names as field names
public record EvaluationResult(
    StageResult Completeness,       // stage name as field name
    StageResult Authorization,      // stage name as field name
    StageResult ResourceAvailability, // stage name as field name
    IReadOnlyList<string> Blockers
);

// SMELL: evaluation method assigns each field sequentially
public EvaluationResult Evaluate(Request r)
{
    StageResult completeness = CheckCompleteness(r);
    StageResult authorization = CheckAuthorization(r);
    StageResult resourceAvailability = CheckResourceAvailability(r);
    return new EvaluationResult(completeness, authorization, resourceAvailability, ...);
}
```
```csharp
// CORRECT: result uses a keyed collection; stages are data, not field names
public record EvaluationResult(
    IReadOnlyDictionary<StageName, StageResult> Stages,
    IReadOnlyList<string> Blockers
);

// CORRECT: evaluation delegates to an injected gate list
public EvaluationResult Evaluate(Request r, IEnumerable<IEvaluationGate> gates)
{
    var stages = gates.ToDictionary(g => g.Name, g => g.Evaluate(r));
    ...
}
```
Adding a new stage: one new gate class + one DI registration. The result type and the orchestrating method are untouched.

**Origin**: Identified in an evaluation service that implemented a fixed set of named validation criteria as a single method with one local variable per criterion name, paired with a result record that had one field per criterion. Adding a new criterion required modifying both the evaluation method and the result type — a two-file breaking change. Resolved by extracting each criterion into a gate interface registered via DI, and replacing the named fields with a keyed dictionary so the result type never needs to change when criteria are added.

---

## SP-007 — String Key for In-Solution Strategy Dispatch

**Signal**: A strategy pattern, factory lookup, or keyed-dispatch mechanism uses a `string` as the discriminator key, but all strategy implementations and all call sites that produce or consume those keys are defined within the same solution and are known at compile time.

**Review Question**: "Can all valid key values be enumerated at compile time from within this solution? If yes, a string key provides no advantage over an enum — and loses compiler enforcement, rename-refactoring support, and exhaustiveness checking at switch sites."

**Severity Guidance**:
- **High** if key values are assembled from or compared against user input, external configuration, or database columns — mismatches are undetectable until runtime and strings in the codebase can silently drift from values stored externally
- **Medium** if keys are all literal constants defined in code but scattered across multiple files or classes with no central declaration, making a rename or audit difficult
- **Low** if the string key is intentional for runtime extensibility — keys represent plugin identifiers, feature flags, or agent types loaded from configuration at startup that may not be known at build time; in this case the design intent should be documented explicitly

**What to Look For**:
```csharp
// SMELL: string discriminator where all values are in-solution constants
public interface IProcessor
{
    string ProcessorType { get; }  // returns a string literal in every implementation
}

// Consumer resolves by string — no compiler check if the string drifts
var processor = _processors.First(p => p.ProcessorType == "batch-export");
```
```csharp
// CORRECT: enum discriminator for in-solution fixed strategy sets
public interface IProcessor
{
    ProcessorType Type { get; }    // enum — exhaustiveness is compiler-checkable
}

var processor = _processors.First(p => p.Type == ProcessorType.BatchExport);
```
The string-vs-enum distinction is intentional only when keys originate outside the solution (e.g., a plugin loaded from a NuGet package or a config file shipped by a third party). For all other cases, prefer an enum.

**Origin**: Identified in a strategy registry where the discriminator was a `string` property returning a literal constant in every implementation. All consumers compared against those string literals directly. Since every possible value was defined within the solution, there was no reason to forgo the compile-time safety of an enum — renaming a strategy required a grep rather than a refactor, and typos in string comparisons were not caught at build time. Resolved by replacing the string discriminator with an enum whose cases enumerated all in-solution strategies.

---

## SP-008 — Excessive Test Arrangement Complexity

**Signal**: The arrange phase of a test for a single behavior requires constructing or mocking 5 or more collaborators, or involves multi-step orchestration (seeding state into one fake, wiring a fake to another, arranging lifecycle transitions) before the single act under test can execute. The setup lines outnumber or dwarf the assertion lines.

**Review Question**: "Is the test arrangement complex because the behavior is genuinely complex, or because the production class does not expose a seam that isolates this behavior from unrelated concerns? Would splitting the class along its natural responsibility boundaries reduce the mock count to 1–2 for any single test?"

**Severity Guidance**:
- **High** if the arrangement complexity is caused by multiple unrelated domains being coupled in a single class — the test is reflecting a real SRP violation that makes each concern hard to exercise independently
- **Medium** if the complexity is caused by missing abstraction interfaces over infrastructure — concrete dependencies that cannot be faked without real I/O, where adding interfaces would unlock direct isolation
- **Low** if the behavior under test is a genuine integration point that coordinates several collaborators by documented design, and a narrower unit-scope test cannot reasonably be extracted

**What to Look For**:
```csharp
// SMELL: 6 mocks required to verify a single email confirmation behavior
[Test]
public async Task ProcessOrder_SendsConfirmationEmail()
{
    var mockRepo      = new Mock<IOrderRepository>();
    var mockInventory = new Mock<IInventoryService>();
    var mockPricing   = new Mock<IPricingEngine>();
    var mockAudit     = new Mock<IAuditLog>();
    var mockEmail     = new Mock<IEmailService>();
    var mockNotify    = new Mock<INotificationGateway>();

    mockRepo.Setup(...).ReturnsAsync(order);
    mockInventory.Setup(...).ReturnsAsync(true);
    mockPricing.Setup(...).Returns(price);
    // ... more setup ...

    var sut = new OrderProcessor(mockRepo.Object, mockInventory.Object,
                                  mockPricing.Object, mockAudit.Object,
                                  mockEmail.Object, mockNotify.Object);
    await sut.ProcessAsync(orderId);

    mockEmail.Verify(e => e.SendConfirmationAsync(It.IsAny<Order>()), Times.Once);
}
```
```csharp
// CORRECT: after extracting a focused notification step class:
[Test]
public async Task SendConfirmation_InvokesEmailGateway()
{
    var mockEmail = new Mock<IEmailService>();
    var sut = new EmailConfirmationStep(mockEmail.Object);
    await sut.ExecuteAsync(order);
    mockEmail.Verify(e => e.SendConfirmationAsync(order), Times.Once);
}
```
When the mock count in a test's arrange phase is high, read the number as the class's dependency count reflected back — not a testing problem, but a structural one. Each additional mock that is irrelevant to the assertion is evidence of a concern the class should have delegated.

**Origin**: Identified in test suites where the majority of mocked collaborators in an arrange phase were not referenced by any assertion. The excessive setup was a mirror of the production class carrying responsibilities it should have delegated to focused collaborators. Splitting the class along its natural responsibility boundaries reduced mock counts per test and made each resulting test describe a single clear behavior.

---

## SP-009 — Untestable Logic Path

**Signal**: A block of business logic, conditional branching, or validation lives inside a method that also directly invokes infrastructure (database reads/writes, HTTP calls, file system operations, system clock, message dispatch). No injection point exists that would allow the decision-making logic to be exercised by a unit test without standing up the full infrastructure.

**Review Question**: "Can the decision-making logic in this method be reached by a unit test without real infrastructure? If not, what is the smallest extraction that would create a testable seam — an extracted method taking its inputs as parameters, a collaborator interface, or a separated decision object?"

**Severity Guidance**:
- **High** if the untestable path contains business rules, conditional routing, or validation logic that is subject to business change and regression — these are precisely the paths most worth testing, and the structure is preventing it
- **Medium** if the path contains transformation or mapping logic that is unlikely to be a frequent source of bugs, but extracting it would still improve maintainability and enable focused assertions
- **Low** if the path is pure plumbing with no business behavior (logging, metrics emission, retry telemetry) — a test of that specific line provides limited value and the structural smell is minor

**What to Look For**:
```csharp
// SMELL: business rule is untestable without real DB and real clock
public async Task SubmitAsync(Order order)
{
    var existing = await _db.Orders.FindAsync(order.Id);  // real DB required
    if (existing == null)
        throw new NotFoundException();

    // Business rule buried here — cannot be tested without real infrastructure
    if (DateTime.UtcNow > existing.CutoffTime)            // real clock required
        throw new SubmissionClosedException();

    await _messageBus.PublishAsync(new OrderSubmitted(order)); // real bus required
}
```
```csharp
// CORRECT: business rule extracted to a pure, directly unit-testable decision object
public class SubmissionPolicy
{
    public void ThrowIfClosed(Order order, DateTimeOffset now)
    {
        if (now > order.CutoffTime)
            throw new SubmissionClosedException();
    }
}

// No infrastructure needed:
[Test]
public void ThrowIfClosed_PastCutoff_Throws()
{
    var policy = new SubmissionPolicy();
    var order  = new Order { CutoffTime = DateTimeOffset.UtcNow.AddHours(-1) };
    Assert.Throws<SubmissionClosedException>(
        () => policy.ThrowIfClosed(order, DateTimeOffset.UtcNow));
}
```
When a line of code cannot be reached directly by a unit test, ask whether the difficulty is accidental (a concrete dependency blocking substitution) or structural (the logic itself is entangled with I/O). In either case the fix is a seam — an extracted interface, a clock abstraction, a decision object — that lets the logic and the infrastructure be exercised independently.

**Origin**: Identified in service methods where decision logic and infrastructure coordination were mixed in the same method body. The business rules — the most change-prone parts of the system — could only be verified through slow, fragile integration tests that required real databases, clocks, or message brokers. Extracting each rule into a parameter-driven decision class made it directly reachable by fast, isolated unit tests, while the infrastructure coordination method remained responsible only for wiring.

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
