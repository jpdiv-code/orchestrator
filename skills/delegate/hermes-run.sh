#!/usr/bin/env bash
# hermes-run.sh <name> <IMPL.md> — run the executor on one IMPL in its own worktree. Config: .claude/orchestrator.md.
# Worktree <worktree_dir>/<repo>-h-<name>, branch hermes/<name>; a fix round reuses the same <name>.
# Writes next to the prompt: <IMPL>.report.md (final answer), .usage.json, .log (stderr).
set -euo pipefail
[ $# -eq 2 ] || { echo "usage: $0 <name> <IMPL.md>" >&2; exit 2; }
cfg=${ORCH_CONFIG:-.claude/orchestrator.md}
get() { sed -n "s/^$1: *\([^#]*[^# ]\).*/\1/p" "$cfg" 2>/dev/null | head -1; }
name=$1; impl=$(realpath "$2"); base=${impl%.md}
repo=$(get code_repo); repo=${repo:-.}; repo=$(realpath "${repo/#\~/$HOME}")
main=$(get main_branch); main=${main:-main}
wtdir=$(get worktree_dir); wtdir=${wtdir:-../.wt}; mkdir -p "$wtdir"; wtdir=$(realpath "${wtdir/#\~/$HOME}")
exec_cmd=$(get executor); exec_cmd=${exec_cmd:-'hermes -z "$PROMPT" --in "$WT" --usage-file "$USAGE"'}
fl=$(get file_language)
wt=$wtdir/$(basename "$repo")-h-$name; br=hermes/$name

if [ ! -d "$wt" ]; then
  git -C "$repo" worktree add -q -b "$br" "$wt" "$main"
  # ponytail: shared deps via symlink; a task that changes deps must reinstall in the worktree itself
  IFS=, read -ra links <<<"$(get link_dirs)"
  for p in "${links[@]}"; do p=${p// /}; [ -n "$p" ] && [ -d "$repo/$p" ] && ln -s "$repo/$p" "$wt/$p"; done
fi

export WT=$wt USAGE=$base.usage.json
PROMPT="Working dir: $wt — a git worktree of the $(basename "$repo") repo, branch $br.
All paths are relative to it; do not touch the original $repo.
Commit to $br, do not switch branches, do not push, do not deploy. If the task says \"work in main\", it means this branch.
Write your report as your final message in ${fl:-English} (it is saved to a file automatically).

$(cat "$impl")"
export PROMPT

rc=0
bash -c "$exec_cmd" >"$base.report.md" 2>"$base.log" || rc=$?
echo "rc=$rc report=$base.report.md branch=$br worktree=$wt"
git -C "$wt" log --oneline "$main"..HEAD
exit $rc
