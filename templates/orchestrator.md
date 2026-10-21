# Orchestrator config — read by /orch:plan, /orch:delegate, /orch:entropy
# One `key: value` per line. Everything is optional except `gate`; defaults in brackets.

code_repo: .                 # [.] repo the executor writes code in (may be a sibling: ~/Projects/app)
main_branch: main            # [main]
gate: ./scripts/test.sh      # command that must be green before merge (no default — ask the owner if missing)
worktree_dir: ../.wt         # [../.wt] where executor worktrees go; <dir>/<repo>-h-<name>
link_dirs:                   # comma list of paths inside the repo to symlink into each worktree (node_modules)
executor: hermes -z "$PROMPT" --in "$WT" --usage-file "$USAGE"   # run via bash; env PROMPT, WT, USAGE are set

chat_language: Russian       # [owner's language] language of chat with the owner
file_language: English       # [English] language of every file, prompt and subagent brief
glossary:                    # file with canonical product/UI names that must stay verbatim (optional)

plans_dir: plans             # [plans]   PLAN-<date>-<TOPIC>.md
ops_dir: ops                 # [ops]     IMPL / RECON / entropy briefs per topic
archive_dir: archive         # [archive] finished plans and ops
core_docs:                   # comma list of docs /orch:entropy docs treats as the live set
known_flakes:                # notes for the executor, e.g. 'events.test.ts "2 !== 1" — rerun'
