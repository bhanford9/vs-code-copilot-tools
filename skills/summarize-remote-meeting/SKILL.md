---
name: summarize-remote-meeting
description: Summarize a Zoom or other remote meeting transcript where each participant is on their own microphone. Detects and filters off-topic segments, field-issue interruptions, and social tangents. Produces a clean, structured meeting summary seeded only with the content that was actually relevant to the meeting's purpose. Use when summarizing a remote/virtual meeting transcript, when a Zoom auto-transcription needs cleaning and compression, or when a meeting was interrupted mid-session and the signal needs to be separated from the noise.
---

# Summarize Remote Meeting Transcript

> This skill produces a focused summary from a remote meeting transcript. Remote meetings have a distinct noise profile from in-person workshops: each speaker has clean audio, but the meeting itself is structurally fragile — it can be interrupted, hijacked, or drift off-topic at any moment. The primary job is to identify what the meeting was *supposed* to be about and extract only that signal.

## Quick Checklist

```
Remote Meeting Summary Session:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if it exists)
- [ ] Step 1: Intake — gather transcript and meeting metadata
- [ ] Step 2: Identify meeting intent — what was this meeting supposed to accomplish?
- [ ] Step 3: Classify every segment — On-Topic, Off-Topic, or Tangential
- [ ] Step 4: Document filtered segments — record what was removed and why
- [ ] Step 5: Reconstruct the core meeting from on-topic segments only
- [ ] Step 6: Write the Meeting Summary — structured output
- [ ] Step 7: Capture action items — from both on-topic AND off-topic segments
- [ ] Step 8: Reflect and update LessonsLearned
```

---

## Step 1: Intake

Before reading the transcript, establish what you know about the meeting.

| Field | What to Do If Unknown |
|---|---|
| **Transcript file path or content** | Required — cannot proceed without it |
| **Date of the meeting** | Note as "unknown" — use any date mentioned in the transcript |
| **Stated meeting purpose** | Ask if known; otherwise infer from the transcript in Step 2 |
| **Participants** | Infer from speaker labels in the transcript |
| **Output file location** | Default: `meeting-summaries/{YYYY-MM-DD}-{topic-slug}.md` relative to workspace root |

**Transcript format awareness for remote meetings:**
- Zoom auto-transcription produces per-utterance speaker-labeled lines (e.g., `[Name] HH:MM:SS`)
- Each utterance may be one sentence or a sentence fragment — treat adjacent utterances from the same speaker as a continuous thought
- Timestamps are reliable — use them to estimate time spent on each segment
- Speaker attribution is generally accurate because each participant has a dedicated microphone

If the transcript format is different (Google Meet, Teams, Teams Live Captions, plain text), note this and adapt. Core logic is the same.

---

## Step 2: Identify Meeting Intent

Before classifying any segment, establish the **intended purpose** of this meeting. Look for:

- An explicit agenda or goal stated by the meeting organizer early in the call
- A clear topic that the first several minutes center on before any drift
- A stated "I wanted to cover X today" or equivalent
- Context clues: who invited whom, what project or team is involved

**Write a one-sentence Meeting Intent Statement:**

> "This meeting was intended to: {specific goal, e.g., 'onboard a new developer on the design and analysis architecture of the JEDI V2 system'}."

This statement is your filter. Every segment will be evaluated against it in Step 3. Do not skip this step — it is the anchor for all filtering decisions.

---

## Step 3: Classify Every Segment

Read the full transcript once through, tagging each meaningful segment with one of three classifications:

| Tag | Meaning |
|---|---|
| `[ON-TOPIC]` | Directly serves the meeting intent |
| `[TANGENTIAL]` | Related to the participants or project but not the meeting's goal; low summary value |
| `[OFF-TOPIC]` | Unrelated to the meeting intent — interruptions, side conversations, social chat, unrelated field issues |

### Off-Topic Patterns to Watch For in Remote Meetings

These are the most common ways a remote meeting loses its thread:

| Pattern | Signals | Example |
|---|---|---|
| **Uninvited participant joins** | New speaker label appears mid-meeting; topic shifts abruptly | Someone joins to ask a question unrelated to the meeting agenda |
| **Field issue injection** | Discussion shifts to an active operational problem; urgency language appears | "Hey, do you have a minute? We found something in production..." |
| **Scheduler / logistics tangent** | Discussion becomes entirely about when to meet next, who is available | Time spent coordinating future meetings exceeds 2–3 minutes |
| **Weekend / personal chat** | Non-work social content | "How was your weekend?", "Did you catch the game?" |
| **Cross-team context dump** | A participant explains something from a different team's domain that is not directly relevant | Long explanation of another team's system that doesn't connect back to the meeting topic |
| **Tool setup / access issues** | Meeting pauses while someone troubleshoots a non-topic tool | "Let me share my screen... hold on, something's wrong with my mic" (beyond a brief pause) |

### Boundary Detection

When classifying, identify:

- **Entry point**: Where does the off-topic content begin? (Look for a topic switch, a new voice, a meta-comment like "real quick question")
- **Exit point**: Where does the original thread resume? (Often signaled by the original speaker saying "anyway," "back to," "so where were we," or re-stating the last on-topic point)
- **Re-entry marker**: Note the timestamp and the speaker's words that signal the resume. This is important for reconstruction in Step 5.

**Do not silently discard any segment.** Record every classified segment — its timestamp range, classification, and brief description — in the Segment Log below.

---

## Step 4: Build the Segment Log

Produce a Segment Log as you read. This log is included in the output file for transparency.

