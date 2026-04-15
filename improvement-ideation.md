# Feedback Loop Ideation

Research and brainstorming on improving the improvement cycle in agentic workflows — drawing from practitioner interviews, Birgitta Böckeler's harness engineering framework, Kieran Klaassen's compounding engineering idea, and Anthropic's observations about harnesses going stale.

---

## Framing: Two Problems, Not One

Most discussion of feedback loops conflates two distinct problems:

**Problem 1: Capture** — Did we notice and record something worth knowing?  
**Problem 2: Relevance** — Is what we recorded still true and worth surfacing?

The current LessonsLearned pattern solves Problem 1 reasonably well. The harder problem is Problem 2 — lessons accumulate, models improve, codebases change, and an old entry can become noise or worse, actively wrong guidance. Every idea below is really about one of these two problems, or the tension between them.

---

## Core Ideas

### 1. Categorize Lessons at Write Time

Right now all lessons are treated as equivalent. They're not. A lesson about an enum namespace in a specific project is fundamentally different from a lesson about a workflow failure mode. Split into two categories when writing:

- **Codebase lessons** — facts about the project: type locations, naming quirks, non-mockable classes, team conventions. These are stable and almost never go stale unless the project itself changes.
- **Process/model lessons** — observations about agent behavior, workflow gaps, harness decisions. These can go stale when the model improves.

The split matters because when a new model version arrives, "scan for process/model lessons and evaluate if they still hold" becomes a routine action. Codebase lessons almost never need that scan.

This also solves a writing hesitation: "is this worth writing down?" The answer is yes if it's codebase-specific, and yes if it's a process pattern that happened more than once.

---

### 2. Lessons-to-Hook Escalation Path

Böckeler's framework distinguishes inferential controls (AI reads and reasons) from computational controls (scripts run deterministically). A lesson in a markdown file is purely inferential — the agent has to read it and remember to apply it. A hook is computational — it runs regardless.

The escalation path should be explicit:

```
Observed mistake once → LessonsLearned.md entry
Same mistake recurs → Promote to SKILL.md as a rule
Rule keeps getting ignored → Escalate to a hook
```

The existing `test-no-comments` hook followed exactly this path (even if not consciously). Formalizing it as an explicit escalation ladder gives a framework for deciding when a lesson has earned enforcement rather than just guidance.

A concrete trigger: when writing a new LessonsLearned entry, ask "has this category of mistake appeared before in this file?" If yes, it's a promotion or escalation candidate, not just another entry.

---

### 3. Self-Assessment as a Structured Sensor

Inspired by Nathan Sickler's approach: at the end of any substantive workflow, the agent produces a short structured self-assessment covering:

- What assumptions did I make that needed correction?
- What would make this go smoother next time — a clarification, a constraint, a missing reference?
- Is this observation likely model-specific, or would any model have the same gap?

The third question directly addresses the model-upgrade staleness problem. If the agent itself flags "this lesson exists because the model doesn't do X well," that entry becomes a candidate for review when upgrading models.

This doesn't have to be appended to LessonsLearned automatically — it can be surfaced in the session and the human decides whether it's worth persisting. That keeps the human in the steering role.

---

### 4. Cluster Detection Before Writing

The blog describes Steven Mills' approach: keep a mental log, act when mistakes cluster into a category. The same principle should apply to LessonsLearned.md itself — before writing a new entry, scan existing entries in the file.

The lessons-learned SKILL.md could add: before writing a new entry, check if an entry in the same category already exists. If so, you have two choices:
- Update the existing entry (strengthen it, add a new example)
- Recognize that this category keeps appearing and escalate to a skill rule or hook

This prevents the same lesson from appearing five times in slightly different forms, which is the primary driver of bloat.

---

### 5. Health Audit Pass in Agentic Tools Auditor

The agentic-tools-auditor already reads and evaluates all config files. Add a dedicated LessonsLearned audit pass that checks:

- **Age distribution** — are all entries recent, or are there entries from a year ago that have never been revisited?
- **Category balance** — are entries overwhelmingly codebase-specific (good) or process-specific (may need staleness review)?
- **Escalation candidates** — does the same topic appear in 3+ entries? Flag for promotion.
- **Cross-skill duplicates** — does a lesson appear in multiple skills' LessonsLearned files? It may belong in a shared instruction instead.
- **Dead sensors** — are there SKILL.md rules that were "promoted from LessonsLearned" and have now been violated again? (If so, the rule may need strengthening or hook escalation.)

