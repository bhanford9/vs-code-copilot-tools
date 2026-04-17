# Paper Banana Prompt Template

This file defines the structure of the output file produced by the `paper-banana-infographics` skill.

---

## Output File Structure

Each generated prompt file contains two sections: a **Metadata Block** for record-keeping and a **Prompt Text** ready to paste into Paper Banana.

---

```markdown
# Paper Banana Prompt: {Topic}

## Metadata

| Category        | Value |
|-----------------|-------|
| Topic           | {topic} |
| Audience        | {audience} |
| Intent          | {intent} |
| Visual Style    | {visual_style} |
| Core Concept    | {core_concept} |
| Structure       | {structure} |
| Color/Aesthetic | {color_aesthetic} |
| Source File     | {source_file} |
| Generated       | {date} |

**Key Elements (must appear):**
- {key_element_1}
- {key_element_2}
- {key_element_3}
- ...

**Exclusions (must NOT appear):**
- {exclusion_1}
- {exclusion_2}
- {exclusion_3}
- ...

---

## Paper Banana Prompt

> Copy everything below this line and paste it into Paper Banana.

---

Create an {visual_style} for {audience}.

**Topic:** {topic}

**Goal:** {intent}

**Core concept to convey:** {core_concept}

**Layout:** {structure}

**Must include the following elements:**
- {key_element_1}
- {key_element_2}
- {key_element_3}
- ...

**Do NOT include:** {exclusion_1}, {exclusion_2}, {exclusion_3}.

**Visual style:** {color_aesthetic}. Keep the design clean and easy to read at a glance. Prioritize clarity over density.
```

---

## Notes for Agent

- Replace all `{placeholder}` values with confirmed values from Step 3.
- The **Metadata** section is for reference only — do not paste it into Paper Banana.
- The **Paper Banana Prompt** section should read as a single cohesive instruction, not a checklist. Rewrite the bullet lists into natural prose if the content flows better that way.
- If the user has more than one intended output (e.g., two separate infographics from one source), create a separate output file for each.
