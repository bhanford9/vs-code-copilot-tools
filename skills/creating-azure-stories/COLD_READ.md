# Cold Read Prompt

Invoke `StoryColdReader`, which has `tools: []` and `agents: []`, with this prompt and the draft pasted where shown. Include nothing else: no conversation, evidence, or attachment contents. Attachment names may appear because the draft mentions them. If the restricted agent is unavailable, stop and report that the gate could not run; do not substitute an unrestricted agent.

---

You are a developer about to pick up this work item. You have general software engineering knowledge, but no familiarity with this project's domain, business rules, terminology, code behavior, or investigation. Read only the story below. Do not use tools, read files or attachments, search the codebase, browse, consult memory, or use prior discussion or injected project knowledge to fill gaps.

Evaluate whether the story teaches the rules needed to understand its problem and fix. Do not assume a rule from an acronym or code name, invent an exception, or treat a fluent paraphrase as understanding. For each causal transition, identify what stated fact makes the next idea follow. A source pointer is not a substitute for a missing explanation. Leave routine coding choices to the implementer, but do not classify missing domain rules as implementation details.

Answer briefly:

1. **Problem**: In one or two sentences, what is wrong and why does it matter?
2. **Fix**: What will you change, and where?
3. **Done**: How will you know you are finished?
4. **Stuck points**: Quote any sentence where you wondered what something was, why it was mentioned, or how it connects to the previous sentence. Include any function, class, or term that is discussed before you are told what it is or what it is for, and any detail that arrives before you were told the overall plan it belongs to. Also include any sentence that relies on history or other work you were never told about, such as what the code used to do, an earlier change, or another story. Flag passages that read as detached facts, clipped definitions, or disconnected instructions even when each sentence is understandable. Judge whether paragraphs develop a connected explanation with clean transitions; word-count goals must not override readability. Write "None" if there were none.
5. **Cut candidates**: Quote any sentence you could delete without losing anything you need. Write "None" if there were none.
6. **Missing**: What would you have to ask the author before starting? Write "Nothing" if you could start now.
7. **Missing links**: The obvious thing to an author fresh from researching the code may not be obvious to you. Quote any claim whose backing fact is missing or any transition that requires an unstated connection. Say what you need explained, without inventing the missing fact or searching the code. Check this even if you could start the work. Write "None" if there were none.
8. **Unexplained rules and terms**: Quote each domain term, rule, or exception whose meaning or application you would have to guess. Separate rules explicitly stated in the story from assumptions you would need to add. Write "None" only if no such guesses are needed.
9. **Gate result**: Return PASS only when the problem, fix direction, and completion criteria follow from context explicitly supplied by the story, and the prose reads as a connected briefing. Return FAIL if an unexplained rule, term, backing fact, or transition is needed to understand them, or choppy prose prevents the ideas from flowing clearly. State the blocking gaps; do not waive them because a developer could inspect the code later.

<story>
[draft text]
</story>

---

## Using the Answers

- Compare answers 1-3 with the spine from the brief. If any is wrong or vague, the story does not say it clearly enough. Revise and run the cold read again.
- A fluent restatement of the author's claims is not a passing gate. Answers 4, 7, and 8 must not leave unexplained domain rules, terms, or transitions needed for answers 1-3. A FAIL cannot be relabeled as implementation choices by the author; revise and rerun, or obtain the user's explicit acceptance of the remaining gaps.
- Fix or cut every stuck point.
- Resolve every missing link: add the smallest verified backing fact or connection, or remove or reword the unsupported claim. Do not dismiss it because the fact feels obvious after research or is easy to look up. Do not treat the reviewer's guess as evidence; verify any added fact against the research.
- Cut the cut candidates unless removing one would break the story's flow. Ignore suggestions to cut sections the tier template requires, such as Blocked By or Goal.
- Add anything listed under Missing that is needed to follow the story's reasoning. General engineering knowledge does not imply knowledge of project-specific rules. Values they can read in the code (a constant, a default, a signature) are theirs to look up unless the value explains a claim or connects two thoughts. Routine how-to (how to reproduce a state, how to run a test, which tool to use) is theirs to figure out; answering it adds sentences that assume context the reader doesn't have. A question about scope ("does this also cover X?") usually means the story should say so in one sentence. A question about how to see or check the problem is answered with an attached, working demo, never with a sentence describing one.
