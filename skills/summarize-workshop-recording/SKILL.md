---
name: summarize-workshop-recording
description: Read, comprehend, and summarize a recorded in-person workshop or classroom session captured by a room microphone. Handles multi-group noise, classifies low-quality segments, produces a structured lesson overview with key takeaways, and critiques the session on pacing, engagement, and learning growth. Use when summarizing an in-person workshop, lecture, or instructional session recorded as a room; when a transcript has crosstalk or audio dropout quality gaps; or when an instructor wants reflective feedback on a session.
---

# Summarize Workshop Recording

> This skill is for extracting signal from messy, human transcripts — not clean documents. Assume noise, crosstalk, and gaps. The goal is to reconstruct the clearest possible picture of what was taught, how it was received, and how the session could improve.

## Quick Checklist

```
Transcript Summary Session:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if it exists)
- [ ] Step 1: Intake — gather the transcript and session metadata
- [ ] Step 2: Assess quality — classify the transcript's parsability
- [ ] Step 3: Flag low-confidence segments — mark and annotate gaps
- [ ] Step 4: Reconstruct context — infer what was lost using surrounding material
- [ ] Step 5: Comprehend the lesson — map topics, flow, and instructional arc
- [ ] Step 6: Write the Lesson Overview — produce the output markdown file
- [ ] Step 7: Critique the session — pacing, engagement, growth, instructor effectiveness
- [ ] Step 8: Produce participant dynamics notes (if enough signal exists)
- [ ] Step 9: Reflect and update LessonsLearned
```

---

## Step 1: Intake

Before reading the transcript, establish what you know about the session.

Confirm or ask for the following:

| Field | What to Do If Unknown |
|---|---|
| **Transcript file path or content** | Required — cannot proceed without it |
| **Date of the session** | Note as "unknown" — use any date mentioned in the transcript |
| **Topic / lesson title** | Infer from the transcript if not provided |
| **Participants** | Ask for names/roles if not in the transcript; otherwise infer from speaker labels |
| **Session structure** | Assume: 1 lead instructor, 2 co-instructors, 6 students — ask if different |
| **Output file location** | Default: `lesson-overviews/{YYYY-MM-DD}-{topic-slug}.md` relative to workspace root |

**Transcript format awareness:**
- If speaker labels are present (e.g., `[Speaker 1]:` or `John:`), use them throughout
- If timestamps are present, use them to estimate time spent per section
- If no structure is present (raw wall-of-text), treat the whole transcript as unstructured and note this prominently in the output

Do not ask about all fields at once. If metadata is missing but the transcript is present, proceed with what you have. Note all missing metadata at the top of the output file.

---

## Step 2: Assess Transcript Quality

Read the full transcript before producing any output. As you read, perform a quality assessment.

### Classify Overall Quality

Rate the transcript on a four-point scale:

| Grade | Meaning |
|---|---|
| **A — High fidelity** | Most speech is captured accurately; gaps are minor |
| **B — Mostly usable** | Some crosstalk or dropout segments; core lesson is recoverable |
| **C — Significantly degraded** | Frequent quality failures; reconstruction is required for large portions |
| **D — Mostly unusable** | More noise than signal; output should lean heavily on inference with strong caveats |

### Common Transcript Problems in Workshop Settings

This session type has specific failure modes to watch for:

| Problem | Cause | How to Handle |
|---|---|---|
| **Crosstalk / simultaneous speech** | Group splits into 3 pairs — multiple conversations happen at once | Mark affected blocks as LOW or UNUSABLE; note which group was likely active |
| **Soft-spoken participants** | Some students hesitant, close to microphone or away from it | Flag with `[soft-spoken — partial]`; attempt to reconstruct from context |
| **Overlapping instructor corrections** | Two instructors speaking near-simultaneously during guided exercises | Attribute best guess; note ambiguity |
| **Audio dropout or silence** | Connection issues, room acoustics, pauses treated as silence | Mark as `[gap — ~N seconds]` with estimated duration if timestamps exist |
| **Transcription hallucinations** | Auto-transcription produces plausible-but-wrong words for domain terminology | Watch for technical terms that appear mangled (e.g., jargon misread as common words) |

Write a brief **Transcript Quality Summary** (used in the output file and to calibrate confidence throughout):

