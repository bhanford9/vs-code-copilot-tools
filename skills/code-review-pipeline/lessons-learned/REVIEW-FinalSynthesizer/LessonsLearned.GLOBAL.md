# Lessons Learned: REVIEW-FinalSynthesizer

> **Recording rule**: Record only workflow process improvements — synthesis steps, conflict resolution rules, deduplication rules, finding structure rules that apply to any review of any codebase.

---

## When to Append

Only append if the session revealed a missing synthesis step, a conflict resolution rule, or a structural requirement for the final report. Skip if synthesis ran smoothly.

---

### Three-auditor testing gap convergence: consolidate to High with Coverage auditor's recommendations
When three auditors independently surface a testing gap from different angles, consolidate into one High finding. Use the Coverage auditor's specific test recommendations as the action items. Do not produce three separate Medium findings.

---

### Severity discrepancy between specialist and generalist auditor: defer to the specialist
When a specialist auditor rates a finding differently from a generalist, the specialist's rating takes precedence. Document the discrepancy in the synthesis and include the specialist's rationale.

---

### Auditor field-name errors: verify ground truth before writing the recommendation
Before including a code snippet or field reference in the synthesis report, verify the field name against the actual file. Auditor output may contain stale or incorrect identifiers.

---

### Security-critical method extraction: three conditions → one Critical compound finding
When a PR extracts a security-critical method AND the structural, correctness, and coverage auditors all flag related gaps, consolidate into one Critical finding with a three-bullet action list — one per auditor dimension.

---

### `void → bool` return-type promotion: scan ALL call sites across the full source tree
When any method changes its return type, the Ripple Effect auditor must scan every call site — not just the changed file. This is a required scan trigger, not a best-effort check.

---

### Use the user-provided deduplication map as the authoritative consolidation plan
When the user provides a deduplication map before synthesis, use it as the authoritative input. Do not re-derive a consolidation plan from scratch — the provided map takes precedence.

---

### Security + Performance co-flag on the same endpoint: one High finding, Security framing leads
When Security and Performance both flag the same endpoint, produce one High finding framed from the Security angle. Include the Performance concern as a secondary dimension within that finding.

---

### Partition High findings into "blocks merge" vs. "recommended before next slice"
When the final report has seven or more High findings, add a two-column partition to the summary table: findings that block this merge vs. findings that should be addressed before the next delivery slice.

---

### Deduplication: consolidate on the strongest single statement, not the union
When deduplicating two findings about the same element, write one finding using the strongest, most precise statement. Do not write a union of both descriptions — it inflates word count without adding clarity.

---

### Infrastructure-scale test additions: check write/edit/save workflow coverage specifically
When a PR adds dozens or hundreds of tests, spot-check write/edit/save workflow paths specifically. These are the most commonly missed when test additions focus on read or query paths.

---

### Compound findings: one root cause producing N gap surfaces → one High with numbered bullets
When one root cause produces findings across N auditors or N files, write one High finding with a numbered bullet list of affected surfaces. Do not produce N separate findings.

---

### Trust the individual auditor's classification over the orchestrator summary
When there is a discrepancy between an auditor's own severity rating and the orchestrator's summary of that rating, use the auditor's original rating. Orchestrator summaries can introduce transcription errors.

---

### Stale audit file: derive findings from the orchestrator's deduplication map
When an audit file is stale or corrupt, do not re-read it. Derive the affected findings from the orchestrator's deduplication map, which is written from auditor output during the parallel phase.

---

### Severity overlap between RE/TB/EX and Maintainability: consolidate at the highest observed
When Ripple Effect, Testability, and/or Extensibility overlap with Maintainability on the same finding, the cross-project dimension (RE/TB/EX) takes precedence for severity. Consolidate at the highest rating.

---

### Dead-code safety confirmation overrides specialist severity bump
When the Requirements auditor rates a finding 🟠 but Code Correctness confirms the affected code path was dead in production (e.g., gated by a toggle that was always ON), use 🟡 in the final report. A confirmed dead-code argument is a factual safety claim that outweighs a specialist's architectural concern rating. Document both views in the finding body so the team has full context.

