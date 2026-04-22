# Summarize Meeting Transcripts

Two skills for extracting signal from recorded session transcripts — one tuned to the noise profile of remote calls, one tuned to the noise profile of in-person rooms.

## The Problem It Solves

Every recorded session produces a transcript. But a raw transcript is not a summary — it is a chronological dump of everything that was said, including interruptions, tangents, crosstalk, audio gaps, and social filler. Converting that into something a reader can actually use requires knowing what the session was *supposed* to accomplish and separating signal from noise. The challenge is that "noise" looks completely different depending on how the session was captured, which is why these two skills share the same goal but have fundamentally different filtering strategies.

## Two Skills, One Purpose

The split between the skills is not about content, length, or formality. It is about **microphone setup**. That single variable determines the character of the noise — and noise character determines everything about how filtering works.

- **Remote meeting**: Each participant is on their own microphone. The audio is clean, speaker attribution is accurate, and the transcript is well-formed. But the meeting structure is fragile. Anyone can join mid-call, inject a field issue, or redirect the conversation. The noise is *topical* — structurally normal speech that simply isn't relevant to why the meeting was called.

- **In-person workshop**: A single room microphone captures everything at once. The structure is stable — there is a curriculum, a lead instructor, defined phases. But the audio is inherently messy. When students split into groups, multiple conversations happen simultaneously. Soft-spoken participants disappear. Domain terminology gets mangled by auto-transcription. The noise is *acoustic* — the content may be valuable but the capture is degraded.

| Dimension | Remote Meeting | Workshop Recording |
|-----------|---------------|--------------------|
| Capture setup | One microphone per participant | Single room microphone |
| Audio quality | Clean, reliable | Noisy, crosstalk-prone |
| Speaker attribution | Accurate (dedicated mic per person) | Unreliable (best-guess or absent) |
| Dominant noise type | Topical — interruptions, off-topic segments | Acoustic — crosstalk, dropout, transcription errors |
| Structural stability | Fragile — any participant can derail it | Stable — curriculum and instructor arc hold it together |
| Primary filter task | Classify every segment: On-Topic / Tangential / Off-Topic | Classify every segment by quality: A–D grade, then reconstruct gaps |
| Output artifact | `meeting-summaries/{date}-{topic}.md` | `lesson-overviews/{date}-{topic}.md` |
| Unique output section | Filtered Segment Log + action items salvaged from excluded segments | Session Critique with pacing, engagement, and learning growth analysis |

## What Each Skill Produces

**Remote meeting summary** — A narrative account of the on-topic content only, written as if the interruptions never happened. Includes a Topic Breakdown, a two-part Action Items table (sourced from *all* segments — because a field-issue interruption can still produce real deliverables even though it gets excluded from the summary), and a Filtered Segment Log that makes every filtering decision transparent. The reader should be able to reconstruct exactly why each segment was included or excluded.

**Workshop lesson overview** — A structured recap of what was taught and how: session arc, concepts introduced, instructional moves, and a Transcript Quality assessment with a Gap Log documenting every segment the skill could not confidently parse. Followed by a Session Critique — honest, specific feedback on pacing, engagement, learning growth indicators, and instructor effectiveness. The critique is written for the people who ran the session, not the attendees. An optional Participant Dynamics section captures participation distribution and notable exchanges when speaker attribution is reliable enough to support it.

## Entry Points

| Invoke | Skill | When |
|--------|-------|------|
| Mention the skill by name | `summarize-remote-meeting` | Zoom, Teams, Meet, or any remote call where participants were on individual microphones |
| Mention the skill by name | `summarize-workshop-recording` | In-person classroom or hands-on session captured by a room mic; transcript has crosstalk, group noise, or audio dropout |

## Reference Files

| File | Role |
|------|------|
| [`skills/summarize-remote-meeting/SKILL.md`](../../skills/summarize-remote-meeting/SKILL.md) | Full workflow: meeting intent identification, segment classification rules, off-topic pattern catalog, output structure |
| [`skills/summarize-remote-meeting/LessonsLearned.GLOBAL.md`](../../skills/summarize-remote-meeting/LessonsLearned.GLOBAL.md) | Process and model findings from past remote meeting summary sessions |
| [`skills/summarize-workshop-recording/SKILL.md`](../../skills/summarize-workshop-recording/SKILL.md) | Full workflow: quality grading, gap reconstruction, lesson overview structure, session critique format |
| [`skills/summarize-workshop-recording/LessonsLearned.GLOBAL.md`](../../skills/summarize-workshop-recording/LessonsLearned.GLOBAL.md) | Process and model findings from past workshop summary sessions |