The output would be a section in `AUDIT-SYNTHESIS.md` specific to the feedback loop health.

---

### 6. A Shared "Cross-Skill" Lessons Layer

Currently every skill owns its own LessonsLearned.md. But some discoveries span skills — a general agent behavior pattern, a failure mode that hits every complex workflow, an insight about when to ask vs. proceed.

Proposal: a `lessons-learned/LessonsLearned.md` (next to the `lessons-learned/SKILL.md`) as a global layer for lessons that aren't skill-specific. The lessons-learned SKILL.md already governs the process; this would add a place to put cross-cutting observations.

Any agent completing a complex multi-skill workflow could check both its own skill's LessonsLearned and this shared file. The audit pass (Idea 5) would be responsible for identifying when skill-specific lessons should be promoted to the shared file.

---

### 7. Session-Fork Capture Pattern

Brian Hanford describes forking a session when something goes off path — working in the fork to improve configurations, then returning to the original session with updated configs. This is high-value but currently unstructured.

A lightweight "fork-and-improve" prompt or skill could formalize the moment of capture:
1. Describe what went wrong and what the root cause appears to be
2. Identify which config file owns the fix (skill, agent, instruction, hook)
3. Apply the fix in that file
4. Write a LessonsLearned entry capturing what the situation was and what was changed
5. Return to the original task with the updated config

The key insight is that the moment of frustration is the best time to capture the context — the agent still has the full failure mode in view. The pattern makes that capture deliberate rather than something remembered (or not) at session end.

---

### 8. Model-Upgrade Review Trigger

Anthropic's article: a workaround built for Sonnet 4.5 (context resets) became dead weight on Opus 4.5. Every process/model lesson implicitly bets on what the current model can't do.

When a new model version is adopted, the right action is a targeted review of process and model lessons — not a full rewrite, and not ignoring them. A prompt or checklist for this moment:

- Read all LessonsLearned.md entries tagged as process/model lessons
- For each: does this behavior still happen with the new model?
- If not, remove or archive the entry
- If still relevant, leave it and optionally note it was verified on the new model

This is a low-frequency action (whenever you upgrade models) but prevents the frustration of following outdated guidance. The category split from Idea 1 makes this scan fast — only process/model lessons need review, not codebase lessons.

---

### 9. Hypothesis-Framed Lessons

Instead of writing "do X next time," frame lessons as testable hypotheses: "If the agent reads [file Y] before this step, then [failure Z] should not occur." This creates a design commitment rather than a vague reminder.

The test for the hypothesis is the next session — did the failure recur? If yes, the hypothesis was wrong or incomplete and needs revision. If no, the lesson is validated.

This maps directly to Klaassen's TDD-by-analogy framing: the lesson is the failing test. The config change is the implementation. The next session is the test run. If it passes, the lesson can be condensed; if it fails, iterate.

The discipline this adds: if you can't frame a lesson as a testable hypothesis, you probably don't understand the failure mode well enough to write a useful lesson yet.

---

## What NOT to Do

Ideas that sound useful but introduce more overhead than value:

- **Automatic lesson capture via Stop hooks** — lessons should be deliberate, not automatic. An agent forced to write a lesson after every session creates ceremony. The current "only write if something notable happened" rule is correct.
- **Full reconciler pipelines** — the David Sweet team approach is valuable at team scale, but for individual developers it adds coordination overhead without proportional benefit.
- **Timestamp-based expiration** — auto-expiring old lessons assumes time is the right proxy for staleness. It isn't. A codebase lesson from two years ago may be exactly as relevant today.
- **Mandatory self-assessment on every response** — this floods context. It belongs at workflow completion, not after every response.

---

## Prioritized Starting Points

If implementing a subset, the highest leverage in order:

1. **Categorize at write time** (Idea 1) — minimal effort, fixes the model-upgrade staleness problem and the bloat problem simultaneously
2. **Cluster detection before writing** (Idea 4) — one line added to the lessons-learned SKILL.md, prevents the most common source of bloat
3. **Escalation path formalization** (Idea 2) — explicit ladder from lesson → rule → hook clarifies when passive guidance is insufficient
4. **Health audit pass in auditor** (Idea 5) — builds on existing infrastructure, surfaces systemic issues invisibly accumulating across skill files
5. **Session-fork capture pattern** (Idea 7) — formalizes the highest-value moment of capture (during the frustration, not after)
