---
name: entropy
description: Entropy pass after a series of features — logic (business logic, coupling), code (abstractions, types, cohesion), docs (stale, duplicated). Inventory by contour → summary → batches → /orch:delegate. Run when the owner says "time to clean" / "entropy" or after the session-start nudge.
---

# /orch:entropy [logic|code|docs]

Why: features ship faster than the shape holds. Without a regular pass: duplicates ("two ways to do X"), knobs
without a source of truth, dead code, stale docs — every next feature costs more.
The pass fixes nothing itself — it produces a map and batches; the owner picks what to do.
Read `.claude/orchestrator.md` first (`code_repo`, `ops_dir`, `core_docs`, `glossary`, `file_language`).
No mode given — ask; default order logic → code → docs (each next one runs on the cleaned previous).

## 1. Brief `<ops_dir>/entropy-<date>-<mode>/BRIEF.md`
Current project goal (confirm with the owner in one sentence), where code and docs are, "read only". Questions by mode:
- **logic** — mechanisms (entry point, what it writes, who sees it), settings and their source of truth, duplicates,
  dead code (prove with grep), "one way diverged into several", the cross-cutting question of the current goal.
- **code** — abstractions with a single implementation and needless layers; repetition that wants a shared function;
  weak types (`any`, strings instead of unions, casts); modules that know too much about each other; giant files.
- **docs** — what contradicts the code, what's stale, what's duplicated across `core_docs`/plans, what's due for the
  archive; sizes. If `file_language` differs from a doc's language: rewrite it *and compress* (drop history git already
  holds, keep decisions and current state); `glossary` names verbatim. Translation is mechanical → `/orch:delegate`,
  one doc per IMPL; spot-check meaning against the original (decisions, numbers, "deferred" marks must survive).
Common: every claim with `file:line`, "not verified" separately, a proposals table P1…Pn
(action, type merge/delete/move/leave, size S/M/L, risk, dependencies), report ≤ ~350 lines.

## 2. Contours
Cut into 6–12 contours by module/feature (W — cross-cutting, C — per feature, D — docs). Code/docs only →
`/orch:delegate` with an IMPL "read only, output `<ops_dir>/entropy-…/<contour>.md`", may run in parallel;
needs prod data → a Sonnet subagent, sequentially (limits).

## 3. Summary `SUMMARY.md` (yourself)
Spot-check key findings by hand (say which). Group: root cause → dangerous → wrong but harmless → cleanup.
Batches with an order. Then brainstorm with the owner (do / don't / "deliberately not done") → `/orch:plan` → `/orch:delegate`.

## 4. Mark
Append a line to `.claude/entropy.log`: `<date> <mode> <repo>@<short hash of main>` — the session-start hook counts commits since.
