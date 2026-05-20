# Lessons Learned: REVIEW-SecurityAuditor

> # ⚠️ GLOBAL FILE — CODEBASE-SPECIFIC CONTENT IS STRICTLY FORBIDDEN
>
> **This file is committed to a public shared repository and read across all projects and codebases.**
>
> **BANNED — do NOT write any of the following:**
> - Class names, interface names, method names, type names, field names
> - File paths, namespace names, project names, solution names
> - Work item IDs, ticket numbers, branch names, version identifiers
> - Domain-specific abbreviations or industry jargon unique to one team or product
> - Any identifier specific to one repository, team, or system
>
> **Write ONLY:** abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
>
> **Proper-noun test:** Remove all proper nouns from your proposed entry. If it still makes sense as general engineering advice, it belongs here. If understanding it requires knowing the project, move it to `LessonsLearned.md` (gitignored, local only).
>
> **MANDATORY SANITIZATION GATE — run before every append:**
> 1. List every capitalized identifier and domain abbreviation in the proposed text.
> 2. Classify each: standard framework/language type (safe) OR project-specific (banned).
> 3. Replace all project-specific items with generic placeholders before writing.
> 4. Re-read. If the entry still requires knowing the project to understand it, move it to `LessonsLearned.md`.
>
> ⚠️ **Most common violation: an abstract lesson body with a concrete project-specific example. Generalizing the headline is not enough — generalize or remove the example too.**

---

## Correctness Findings Often Double as Security Findings

When a correctness audit has already run, some bugs are dual-natured: both a logic error and a security vulnerability. A null-token bypass in a credential comparison is the canonical example — the correctness report calls it "double-completion," while the security report should re-characterize it as "authentication bypass." Don't skip a finding because it appeared in another audit; instead, add the security framing: attack vector, exploitability, and OWASP mapping.

## EF Core LINQ Is Safe Against SQL Injection By Default

EF Core LINQ queries (`Where`, `FindAsync`, etc.) always produce parameterized SQL. Do not audit for SQL injection in standard data-access code unless `FromSqlRaw`, `ExecuteSqlRaw`, or string-interpolated queries are present. Grep for those patterns first as a rapid-disqualification shortcut.

## Base `appsettings.json` Is Active In ALL Environments

ASP.NET Core config layers: `appsettings.json` (always loaded) → `appsettings.{Env}.json` (merged on top). A hardcoded credential in the base file is a security risk even when the environment-specific file is present — it is only safe if the environment-specific file explicitly overrides that key. Always confirm the override exists for every environment that runs in production.

## `[JsonIgnore]` on Credential Fields Is Necessary But Not Sufficient

`[JsonIgnore]` blocks default System.Text.Json serialization. It does nothing for: structured loggers that inspect object graphs, direct entity returns in controller actions, and diagnostic/debug endpoints. Verify at the API boundary that sensitive entities are never returned directly.

## `PGPASSWORD` in Process Environment Deserves Medium Severity

Passing credentials via process environment variables (`PGPASSWORD`) is standard practice for non-interactive `pg_dump`, but it exposes the credential in the OS process table for the lifetime of the process. Flag as Medium (not Low) in any production-facing service. Note the mitigation path: a temporary `pgpass` file with restricted permissions, removed after the subprocess exits.

## Non-Constant-Time Token Comparisons Are Low in Local Single-Tenant Tools

Standard string equality (`==`, `!=`) is not timing-safe. However, timing attacks over loopback TCP are practically infeasible against strong tokens (>= 128-bit entropy). Classify as Low for local single-tenant deployments, Medium if the comparison is over a network boundary or the token space is small. Always recommend the fix (`CryptographicOperations.FixedTimeEquals`) regardless of severity.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future security reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-18 — SignalR Authentication Token in URL Query String

**Pattern**: When auditing SignalR hub connections, always check whether the authentication token is passed as a URL query parameter vs. an `Authorization: Bearer` header. Query parameters appear in server access logs, proxy logs, and process-level network monitors in plain text — bypassing all `ToString()` redaction and `[JsonIgnore]` protections applied elsewhere. The correct pattern for SignalR is to use `AccessTokenProvider` on `HubConnectionBuilder`, which causes the token to be sent as a header during the HTTP negotiate phase.

**Heuristic**: Search for `.WithUrl(` calls in any SignalR client code. If the URL is built with string interpolation that includes a token, credential, or key, flag it as High — the token will appear in server access logs unconditionally.

**Severity guidance**: High when the token is long-lived (machine registration, API key). Medium when the token is short-lived and per-session.

---

## 2026-05-18 — LLM Dispatch Architecture: Prompt Injection Is an Inherent Risk

