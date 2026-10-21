---
name: plan
description: Brainstorm with the owner and a PLAN file — for a task with no obvious solution, a creative task, analysis or measurement. Decisions → recon → steps → execution via /orch:delegate. Triggers: "let's brainstorm", "I need a plan", "I don't know how to solve this".
---

# /orch:plan — from brainstorm to steps

First read `.claude/orchestrator.md` (see the plugin's `templates/orchestrator.md`): `plans_dir`, `ops_dir`, `archive_dir`,
`chat_language`, `file_language`. No config → defaults, and offer to create it.
Fit the process to the task; skipping an empty section is fine.

## Brainstorm (in `chat_language`)
- First understand what the owner wants to get, then options. At every fork — a recommendation and why, not a survey.
  Questions in a numbered batch, so the owner can answer "1. yes 2. B".
- Record the owner's decisions immediately in the "Decisions" table — meaning, in `file_language`, dated when it matters.
  "Deferred by owner" is a decision too — record it (otherwise we re-discuss it in a week).
- Facts about code/prod — verify, don't recall. If a decision needs code knowledge — that's recon, below.

## File `<plans_dir>/PLAN-<date>-<TOPIC>.md` — in `file_language`
1. Title and a **status line** (what's done / what's waiting) — the first thing the next session reads.
2. **Decisions** — table topic → decision.
3. **Order** — steps; each step = one commit + `gate`; sized so it can go out as one IMPL.
4. **Out of scope** — explicitly, especially what the owner deferred.
5. A row in `<plans_dir>/README.md` if it exists.

## Recon
Needed when the steps can't be written without reading code. Output — `<ops_dir>/<topic>-<date>/RECON.md`: cuts by
`file:line`, who imports what, a proposed schema, "not verified". Code-only → `/orch:delegate` (IMPL "read only, output RECON.md");
with prod data → a Sonnet subagent or yourself. After recon amend the plan; mark stale parts, don't silently delete.

## Then
Each step — `/orch:delegate`. After a step — update the plan's status line.
All done and deployed → `git mv` to `<archive_dir>/`, remove the row from the README.