```
Transcript Quality: {A/B/C/D}
Overall parsability: ~{X}% of content clearly captured
Major problem areas: {brief list — e.g., "minutes 23–31 (group work phase) heavily degraded"}
Domain terminology issues: {any technical terms that appeared garbled}
```

---

## Step 3: Flag Low-Confidence Segments

As you parse the transcript, annotate problematic segments inline. Use these markers:

| Tag | Meaning |
|---|---|
| `[LOW CONFIDENCE]` | Content was partially audible; meaning is inferred with reasonable certainty |
| `[INFERRED]` | Segment was not parseable; content is reconstructed from surrounding context only |
| `[UNUSABLE — crosstalk]` | Multiple simultaneous speakers; no reliable content recoverable |
| `[UNUSABLE — dropout]` | Audio missing or transcription failed entirely |
| `[TERMINOLOGY?]` | Technical term appears to have been misread by auto-transcription; flagged for instructor review |

**Do not silently omit low-quality segments.** Their location and rough duration are part of understanding the session. A gap during a key explanation is a different risk than a gap during a break.

Produce a **Gap Log** — a short list of every flagged segment with:
- Approximate timestamp or position (e.g., "~35% through the transcript")
- Tag type
- What was likely happening based on surrounding context
- Confidence in that inference: High / Medium / Low

---

## Step 4: Reconstruct Context for Gaps

For each `[INFERRED]` or `[LOW CONFIDENCE]` segment, attempt reconstruction using:

1. **What came immediately before** — what topic was active?
2. **What came immediately after** — did the conversation resume mid-thought?
3. **Pattern from earlier in the session** — was this a recurring exercise or explanation?
4. **Session structure knowledge** — group-split phases are predictable; what were the other groups doing?

State every reconstruction explicitly. Use the format:

> **Reconstructed:** Based on the prior exchange about {topic} and the instructor's follow-up question, this segment likely covered {inferred content}. Confidence: Medium.

Never present a reconstruction as fact. If confidence is Low, say so and mark the relevant summary section accordingly.

---

## Step 5: Comprehend the Lesson

Before writing any output, build a full mental model of the session. Map:

### Session Arc

Identify the phases of the session:
- **Opening / framing** — how did the instructor open the session? What goal or agenda was stated?
- **Instruction blocks** — what was directly taught? In what order?
- **Practice / exercises** — what did students do? Solo work, pair work, full-group discussion?
- **Debrief moments** — when did the group reconvene after exercises?
- **Q&A or clarification** — what questions arose? Were they answered well?
- **Closing** — how did the session end? Was there a summary or takeaway statement?

### Concepts Introduced

List every concept, technique, or term that was introduced or reinforced. For each:
- Was it introduced from scratch or built on prior knowledge?
- Was it explained once or returned to multiple times?
- Did students demonstrate understanding (correct answers, good questions, application)?

### Instructional Moves

Note the techniques the instructors used:
- Direct explanation
- Socratic questioning
- Live demonstration
- Guided exercise
- Open discussion
- Think-pair-share or small group work
- Worked examples
- Student presentations

---

## Step 6: Write the Lesson Overview

Produce the output markdown file at the configured path. Use this structure:

```markdown
# Lesson Overview: {Title}

**Date:** {date or "Unknown"}  
**Lead Instructor:** {name or "Unknown"}  
**Co-Instructors:** {names or count}  
**Students:** {count or names}  
**Transcript Quality:** {A/B/C/D} — {one-sentence description}

---

## Key Takeaways

> The most important things to know from this session. Written for someone who could not attend.

- {takeaway 1}
- {takeaway 2}
- {takeaway 3}
...

---

## Session Summary

{2–4 paragraph narrative overview of the session arc — what was taught, how, and how it landed. Do not just list events; explain the flow and intent.}

---

## Topic Breakdown

### {Topic 1}
{Explanation of the topic as taught in the session. Note how it was introduced, what examples or analogies were used, and whether students seemed to grasp it.}

### {Topic 2}
...

---

## Transcript Quality Notes

**Overall quality grade:** {A/B/C/D}  
**Estimated parsability:** ~{X}%  

### Gap Log

| Position | Tag | Likely Content | Confidence |
|---|---|---|---|
| {~timestamp or position} | {tag} | {inferred content} | {High/Medium/Low} |

### Reconstructed Segments

{List each reconstructed segment with the full reconstruction note from Step 4.}

---

## Metadata Notes

{Any missing or ambiguous metadata — unknown participants, unclear date, unidentified speakers, etc.}
```

