---
name: explain-better
description: Explain a topic, code, or model output in a form that is easier to understand than plain prose. Picks one of four formats, from simple to rich - ASD-STE100 writing, a diagram, an HTML page, or an explainer video. Use when the user says "/explain-better", "help me understand", "explain this visually", "make a diagram of", "explain it as a page", or "make an explainer video". Based on Andrej Karpathy's tips for understanding LLM output.
argument-hint: "[format: writing|diagram|html|video] <topic or file>"
disable-model-invocation: true
---

Goal: help the user understand something fast. Oversight and understanding is the bottleneck now, not output. Output is cheap, so make a custom, throwaway artifact.

Input: `$ARGUMENTS`

## Pick the format

If the first word of the input is `writing`, `diagram`, `html`, or `video`, use that format. Otherwise pick the lowest rung that fits. Each rung is richer than the one before.

| Rung | Format | Use when |
| --- | --- | --- |
| 1 | ASD-STE100 writing | The idea is a sequence, a rule, or a definition. |
| 2 | Diagram | The idea has parts and links, a flow, or a hierarchy. |
| 3 | HTML page | The idea needs interaction, many diagrams, or animation. |
| 4 | Explainer video | The idea is a process that changes over time, and the user wants to watch it. |

Do not ask which format. State the pick in one line, then do it. If the user is unsure, offer the next rung up at the end.

## 1. Writing: ASD-STE100

ASD-STE100 is Simplified Technical English. It was made for aerospace maintenance manuals.

- Maximum 20 words per instruction sentence. Maximum 25 for descriptive text.
- One instruction per sentence.
- Active voice. Simple tenses. No `-ing` verb forms except technical nouns.
- One word for one meaning. Never rotate synonyms.
- Plain, short words. Define each technical term at first use.
- Paragraphs: one topic, maximum 6 sentences. Use lists for 3 or more steps.

The full spec is strict. If the result reads stiff, relax to "80% of the way to ASD-STE100": keep the short sentences and the one-word-one-meaning rule, and allow some passive voice and tenses.

## 2. Diagram

Load the `artifact-diagramming` skill first. Draw the real mechanism: the parts, the links, and the direction of data or control. Label every arrow with what travels on it. Use inline SVG or Mermaid. Add at most 3 sentences of text.

## 3. HTML page

Load the `artifact-design` skill, then build one self-contained `.html` file. Put these in it:

- A short summary at the top.
- Diagrams, with hover or click to show detail.
- Small interactive parts where they help (sliders, step buttons, toggles).
- No external build step.

Check the page with a headless browser tool such as Playwright. Open it in the browser with a local file URL.

## 4. Explainer video (3Blue1Brown style)

1. Write a short script first: 5 to 10 scenes, one idea per scene. Show the script to the user only if the topic is large.
2. Build the scenes with Manim (`pip install manim`) or Remotion. Use Manim for math and diagrams. Use Remotion for UI and text.
3. Narration, in this order:
   1. ElevenLabs, if the user has a key. Read it from an environment variable or a secrets manager. Never print the key or write it to a file. If no key is found, go to step 2.
   2. A free local option: macOS `say`, or Piper or Kokoro TTS.
4. Render to `.mp4`, then open it for the user. Name the output path in the reply.

Render a low-quality preview first (`manim -ql`). Render the final file only after the preview works.

## Rules

- Do not ship a diagram, page, or video for a trivial question. Use rung 1.
- Keep the artifact discardable. Write it in the scratchpad or a `explain/` folder, not in a project repo, unless the user names a path.
- End with one line: what was made, where it is, and what the next rung up would add.