---

### Same element introduced in this PR: do not apply the pre-existing downgrade rule
The rule "pre-existing issues rate lower than introduced issues" applies only to issues that existed BEFORE the PR. When an element was introduced in the current PR, do not downgrade its severity on pre-existing grounds.

---

### Three-auditor convergence on the same Medium finding: consolidate, do NOT escalate
Three auditors all rating a finding Medium produces one consolidated Medium finding — not a High. Escalation to High requires at least one auditor to independently rate it High.

---

### Full-project zero-test review: Coverage audit generates more findings — frame as batch resolution
When a review covers a zero-test subsystem, the Coverage auditor will produce 2–4× more findings than typical. Frame the synthesis recommendation as a single "build the project test foundation first" action rather than itemizing each individual gap.

---

### Notification propagation bugs are user-visible correctness bugs, not design issues
When an auditor flags a notification propagation failure, label it "user-visible correctness bug" in the synthesis — not a design smell. This ensures it is prioritized correctly against user-facing impact.

---

### Multi-host DI consolidation: synthesizer must ask whether any other composition root was missed
When a DI consolidation PR is reviewed, the synthesizer must explicitly check: "Did any other composition root (e.g., CLI host, MAUI host, test host) get missed?" Include this check in the synthesis step.

---

### Severity disagreement: check whether it is a pre-existing vs. introduced distinction first
Before treating a severity disagreement as a factual conflict between auditors, verify whether one auditor saw the element as pre-existing and the other saw it as introduced. This explains most disagreements without requiring conflict resolution.

---

### Symmetric-path ripple findings: enumerate ALL asymmetric cases from the Ripple Effect table
When the Ripple Effect auditor produces a table of symmetric paths, the synthesizer must enumerate every asymmetric case explicitly. Do not summarize as "several asymmetric cases" — list them all.

---

### Security stub + private guard method: do not automatically apply the three-condition Critical escalation
The three-condition Critical rule (structural + correctness + coverage all flag the same security method) requires the correctness component to be confirmed. A stub or placeholder does not satisfy the correctness condition.

---

### Three or more independent auditors on the same finding: include it regardless of individual severity
When three or more auditors flag the same element independently, include the finding in the synthesis regardless of the individual severity ratings. Three independent detections override any per-auditor Low rating.

---

### Bool-flag constructor parameter flagged by three auditors: converges to Medium even when each rates it Low
When three auditors independently flag a bool-flag constructor parameter from different angles (readability, testability, extensibility), consolidate at Medium — not Low. Three independent detections elevate a Low.

---

### Two auditors recommend the same method rename with different names: use framework naming convention
When two auditors recommend the same method with different proposed names, the synthesis must resolve the conflict by applying the established framework or codebase naming convention — not by picking either auditor's suggestion arbitrarily.

---

### Pre-existing zero-test gap does not block merge — but say so explicitly
When a Coverage finding covers a pre-existing zero-test gap (not introduced in this PR), the synthesis must explicitly state it does not block this merge. The default assumption is that all Critical/High findings block merge.

---

### Full-project zero-test review: emphasize batch resolution in the synthesis
When the review covers a project with zero existing tests, the synthesis recommendation must frame test additions as a batch action ("build the foundation") rather than individual test-per-method recommendations.

---

### Unreachable infrastructure cluster is ONE Critical finding, not N findings
When an entry point is missing (no composition root calls it), that is the Critical finding. Each secondary command or handler that is unreachable as a consequence is a separate Medium — not additional Criticals.

---

### Structural patterns disambiguation notes belong in the executive summary
When the Structural Patterns auditor produces "Clean" verdicts for multiple pattern categories, include a disambiguation note in the executive summary explaining why the patterns are not applicable to this changeset. Do not leave readers wondering if the auditor skipped those patterns.

---

### Dev-tool + Framework-hook PRs: asymmetric escalation rule
For PRs that mix dev-tool changes and framework API changes: framework API findings escalate by auditor convergence rules; dev-tool findings stay at their per-auditor ratings. Do not apply convergence escalation uniformly across both layers.
