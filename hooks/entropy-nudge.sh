#!/usr/bin/env bash
# SessionStart: one line "how much piled up since the last /orch:entropy pass". Silent without config or LOG.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
cfg=.claude/orchestrator.md; log=.claude/entropy.log
[ -f "$cfg" ] && [ -f "$log" ] || exit 0
repo=$(sed -n 's/^code_repo: *//p' "$cfg"); repo=${repo:-.}; repo=${repo/#\~/$HOME}
main=$(sed -n 's/^main_branch: *//p' "$cfg"); main=${main:-main}
parts=()
for mode in logic code docs; do
  line=$(grep " $mode " "$log" | tail -1) || continue
  read -r date _ ref <<<"$line"
  n=$(git -C "$repo" rev-list --count "${ref#*@}..$main" 2>/dev/null) || n='?'
  parts+=("$mode $date (+$n)")
done
[ ${#parts[@]} -gt 0 ] || exit 0
msg="Entropy — last pass: $(IFS=,; echo "${parts[*]}") (commits since, in brackets)."
printf '{"systemMessage": %s}\n' "$(printf '%s' "$msg" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read(), ensure_ascii=False))')"
