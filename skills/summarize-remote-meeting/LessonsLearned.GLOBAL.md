# LessonsLearned.GLOBAL.md — summarize-remote-meeting

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

### Embedded Standup / Cross-Team Meeting Produces Real Action Items
Category: Process/Model

A recording may contain a full secondary meeting embedded in the middle (e.g., a daily standup that started before the host could stop recording). This segment is `OFF-TOPIC` relative to the primary meeting intent, but it can contain high-priority action items with named owners and concrete deliverables. Do not silently discard it.

- Classify the entire standup block as OFF-TOPIC in the Segment Log
- Extract every action item from it and put them in the "From Filtered Segments" action items table
- The core summary reads as if the standup never happened, but the action items are fully visible to the reader

---

### Team Tooling / Meta-Workflow Segments Are TANGENTIAL, Not OFF-TOPIC
Category: Process/Model

When a speaker describes a new workflow being applied *to the same team* (e.g., "I'm now using AI to document our conversations"), the segment is related to the participants and project even though it does not serve the meeting's stated technical intent. Classify it as TANGENTIAL, not OFF-TOPIC. Include a brief note in Side Notes if the workflow is useful context for a reader. OFF-TOPIC is reserved for fully unrelated content.

---

### Onboarding Transcripts Contain Teaching Simplifications, Not Documentation-Grade Facts
Category: Process/Model

When summarizing an onboarding/teaching meeting, the speaker is deliberately simplifying. Numbers, counts, and "always X" claims are often rounded or approximated for clarity. The summary is accurate to what was *said*, but downstream users of the summary (e.g., knowledge doc writers) may treat those simplifications as authoritative.

- When the meeting intent is explicitly "onboarding" or "teaching", add a **Side Note** warning that specific numbers and simplified rules in this summary are teaching approximations and should be verified before being promoted to reference documentation.
- DO NOT flag every sentence — only specific numbers (`~70`, `exactly 3`) and categorical claims (`always`, `never`, `only`) that were stated casually in a teaching context.