**Pattern**: In any system that takes user-controlled text from a data store (task titles, descriptions, comments) and constructs an LLM prompt from it without sanitization, prompt injection is present by design. The risk is amplified when the agent runs with permissive flags (equivalent to `--allow-all-tools`, `--no-ask-user`) that remove human confirmation. The standard mitigation is a fixed system-level preamble that explicitly scopes the agent and tells it to ignore instructions embedded in data fields.

**Heuristic**: For any LLM dispatch or agent-automation codebase, locate the code that builds the prompt string. Check: (1) does it include user-authored fields? (2) is there a fixed system instruction that precedes those fields and cannot be overridden? (3) are the agent's tool permissions minimized for the category of task? Flag as Medium if all three are absent.

**Severity guidance**: Medium for internal tools with authenticated task creation. High if task creation is externally accessible (e.g., via a public API). Critical if the agent has shell or filesystem access and `--allow-all-tools` is set.

---

## 2026-05-08 — Scope-Relative Severity for Absent Auth

**Pattern**: When a personal/local-only application has no authentication, resist classifying this as Critical/High at face value. Apply a deployment-context matrix: localhost-only = Medium; LAN-accessible = High; internet-facing = Critical. Flag it clearly with the escalation condition rather than assigning worst-case severity for a tool that is demonstrably scoped to single-user local use.

**Heuristic**: Check whether the architectural intent (personal tool, no multi-user model) is apparent from the domain model, DI registration, and README before assigning severity to missing auth.

---

## 2026-05-08 — Binary Database Files in Git

**Pattern**: Design-time or migration-scaffolding database files (SQLite `.db`, Access `.mdb`, etc.) frequently appear committed to source repositories. They are binary blobs that do not belong in git: they can accumulate real data, cause merge conflicts, and bloat history. Always check `git ls-files` for `*.db` patterns during security reviews. Classify as Medium if only schema is present, escalate if real data is detected.

---

## 2026-05-19 — Blazor `@` Binding Auto-Encodes: XSS Via Toast/Label Content Is Not a Valid Finding

**Pattern**: In Blazor (Server, WASM, Hybrid), the standard `@expression` syntax in `.razor` files applies HTML encoding unconditionally before writing to the DOM. A `@toast.Message` or `@entry.Email` binding cannot produce XSS regardless of what the string contains — it will be rendered as literal text, not markup. This applies to both text node interpolation and attribute values bound via `@`.

**Exception**: XSS is still possible if the developer explicitly opts out via `@((MarkupString)rawHtml)` or `@Html.Raw(...)`. These require deliberate use of `MarkupString` or `IHtmlContent`. Always grep for `MarkupString` in any Blazor codebase if XSS is a concern.

**Heuristic**: Start Blazor XSS analysis by searching for `MarkupString` and `Html.Raw` rather than examining individual `@expression` bindings. If neither exists, the XSS surface is essentially zero.

---

## 2026-05-19 — System.Text.Json Typed Deserialization Is Safe Against Gadget-Chain Attacks

**Pattern**: `JsonSerializer.Deserialize<T>()` with a concrete or generic type target does not support polymorphic type instantiation by default. An attacker cannot inject a `$type` field to force construction of an arbitrary .NET type — System.Text.Json ignores unknown properties and deserializes only into the declared type. The risk only re-opens when `[JsonDerivedType]` attributes or a custom `JsonConverter`/`DefaultJsonTypeInfoResolver` with `IncludeFields = true` and broad type resolution is present.

**Heuristic**: For any `JsonSerializer.Deserialize` call, only escalate to a deserialization-gadget finding if `[JsonDerivedType]`, `JsonConverter`, or polymorphic resolver configuration is present. Grep for those patterns first as a rapid-disqualification shortcut.

---

## 2026-05-19 — Unvalidated Path Parameters in Service Method Signatures Are a Latent Risk Pattern

**Pattern**: Service methods that accept a folder or file path as a `string` parameter and use it directly in `Path.Combine` + write operations have no guaranteed trusted-root at the method boundary. Even when all current callers supply trusted values (e.g., from `Directory.EnumerateDirectories`), the method signature is an open invitation for future callers to supply an arbitrary path. The risk is latent, not present.

**Heuristic**: When a `Save*` or `Write*` method takes a path parameter and the service has a concept of a "configured root" (e.g., from settings), always check whether the method asserts `Path.GetFullPath(paramPath).StartsWith(rootPath)`. If not, flag as Low with a concrete remediation snippet. Do not escalate beyond Low unless a current caller is actually untrusted.

**Severity guidance**: Low for internal tools where all callers are in the same process. Medium if the path parameter is derived from a network payload or user-submitted form value.

---

## 2026-05-18 — Fire-and-Forget Async in MVVM Message Receivers Is a Dispatch-State Risk

