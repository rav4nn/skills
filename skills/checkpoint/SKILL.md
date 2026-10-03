---
name: checkpoint
description: Use when the user invokes /checkpoint (write a relay checkpoint of this session's work, often with steering text such as "here, the resume agent should ...") or /checkpoint resume (take over from a checkpoint after /clear, sometimes naming which brief or adding a first task).
---

# Checkpoint: relay through a file and `/clear`

Derive every path yourself. Never ask the user to type one. Each tool call costs a full model
turn on a large context, so use only the calls below.

Briefings live in `$HANDOFFS` (default `~/.claude/handoffs`), one folder per project and day.

## Mode 1: `/checkpoint [steering]` (write)

1. Choose `TOPIC`, a short kebab-case name for the current thread of work. Run ONE Bash call:
   `~/.claude/skills/checkpoint/prep.sh stop <TOPIC>`
   Add a project name as a third argument only when the work lived in one repo but the session
   started in a parent folder (work on `my-app` started from `~/code` → `my-app`).
   The script prints `PROJECT`, `ROOT`, `DIR` (created; this terminal's relay pointer now names it),
   and a `<dev-servers>` block of `pid | ports | cwd | command` lines:
   - `mode="stopped"`: ROOT is a repo. The script stopped these servers (the repo and its worktrees).
   - `mode="list-only"`: ROOT is a plain folder, so the list can hold servers of other terminals.
     Stop only the servers that this session started. Leave the others running.
2. Write `<DIR>/briefing.md` with the Write tool. In list-only mode, send `kill <pids>` in the same
   message. Sections, in this order:
   - `<goal>`: the mission, not one task.
   - `<plan-ref>`: the absolute path of the plan or spec. If none exists, give the plan shape in 2 lines.
   - `<completed>`: one terse line each, with the branch, PR, or file that shows it.
   - `<remaining>`: the ordered work queue: what, why, dependencies. Mark items (new) or (revised).
   - `<blocked>`: what cannot go ahead, and why.
   - `<decisions-log>`: only the decisions that changed the shape of the work, one line each.
   - `<files>`: absolute paths: worktrees and branches, dirty files, open PRs, scratchpad
     artifacts, session gotchas. Put recurring gotchas in auto-memory, not here.
   - `<dev-servers>`: one `port | cwd | command` line per server stopped in step 1. Empty if none.

   Transfer your full context: the successor has none of this conversation. No placeholders, no TBDs.
   **Steering text** after `/checkpoint` (it often starts with `here`) is the user's instruction for
   the briefing and the successor. Obey its exclusions. Put each next move it names at the top of
   `<remaining>`, in the user's words.
   If the plan lives in an issue tracker, first push this session's status changes into its
   tickets, and put the issue URL in `<plan-ref>`.
3. Print exactly this, then stop:

   > Checkpoint written to `<DIR>/briefing.md`. Stopped dev servers: `<ports, or "none">`.
   > When ready: `/clear`, then `/checkpoint resume`.
   > (You can keep working here first — rerun `/checkpoint` later to refresh it.)

A rerun on the same day with the same TOPIC overwrites the same briefing. That is the intended refresh.

## Mode 2: `/checkpoint resume [which brief] [first task]` (take over)

1. Run `~/.claude/skills/checkpoint/prep.sh find [WORD...]`. It prints `POINTER` (the briefing this
   terminal wrote last, or empty) and the newest briefings with their dates. Pass WORDs only when the
   user names a brief ("resume the my-app brief" → `find my-app`). Choose the first that applies:
   1. The path or brief that the user named.
   2. `POINTER`.
   3. The newest briefing under `PROJECT`, when the cwd is inside a git repo.
   4. Otherwise, ask with AskUserQuestion: the 4 newest briefings, newest first, no recommendation.

   If the chosen briefing is more than 2 days old, confirm it with the user before you adopt it.
2. Read the briefing, then the file in `<plan-ref>`. The briefing carries only the delta. What the
   plan marks done is ground truth, `<remaining>` is the work queue, `<blocked>` lists the landmines.
   If `<plan-ref>` is an issue, fetch it and its child issues first. The tracker wins where it
   disagrees with the briefing.
3. For each `<dev-servers>` line: `cd <cwd>`, start `<command>` in the background with its output in
   `<DIR>/logs/<port>.log`, then check `lsof -iTCP:<port> -sTCP:LISTEN`. Report the servers that did
   not come back. Do not block the resume on them.
4. You now own the work end to end (plan, delegate, review, integrate). You are not a subordinate.
   - The args hold a first task: open with one line that names the adopted briefing, then do the task.
   - No first task: restate the goal, where things stand, and the next 1-3 actions you propose.
