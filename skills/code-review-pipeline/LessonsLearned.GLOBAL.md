# Lessons Learned (Global): code-review-pipeline

> Pipeline-process observations applicable to any review session.
> Read before starting. Update only for `Category: Process/Model` pipeline findings.
> Codebase-specific discoveries go in `LessonsLearned.md` (gitignored, local only).

---

### SKILL.md auditor count must be updated atomically when a new REVIEW-* agent is added
Cross-check the Agent Roles table in SKILL.md against the deployed `<agents>` list before starting the parallel phase. If they disagree, fix SKILL.md first. When a new auditor is added, update all of these in one commit: (1) Overview "N-agent system" count, (2) "M specialist auditors" count, (3) Coordinator/FinalSynthesizer row descriptions, (4) LL directory tree, (5) LL rules.

---

### Parallel phase: Orchestrator calls all 8 auditors directly in a single parallel block
There is no Coordinator intermediary. Call all 8 specialist auditors via one parallel `runSubagent` block from the Orchestrator. Calling auditors sequentially one-by-one defeats parallelism and costs unnecessary tokens for each sequential invocation.

---

### Write `parallel-brief.md` before launching the parallel phase
Before the parallel phase, the Orchestrator writes `code-review/parallel-brief.md` — a 400-500 word compressed summary of change intent, key correctness findings, and risk areas from the requirements and correctness audits. Each parallel auditor reads this instead of independently re-processing raw diffs. If this file is missing, each of 8 auditors re-reads the same diff independently, multiplying context costs by 8.

---

### Stale `code-review/` artifacts must be deleted before any new pipeline run
When cherry-picked commits contain `code-review/*.md` files from a prior session, they land in the working tree and corrupt all subsequent stages with stale content.
- Run immediately after cherry-picking: `Remove-Item code-review\*.md -ErrorAction SilentlyContinue`
- When the diff shows `code-review/` files: delete them immediately — do not just note them in the summary and move on
- At no point should `code-review/*.md` exist in the working tree when a new run begins

---

### Auto-start lessons learned after the final review report — do not prompt
Once `final-review.md` is written and presented, start lessons learned in the same turn. Do not print "type 'lessons learned session'" and wait for a trigger phrase.

---

### Complete file replacement: delete then create — do not patch large files in place
When a review artifact from a prior session must be fully replaced, use `Remove-Item` then `create_file`. Piecemeal `replace_string_in_file` on multi-hundred-line files produces partial matches, orphaned sections, and duplicate blocks.

---

### Dead code claims: verify zero usages across the full file before reporting
A symbol removed from one code path may still be referenced by other methods in the same file. An unverified "remove before merge" finding that is actually wrong damages report credibility.

---

### Dead code search on Windows: use `Get-ChildItem | Select-String` — `Select-String -Recurse` is not valid
```
Get-ChildItem <path> -Recurse -Include "*.cs" | Select-String -Pattern <symbol>
```

---

### Compound risk: two Medium findings can combine into HIGH
After listing all findings, second-pass: "If finding X is triggered, does it make finding Y exploitable in a way it otherwise would not be?" If yes, cross-reference both and upgrade the combined severity to HIGH if the exploit path is realistic.

---

### Multiple auditors flagging the same finding: de-duplicate + take the highest severity
When two or more auditors independently flag the same code element from different analytical angles, produce one finding and take the highest severity any auditor cited. Cite all flagging auditors. Convergence from independent auditors is never a false positive — it is a multi-dimensional concern.

---

### Empirical validation data supersedes code-tracing for Critical findings
When the developer provides a same-day validation or characterization test run, analyze its output before writing any Critical finding. Rate Critical only when the data confirms the gap, or when no validation data is available.

---

### Test strategy doc vs. committed tests: search by behavior, not planned method name
Before reporting a test as missing, open the test file and search for the behavior — tests are frequently delivered under a different label but cover the required behavior. A planned method name that doesn't exist is not sufficient evidence of a gap.

---

### Requirements audit without a work item: group by feature area, not by file
Structure the audit around intent-grouped feature areas inferred from the diff: (1) foundational abstractions, (2) refactors, (3) new entry points, (4) downstream behavior changes. This ordering surfaces Critical gaps (new entry points with no call site) that a file-by-file scan would miss.

---

### "Scoped" in a class name does not mean Scoped DI lifetime — check the constructor first
A class named `ScopedXxxFactory` may correctly be Singleton if its constructor captures only `IServiceScopeFactory` (which creates per-call scopes internally). Before flagging as a captive dependency, inspect the constructor. Captive dependency bug = constructor captures a Scoped service. Correct Singleton = constructor captures only `IServiceScopeFactory`.

---

### Comment contradicts code: Medium severity, not cosmetic
When a comment says "we do NOT do X" and the code does X, rate Medium. The risk is the next maintainer who removes X to align with the comment, causing a regression. Recommend a one-line comment fix before merge.

---

### Method-extraction refactors: "field removed, parameter retained" is valid — not a dead parameter
When a private method is extracted to a factory, a constructor parameter may lose its `private readonly _x = x` field assignment. This is not a bug — the parameter had two usages: one feeding the extracted method (now gone) and one inline during construction (still present). Always check the full constructor body for inline usages before writing a "dead parameter" finding.

---

### Structural refactoring: verify toggle evaluation timing when extracting private methods to a factory
When a `Build()` method is extracted, check whether toggle evaluations inside it moved from once-at-construction to N-times-per-request. Almost always equivalent, but worth a "verify toggle immutability" note rather than a defect finding.

---

### Filter-removal: two mandatory companion checks
When a `.Where()` guard is removed: (1) check whether downstream code relied on it as a safety net against `.First()` / `.Single()` throws on empty sequences — trace the full call chain; (2) verify a new test documents the now-inclusive behavior. The previously-excluded case is by definition untested with the old code.

---

### Opt-in inline authorization guard: 3+ auditors converging = one High compound finding
When a service has 3+ write methods each with an identical inline ownership check (no shared helper), expect findings from Maintainability (DRY), Extensibility (no enforcement for future methods), Ripple Effect (unguarded sibling), and Structural Patterns. Synthesize as one High finding — the convergence signals a structural enforcement gap, not just a style issue.

---

### Standing reviews: read architecture docs before source; flag doc-drift in its own section
In standing reviews (no diff): read architecture docs first to extract behavioral contracts, then validate against source. If docs say a feature is "not yet implemented" but code has delivered it, put this in a "Documentation Drift" section — not in the Gaps list. Mixing documentation drift into Gaps inflates the gap count.

---

### Environment lifecycle: trace where a conditional skip flag is CLEARED, not just where it's SET
When auditing a conditional skip ("skip this step if flag X is set"), find where X is cleared. Verify it is cleared before the guarded step re-evaluates in any subsequent outer-loop iteration. A flag set inside a nested sub-flow may still be set when the outer loop reruns, causing incorrect skips on subsequent passes.

---

### Refactoring PRs: verify every new `new ClassName()` call has a resolvable class definition
When a refactor moves instantiation into constructors and introduces new class names, grep the full source tree for each new class name. A class instantiated in a constructor but with no `.cs` implementation file will cause a compile error that `get_errors` may not catch in large solutions.