**Pattern**: In CommunityToolkit.Mvvm (and similar MVVM frameworks), `IRecipient<T>.Receive()` is synchronous by interface contract. When a message triggers async work, the idiomatic result is `_ = SomeAsyncMethod()` — a discarded task. This silently swallows any exception thrown by the async path. If the async work updates security-relevant in-memory state (e.g., dispatch approval flags, task status), a failure leaves the ViewModel in a stale, potentially misleading state with no error signal to the user.

**Heuristic**: During any security review of a CommunityToolkit.Mvvm (or similar) codebase, scan all `IRecipient<T>.Receive` implementations for `_ = ` patterns. If the discarded task touches dispatch, approval, or authorization-adjacent state, classify as Medium and recommend a wrapping catch that resets the card/entity to a safe state on failure.

**Severity guidance**: Medium when the stale state is security-relevant (dispatch approval, status transitions). Low when the stale state is purely cosmetic (display label, count).

---

## 2026-05-18 — MVVM Dispatch Approval Gates: ViewModel Should Assert Pre-Conditions

**Pattern**: In MVVM dispatch approval flows, the ViewModel layer is the last place where domain context (task state, category config) is available before a service call. When the service is the only enforcement gate for a safety-critical operation (autonomous dispatch), any regression or future gap in the service layer is unchecked. The ViewModel should assert readily-available pre-conditions (e.g., verifying the domain entity's own flag that permits the operation) before calling the service.

**Heuristic**: For any approval or dispatch-enabling method in a ViewModel, ask: "Does the ViewModel have access to a property that would immediately disqualify this call?" If yes, assert it before the service call — even if the service will also enforce it. The cost is one `if` statement; the benefit is defense-in-depth for an irreversible operation.

**Severity guidance**: Medium for local tools with trusted callers. High if the ViewModel is invoked via an API or inter-process boundary where the caller cannot be trusted.

---

## 2026-05-12 — CSS Injection via Inline Style Attribute with User-Controlled Color Field

**Pattern**: Color fields (hex color pickers in UI forms) that feed into inline `style="background-color: @Color"` attributes are a CSS injection vector. Blazor's HTML encoding neutralizes HTML-special characters but does NOT prevent CSS token injection (e.g., `#fff; display:none`). When auditing, always trace `color`-type fields from their origin (user input / DB) through to any `style=` attribute usage. Validate with a strict hex color regex at the service layer.

**Heuristic**: Check all `style=` attribute expressions in Razor files for any dynamic value sourced from user data. CSS injection is easily missed because the obvious XSS vectors (script tags, event handlers) are absent.

---

## 2026-05-12 — Hardcoded Fallback Connection Strings in Dev-Time Factory and CLI Bootstrap

**Pattern**: Design-time EF Core factories (`IDesignTimeDbContextFactory`) and CLI tools that bootstrap their own DI often contain hardcoded fallback connection strings so they work "out of the box" during development. These fallbacks routinely end up committed to git and can carry production-equivalent credentials if password hygiene is poor. During security reviews, always check `IDesignTimeDbContextFactory` implementations and CLI `Program.cs` bootstrap sections for `??` fallback connection strings.

**Heuristic**: Fail fast with an explicit error message when the environment variable or config is absent — do not provide a default that makes credentials optional.

---

## 2026-05-12 — `ProcessStartInfo.Arguments` vs `ArgumentList` for Subprocess Safety

**Pattern**: When a C# codebase spawns external processes with `UseShellExecute = false`, shell injection is not a risk. However, if `ProcessStartInfo(fileName, arguments)` is used with a single string `arguments`, and any segment of that string is constructed from config or user data without quoting, argument-splitting bugs can occur (spaces in values, unexpected extra args). The safe alternative is `ProcessStartInfo.ArgumentList` which passes each argument as a separate element without any quoting/parsing. Always prefer `ArgumentList` over the string `Arguments` property when constructing arguments programmatically.

---

## 2026-05-12 — Pure Internal Domain Logic: OWASP Non-Applicability Pattern

**Pattern**: For changes that are entirely within a deep-pipeline calculation engine (no network, no I/O, no external API surface, no user input crossing a trust boundary), the majority of the OWASP Top 10 is structurally non-applicable. The meaningful security question for this class of change is: "Can a flow-skip or short-circuit produce an unsafe domain output?" — not injection, access control, or cryptography.

**Heuristic**: When all inputs to a changed class are in-process domain objects set by prior trusted pipeline stages, write concise "Not applicable" explanations for each OWASP category rather than forcing speculative findings. For flow-control changes specifically, verify: (1) the skip is bounded (does not persist indefinitely), (2) a fallback path ensures correct output on subsequent iterations, and (3) unit tests cover the boundary conditions of the skip predicate.

---

## 2026-05-12 — Flow Exit Log Strings in Engineering Tools Are Not Sensitive Data

**Pattern**: Internal flow frameworks in engineering tools use descriptive string literals as exit/skip reasons. These are execution traces, not user-facing messages, and contain no sensitive data.

**Heuristic**: Do not classify these as information disclosure findings unless the framework demonstrably surfaces them externally (API response, browser, log shipped off-machine). At most, note them as Low/informational with the escalation condition.

---

## 2026-05-13 — `Path.Combine` Does Not Sanitize Inputs — Always Sanitize String Paths From Non-Literal Sources

**Pattern**: `Path.Combine(baseDir, untrustedSegment)` on .NET has two path-traversal behaviors: (1) a relative `..`-containing segment traverses above the base directory (Windows resolves `..` at the OS level during `Directory.CreateDirectory` / `File.Open`), and (2) an absolute-path segment completely discards the base directory. This applies even when the data source is "trusted" (internal DB, internal API). A string field in a database is still a string and can contain path characters if data quality is not enforced at the schema level.

**Heuristic**: Any string that is not a compile-time literal and is used in `Path.Combine` requires sanitization — strip `\`, `/`, `:`, and `..` sequences before use. Check whether the code applies the same sanitization consistently to all segments (not just some of them).

**Severity guidance**: For dev/diagnostic tools with an internal trusted data source, classify as Medium (not High), document the low practical exploitability, and provide the one-line fix. Reserve High for tools with external user input at this boundary.

---

## 2026-05-16 — User-Editable Local Settings File as Identity Source Is a Spoofing Vector

**Pattern**: When a desktop application persists user identity (e.g., Windows username) in a plaintext local settings file and that identity is then used in file path construction or cross-user write operations, the settings file becomes an impersonation attack surface. Even though the file is "local" and "user-scoped," any process running as that user (or any user with access to `%APPDATA%`) can alter the identity field. The stored username then controls which files are written on behalf of whom.

**Heuristic**: At startup, compare the stored identity field against `Environment.UserName` (or equivalent OS-sourced identity). If they diverge, reset to the OS value and log a warning. This is a low-ceremony guard that closes the impersonation path without adding authentication infrastructure. Check: (1) what fields in the settings model control write destinations, (2) whether the settings file is writable by the current user without elevation, and (3) whether there is any OS-sourced assertion that would detect tampering.

**Severity guidance**: Medium for internal dev tools (write target is an internal shared folder). High if the write target is a customer-facing or production data store.

---

## 2026-05-16 — C# Record `ToString()` Leaks All Positional Properties Including Tokens

**Pattern**: C# records auto-generate a `ToString()` that includes all positional parameters by name and value. When a record contains a token, password, or secret field, any log call that passes the record (e.g., `logger.LogDebug("{record}", myRecord)`) or any exception message that calls `.ToString()` will dump the secret verbatim. This is especially dangerous for dispatch/auth records that combine non-sensitive routing data (task ID, machine ID) with sensitive token fields in a single type.

**Heuristic**: During any security review, scan for `record` types that contain fields named `Token`, `Secret`, `Key`, `Password`, `Credential`, or `Auth`. Verify whether `ToString()` is overridden or whether the type has a `[SensitiveData]` attribute. If neither: flag as High and recommend a redacted `ToString()` override and/or a separate credential type.

**Severity guidance**: High when the token is persistent (registration token); Medium when the token is short-lived (per-dispatch token).

---

## 2026-05-16 — Persistent Credentials on Domain Entities Will Serialize to API Responses

**Pattern**: Domain entities (EF Core classes that are also POCOs) are often serialized directly in API responses, especially in CRUD-style admin endpoints. A credential or token field on a domain entity will appear in any response that serializes that entity unless `[JsonIgnore]` or a projection DTO is explicitly applied. The domain layer does not control serialization — so a credential on a domain entity is always one forgotten DTO away from being exposed.

**Heuristic**: Flag any domain entity that carries a field semantically equivalent to a password or API key (named `Token`, `Secret`, `Key`, `RegistrationToken`, `ApiKey`, etc.) as a High finding. The fix pattern is: store a hash only; return the raw value once at creation; never include it in the entity used for listings.

---

## 2026-05-16 — Deserialized Fields That Are Never Read Represent Unnecessary PII Surface

**Pattern**: Model classes that deserialize JSON from a shared or persisted source sometimes contain fields (e.g., `Email`, `PhoneNumber`) that were added speculatively for future use but are never referenced by any service, view, or log. These fields still pass through memory on every deserialization, increase the PII footprint in memory dumps, and create schema coupling to the stored file.

**Heuristic**: During security review, grep for model fields that hold email, phone, SSN, or other PII-adjacent names. Cross-reference against all usages — if the field is never read after deserialization, classify as Low and recommend `[JsonIgnore]` or model removal. Document the finding so future developers don't inadvertently add a feature that reads the unused field without reassessing the privacy implications.

---