**Writing principles:**
- Write the Key Takeaways as if for a colleague who missed the session — clear, direct, self-contained
- Write the Session Summary as a narrative, not a bullet list — it should read like a brief but complete account
- The Topic Breakdown should explain concepts the way the instructor did — use their examples, analogies, and framing where you have them
- Do not omit sections because data is sparse — mark sparse sections as "Limited signal — {reason}" rather than leaving them out

---

## Step 7: Critique the Session

Produce a separate **Session Critique** section in the output file (or as a second output file if the overview is already long).

This critique is honest, specific, and constructive. It is written for the instructors, not the students.

### Structure

```markdown
## Session Critique

### What Went Well
{Specific things that worked — clear explanations, good examples, strong engagement moments, effective exercises, instructor responsiveness}

### What Did Not Go Well
{Specific problems — confusion that wasn't resolved, pacing issues, exercises that fell flat, topics that were rushed, lost engagement}

### Pacing Analysis
{Section-by-section review of timing. Was the opening too long? Was a key concept rushed? Did a debrief run out of time? Note both "too fast" and "too slow" issues.}

### Engagement Analysis
{How engaged were the students throughout? When did engagement peak? When did it drop? Were some students consistently silent? Were some consistently engaged? Were there moments of obvious confusion or hesitation?}

### Learning Growth Indicators
{Evidence of student understanding improving during the session. Correct answers, better questions over time, "aha" moments, ability to apply concepts independently. Also note any signs that understanding did not develop as expected.}

### Instructor Effectiveness
{How well did the lead instructor and co-instructors perform? Consider: clarity of explanations, handling of questions, adaptability to student needs, coordination between instructors, use of available time.}

### Recommendations
{Concrete, actionable suggestions for the next session. One recommendation per issue identified above. Be specific — not "explain better" but "the {concept} explanation would benefit from a visual diagram before the verbal explanation."}
```

**Critique principles:**
- Be direct. Vague praise is not useful.
- Every criticism should be paired with a recommendation or at least a suggested direction.
- If the transcript quality prevents a fair assessment of a dimension, say so explicitly rather than guessing.
- Distinguish between structural problems (curriculum design, exercise structure) and execution problems (how the instructor delivered something on the day).

---

## Step 8: Participant Dynamics Notes

If the transcript has sufficient speaker attribution, produce a brief participant dynamics section.

This is optional — skip it if speaker labels are absent or too unreliable.

```markdown
## Participant Dynamics

### Participation Distribution
{Who spoke the most? Who was notably silent? Was participation spread evenly across the group, or dominated by a few?}

### Group Split Observations
{During small-group phases, what did each group appear to work on? Were there differences in engagement or progress between groups?}

### Notable Exchanges
{Moments where a student asked a particularly insightful question, demonstrated a clear breakthrough, appeared stuck, or where group dynamics shifted noticeably.}

### Instructor-Student Dynamics
{How did instructors interact with individual students? Were some students receiving more attention? Did all students get meaningful interaction with at least one instructor?}
```

---

## Step 9: Reflect and Update LessonsLearned

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, read `~/Repos/copilot-configs/skills/lessons-learned/SKILL.md` and follow the two-tier feedback loop. Consider:
- Was any phase of this process harder than expected due to transcript characteristics?
- Were there domain terminology problems that recurred and should be noted for next time?
- Did the output structure feel wrong for this session type? (e.g., a session with no group split needs different framing)
- Did the critique reveal a systematic pattern worth remembering?

Only write entries for things that were hard, slow, surprising, or went wrong. Do not document routine sessions.

---

## Output File Conventions

| File | Purpose |
|---|---|
| `lesson-overviews/{YYYY-MM-DD}-{topic-slug}.md` | Main output — Lesson Overview + Critique + Dynamics |

If no date is known, use `undated` in the filename. If the topic cannot be inferred, use `unknown-topic`.

The output file is self-contained — it should be readable and useful to someone who has never seen the transcript.
