---
name: delegate
description: "Hand a plan step to the executor (T3 subagent with a fallback ladder: pi → opencode → antigravity → codex; hermes script outside T3) — write the IMPL prompt, run it in its own worktree, wait, review the diff, fix round on defects, ff-merge on success. Use for any code change and for mechanical doc work once the step is decided. Triggers: \"delegate\", \"hand it to the executor\", \"let hermes do it\"."
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
`PREAMBLE`: "Work in the tool-prepared checkout on its assigned branch; commit there. Do not create another checkout,
switch branches, push or deploy. End your report with the output of `git rev-parse --show-toplevel` and
`git branch --show-current`. Write the report in <file_language>."
Keep the returned `taskId`, `childThreadId`, `link`, and the child's actual checkout/branch for the review and any fix
round. Follow the tool's `next` — do not poll. A new task id alone does not mean a new conversation: retain the thread id.

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
Reusing `<name>` keeps the checkout, not necessarily the executor's conversation. Use its documented session-resume
mechanism when available; otherwise send the fix IMPL as a fresh context. Do not guess resume flags.

Different `<name>`s may run in parallel. While waiting, keep talking with the owner.

## 3. Review (after the notification)

### Computer-use verification

Before launching an app for GUI verification or starting computer-use checks, pause and obtain the owner's
confirmation. General approval of a plan, autonomous execution, tests or parallel work does not authorize computer
use. Skip this extra confirmation only when the owner explicitly included these checks when approving the plan/work,
or explicitly approves the current check later. Record that scope in the PLAN/IMPL; do not ask again for every action
within an approved check.

Prefer a **Luna subagent** for approved computer-use verification, using the environment's supported computer-use
skill/tools. Keep implementation and independent code review separate from that UI pass. If Luna or its computer-use
tools are unavailable, disclose that and agree on an alternative rather than silently doing the pass yourself.
Worker briefs must say whether GUI checks are authorized; otherwise keep workers headless. Code review and headless
gates may continue while confirmation is pending. Report only GUI cases actually driven.

1. T3: save the child's final message to `IMPL-<step>.report.md`; take `<worktree>` from its last lines.
   Script: read `IMPL-<step>.report.md`; if empty / rc≠0 — read `.log`.
2. `git -C <worktree> log --oneline <main>..HEAD` and `diff <main>...HEAD` — read the whole diff and check it against
   the task, not the report (executor reports run optimistic).
3. Run `gate` yourself in the worktree.
   In T3 use the actual branch reported by the child for merge/cleanup below; `hermes/<name>` is the script convention.
4. Verdict:
   - **Accepted** → `git -C <code_repo> merge --ff-only hermes/<name>`; if main moved on — `git -C <worktree> rebase <main>`
     (conflict → fix round "rebase and resolve"), then ff again. Then `worktree remove` + `branch -d hermes/<name>`.
   - **Defects** → `IMPL-<step>-fix.md`: only concrete defects (`file:line`, what is wrong, what it should be) plus
     the same check/report. Resume the original executor as described below, keeping its checkout, branch and rung.
     At most **2 fix rounds** — then stop and go to the owner with an analysis, unless the owner authorized further rounds.
   - **Owner's call** (task turned out wrong, a product question surfaced) → stop, go to the owner.
5. Commit IMPL, report and fix files; never commit `.usage.json`/`.log`.

### Fix rounds: continue the author, review independently

For an ordinary correction, prefer the original executor's conversation: it already read the code and knows why it
made its choices. In T3, after that child's task has finished, use the saved `childThreadId`:
```
t3_thread_send(threadId = <childThreadId>, mode = "auto", message = <fix IMPL + checkout/branch + current base>)
```
A send to a finished child starts another task in that thread; keep its returned `taskId` and `link`, and follow its
`next` if present. Keep the provider/model/options and the same checkout/branch. Do not use `restart`, create another
worktree, or start a competing fix while the original task is still running. Passing the same model and path to a new
`delegate_task` does not preserve the original history.

Higher-priority host instructions and tool capabilities take precedence. If they require a new `delegate_task`, or
thread continuation is unavailable, use a fresh task on the same existing checkout with the fix IMPL and relevant
context. State why history was reset; do not claim it was a resumed session. The same T3 thread also does not guarantee
that a harness preserves its provider session or cache: that depends on the harness and route.

The orchestrator still reviews the actual diff and runs the gate independently after each round. The author fixing its
work must not replace that review with self-approval. A separate fresh reviewer is optional when it adds confidence;
it is not a required extra agent for every correction.

Choose a fresh executor context when the original one is unavailable, its history is lost or unwieldy, it repeatedly
misses the same finding, the task needs a materially different approach, or the owner asks for fresh eyes. Carry over
the current code, concrete findings and required checks, and record the reason. Stay on the same rung: bad code alone
is not a provider failure or permission to change models. This does not bypass the fix-round limit above.

Continuation can avoid repeated discovery and improve prefix-cache reuse, but is not automatically cheaper: a long
history still occupies context, and cached input may still be billed. Report available cached/uncached input and output
usage when comparing cost; do not promise savings from thread reuse alone or inspect secrets to find those metrics.

## 4. To the owner — briefly, in `chat_language`
What got merged (hashes), fix rounds and why, which rung ran it, tokens from `.usage.json` (script path), what is still open.
Next IMPL only after the owner's "ok": autonomy within a step, pause between steps.