```
| Timestamp Range | Classification | Summary | Disposition |
|---|---|---|---|
| {HH:MM – HH:MM} | ON-TOPIC | {brief description} | Included in summary |
| {HH:MM – HH:MM} | OFF-TOPIC | {brief description, e.g., "uninvited participant, field issue discussion"} | Excluded from summary; action items captured separately |
| {HH:MM – HH:MM} | TANGENTIAL | {brief description} | Included/excluded at judgment |
```

**Tangential segments:** Use judgment. If a tangential segment (e.g., an AI tools discussion during an onboarding meeting) reveals something meaningful about the participants or team culture, include a brief mention in the summary under a "Side Notes" section. If it adds no signal, exclude it.

---

## Step 5: Reconstruct the Core Meeting

From the on-topic segments only, rebuild the meeting's thread. Use the Meeting Intent Statement from Step 2 as the headline. Re-sequence content into a logical narrative if the original conversation jumped around. If the meeting was interrupted and resumed, join the segments as if the interruption did not occur — the reader does not need to know the exact mechanics of how the content was delivered, only what was covered.

Note any content gaps: if an on-topic segment references something that came from an earlier segment that has been filtered out (rare, but possible if a tangent produced follow-on on-topic discussion), flag it and use the surrounding context to reconstruct.

---

## Step 6: Write the Meeting Summary

Produce the output file at the configured path. Use this structure:

```markdown
# Meeting Summary: {Title — derived from Meeting Intent}

**Date:** {date or "Unknown"}
**Organizer / Lead:** {name}
**Participants:** {names or count}
**Duration:** {total meeting time, or on-topic time if significantly shorter}
**Meeting Intent:** {one-sentence statement from Step 2}

---

## Key Takeaways

> The most important things to know from this meeting. Written for someone who could not attend.

- {takeaway 1}
- {takeaway 2}
- {takeaway 3}
...

---

## Meeting Summary

{2–4 paragraph narrative of what the meeting actually covered, based only on on-topic segments. Write as a coherent account — not a timestamped log.}

---

## Topic Breakdown

### {Topic 1}
{Explanation of the topic as discussed, with key points, examples, and decisions made. Attribute named participants where relevant.}

### {Topic 2}
...

---

## Action Items

### From the Core Meeting
| Owner | Action | Context |
|---|---|---|
| {name} | {action} | {brief context} |

### From Filtered Segments
{If any off-topic or tangential segments produced real action items, list them here. Do not discard them just because the segment was off-topic.}

| Owner | Action | Context |
|---|---|---|
| {name} | {action} | {brief context} |

---

## Filtered Segment Log

| Timestamp | Classification | Content | Disposition |
|---|---|---|---|
| {HH:MM – HH:MM} | OFF-TOPIC | {description} | Excluded |
| {HH:MM – HH:MM} | TANGENTIAL | {description} | Excluded / Included briefly |

---

## Side Notes

{Optional section — include only if tangential content adds meaningful signal about team dynamics, onboarding state, tooling practices, or context that a reader would benefit from knowing, even though it wasn't the point of the meeting.}
```

**Writing principles:**
- The summary should read as if the interruptions never happened
- Write for a reader who was not on the call — be self-contained
- Do not editorialize about why segments were off-topic unless there is something genuinely noteworthy
- Action items from off-topic segments are real deliverables — do not bury them

---

## Step 7: Action Item Extraction

Action items can appear in **any** segment — on-topic or off-topic. A field issue interruption may produce high-priority action items even though it is excluded from the core summary.

When extracting action items:

- Look for explicit commitments: "I'll do X", "can you Y", "let's make sure Z happens"
- Look for implicit commitments: "that thread is buried, no one will see it" + "we should post to the main channel" → action item
- Capture owner (named person or "TBD"), action (specific task), and context (brief reason/background)
- If an action item came from an off-topic segment, note that in the "From Filtered Segments" table

---

## Step 8: Reflect and Update LessonsLearned

When this workflow is complete, **tell the user**:
> "Session complete. Start a lessons learned session now — type 'lessons learned session'. Don't skip this."

When the user runs lessons learned, read `~/Repos/vs-code-copilot-tools/skills/lessons-learned/SKILL.md` and follow the two-tier feedback loop. Consider:

- Were there segment classification calls that were genuinely ambiguous? Note the pattern.
- Was the meeting intent hard to identify (no clear agenda, several competing topics)? Note what resolved it.
- Did the off-topic content structure differ from anything described in Step 3? Add the new pattern.
- Was action item extraction unusually complex (nested threads, unclear owners)? Note what made it hard.
- Did the output structure feel wrong for this meeting type? Propose a structural change.

Only write entries for things that were hard, slow, surprising, or went wrong. Routine sessions produce no entries.

---

## Output File Conventions

| File | Purpose |
|---|---|
| `meeting-summaries/{YYYY-MM-DD}-{topic-slug}.md` | Main output — Meeting Summary + Action Items + Filtered Segment Log |

If no date is known, use `undated` in the filename. If the topic cannot be inferred, use `unknown-topic`.

The output file is self-contained — it should be readable and useful to someone who has never seen the transcript or attended the meeting.

---

## Skill Boundaries

This skill is for **remote meetings** where participants are on individual microphones (Zoom, Teams, Meet, etc.) and the transcript is speaker-labeled.

- For **in-person workshops or classroom sessions** recorded by a room microphone (crosstalk, audio dropout, group work noise), use the `summarize-workshop-recording` skill instead.
- Key differences: remote meetings have clean audio per speaker but fragile structure; workshop recordings have noisy audio but stable structure.
