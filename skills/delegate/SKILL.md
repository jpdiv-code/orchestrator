---
name: delegate
description: Hand a plan step to the executor (T3 subagent with a fallback ladder: pi → opencode → antigravity → codex; hermes script outside T3) — write the IMPL prompt, run it in its own worktree, wait, review the diff, fix round on defects, ff-merge on success. Use for any code change and for mechanical doc work once the step is decided. Triggers: "delegate", "hand it to the executor", "let hermes do it".
---

# /orch:delegate — a plan step done by the executor

You are the orchestrator: write the task, review, decide accept / redo / escalate. You do not write the code
(exception: a 1–2 line fix after review, or the owner explicitly asked). Read `.claude/orchestrator.md` first:
`code_repo`, `main_branch`, `gate`, `executor`, `ops_dir`, `file_language`, `glossary`, `known_flakes`.
No `gate` → ask the owner once and write it into the config.

## 1. Task file `<ops_dir>/<topic>/IMPL-<step>.md` — in `file_language`
Sections, in this order:
- **One framing sentence**: what the work is and what counts as a defect ("behaviour does not change", "improvements outside the task are defects").
- **Context, in reading order**: PLAN, RECON, concrete files with line counts. The executor does not see our
  conversation — everything it needs is in the referenced files or in the IMPL itself.
- **Steps**: each = one commit, with a done-criterion and the commit message.
- **Don'ts**: what not to touch, no new dependencies, no essay comments.
- **Check**: `gate`; `known_flakes` if any; fix red with your code, never by editing tests.
- **Report**: hashes, a "what moved where" table, ambiguities and how resolved, gate result, deviations — explicitly.

Do not write "copy the block below…" or "repo/branch: main" — the script injects the working dir and branch.
**Prod data.** The IMPL carries only conclusions and aggregates. No raw DB rows, logs, sessions, customer names.
**Product names** stay verbatim from `glossary` if set.

## 2. Run
**In T3 Code** (`mcp__t3-code__delegate_task` is available) — the child shows up in the UI as a subagent thread:
```
delegate_task(task = <PREAMBLE + IMPL contents>, title = "<name>", role = "implementation",
              isolation = "worktree", mode = "async", target = <rung>)
```
`PREAMBLE`: "You work in a fresh git worktree of <repo>. Create branch `hermes/<name>` and commit there; do not switch
branches, push or deploy. End your report with the output of `git rev-parse --show-toplevel` and `git branch --show-current`.
Write the report in <file_language>." Then follow the tool's `next` — do not poll.

**Fallback ladder** — the `executors:` list in the config, top first. Default:

| # | providerInstanceId | model | harness / sub |
|---|---|---|---|
| 1 | `pi` | `opencode-go/deepseek-v4.1-flash` | pi / OpenCode Go |
| 2 | `opencode` | `opencode/deepseek-v4.1-flash-free` | opencode / OpenCode Go |
| 3 | `antigravity` | `gemini-3.8-flash` | antigravity / Google |
| 4 | `codex` | `gpt-6.1-terra` | codex / ChatGPT |

Go one rung down, same IMPL, **only for provider-side failures**: `delegate_task` rejects the target, or the child ends
failed with quota / rate limit / auth / model-unavailable / harness crash and no commits. Bad code is not a fallback
reason — that is a fix round (§3), on the rung that wrote it. Cancel (`task_cancel`) the failed child first. All rungs
down → stop, go to the owner. Say in §4 which rung did the work.

**Outside T3** (no `delegate_task`) — the old path:
```
${CLAUDE_PLUGIN_ROOT}/skills/delegate/hermes-run.sh <name> <ops_dir>/<topic>/IMPL-<step>.md
```
via Bash with `run_in_background: true` — a notification arrives on completion, do not poll.
Worktree `<worktree_dir>/<repo>-h-<name>`, branch `hermes/<name>`.

Different `<name>`s may run in parallel. While waiting, keep talking with the owner.

## 3. Review (after the notification)
1. T3: save the child's final message to `IMPL-<step>.report.md`; take `<worktree>` from its last lines.
   Script: read `IMPL-<step>.report.md`; if empty / rc≠0 — read `.log`.
2. `git -C <worktree> log --oneline <main>..HEAD` and `diff <main>...HEAD` — read the whole diff and check it against
   the task, not the report (executor reports run optimistic).
3. Run `gate` yourself in the worktree.
4. Verdict:
   - **Accepted** → `git -C <code_repo> merge --ff-only hermes/<name>`; if main moved on — `git -C <worktree> rebase <main>`
     (conflict → fix round "rebase and resolve"), then ff again. Then `worktree remove` + `branch -d hermes/<name>`.
   - **Defects** → `IMPL-<step>-fix.md`: only concrete defects (`file:line`, what is wrong, what it should be) plus
     the same check/report; same `<name>`, same rung — in T3 the fix goes to the same worktree: tell the child its path. At most **2 fix rounds** — then stop and go to the owner with an analysis.
   - **Owner's call** (task turned out wrong, a product question surfaced) → stop, go to the owner.
5. Commit IMPL, report and fix files; never commit `.usage.json`/`.log`.

## 4. To the owner — briefly, in `chat_language`
What got merged (hashes), fix rounds and why, which rung ran it, tokens from `.usage.json` (script path), what is still open.
Next IMPL only after the owner's "ok": autonomy within a step, pause between steps.
