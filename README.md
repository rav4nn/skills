# skills

Personal Claude Code skills by [@rav4nn](https://github.com/rav4nn).

| Skill | What it does |
| --- | --- |
| [explain-better](skills/explain-better/SKILL.md) | Explains a topic as ASD-STE100 writing, a diagram, an HTML page, or an explainer video. Based on Andrej Karpathy's tips for understanding LLM output. |
| [checkpoint](skills/checkpoint/SKILL.md) | Saves a briefing file for the session, stops dev servers, then resumes from it after `/clear`. |
| [e2e-sweep](skills/e2e-sweep/SKILL.md) | Adds [tester-army/e2e](https://github.com/tester-army/e2e) tests to each project with one coding subagent and one verifier per loop. |

## Install

```sh
git clone https://github.com/rav4nn/skills.git
cp -r skills/skills/* ~/.claude/skills/
```

Usage: `/explain-better [writing|diagram|html|video] <topic>`, `/checkpoint [steering]`, `/checkpoint resume`, `/e2e-sweep [project ...]`.
