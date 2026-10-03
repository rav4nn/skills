---
name: e2e-sweep
description: Add end-to-end tests to personal projects with tester-army/e2e, verify every flow, and fix the bugs found. One coding subagent per project, one verifier subagent per loop. Use when the user says "/e2e-sweep", "/e2e-sweep <project>", "add e2e tests to my projects", "verify all flows and write tests", or "run tester-army on my projects".
argument-hint: "[project ...]"
---

# e2e-sweep

Install https://github.com/tester-army/e2e in each project. Verify every user flow. Write a test for each flow. Fix each bug found on the way.

Scope: the projects named in `$ARGUMENTS`. If empty, use every git repo in the current folder (one subfolder per repo).

## Models

| Job | Subagent call |
| --- | --- |
| Per-project work: install, flow list, tests, bug fixes | Strongest coding model, `isolation: "worktree"` |
| Verification loop: run the tests, drive the app, report | Default (cheaper) model |

The orchestrator is this session. It never edits project code.

## Steps

1. Read the README of `tester-army/e2e` once. Copy the install and run commands into the brief. Do not guess them.
2. List the projects in scope. For each one, read its README and docs for known flows and decisions.
3. Write one `brief.md` per project in `~/.claude/handoffs/<project>/<date>-e2e/`. It must state:
   - the install and run commands from step 1,
   - the secrets rule: load secrets from the environment or a secrets manager, never print a value,
   - the goal: every flow listed, one test per flow, every bug fixed with a test that fails before the fix,
   - the report: flows covered, bugs fixed, flows not testable and why.
4. Dispatch all coding agents in ONE message, in parallel, one per project. Prompt: "You are a coding agent. Your task is fully specified in `<dir>/brief.md`. Read it and implement everything in it." Use `isolation: "worktree"` and `run_in_background: true`.
   - If a brief has more than 5 flows, cut it into chunks of 3 to 5 flows. Run the chunks in sequence, one fresh agent each.
5. When a coding agent finishes, spawn one verifier for that project. Prompt: run the full e2e suite in the agent's worktree, then drive each flow in the running app with a browser tool such as Playwright. Report each flow as pass or fail with evidence. The verifier reports. It does not fix.
6. If the verifier reports a failure, send the failure list to the coding agent with `SendMessage`. Then run step 5 again. Stop after 3 loops. After 3 failed loops, stop and question the design.
7. When a project passes, diff the base branch against the agent's branch (three dots) and integrate it. Then remove the worktree and the branch.
8. Record each decision worth keeping in the project's docs.

## Report

End with an outcome line and one table: project, flows, tests added, bugs fixed, loops used, status. Then stop. Do not push and do not open a PR. The user decides when to ship.
