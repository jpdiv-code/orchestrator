# orch — orchestrator + executor skills for Claude Code

Claude (Opus) is the brain: brainstorms, plans, reviews. A cheap executor is the hands — in T3 Code a visible subagent thread with a fallback ladder (`executors:`), elsewhere the hermes script:
writes code in its own git worktree from an IMPL prompt, Claude reviews the diff and ff-merges.
Ordinary fix rounds continue the original executor's thread and checkout where the host permits; the orchestrator
still reviews independently. Use a fresh executor context when the old one is unavailable, unwieldy or stuck.

| skill | does |
|---|---|
| `/orch:plan` | brainstorm → `PLAN-<date>-<TOPIC>.md` (decisions, order, out of scope) |
| `/orch:delegate` | IMPL → executor in a worktree → diff review → ≤2 fix rounds → ff-merge |
| `/orch:entropy` | periodic cleanup pass (logic / code / docs) → map + batches; SessionStart hook nudges |

## Install
```
/plugin marketplace add ~/Documents/Projects/orchestrator
/plugin install orch@orch
```
Then in each project: `cp <repo>/templates/orchestrator.md .claude/orchestrator.md` and set at least `gate`.
Requires `bash`, `git`, `python3` (hook); executor CLI per `executor:` in the config.

## Config
One file, `.claude/orchestrator.md` in the project — see `templates/orchestrator.md`. Swap the executor by changing
`executor:` (a bash line with `$PROMPT`, `$WT`, `$USAGE` set), e.g. `claude -p "$PROMPT"` run inside `$WT`.
