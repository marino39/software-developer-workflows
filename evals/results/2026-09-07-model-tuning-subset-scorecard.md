# Scorecard — model-tuning pass, targeted subset (2026-09-07)

Layer 2 for the 2026-09-07 Opus 5 / Fable 5.1 tuning pass
(`docs/proposals/2026-09-07-opus5-fable51-model-tuning.md`, commits `1c25367` +
`d151af6`). **Targeted subset, not the full suite** — two lanes chosen to exercise
what the pass actually changed: one route-pinned standard lifecycle (task 24) and
one fast-path scoped run (the Mode task). n=1 per lane.

Layer 1 lint: **pass, 8/8**. Layer 3 contracts: separate report,
`2026-09-07-contracts.md`.

## Environment caveats — read before using these numbers

- **`codex` is not installed here.** Every out-of-model second-opinion channel
  (Phase 1 design lens, Phase 2 adversarial review, Phase 6 channel B) fell back to
  a Claude architect. Both runs recorded the fallback as a Deviation, which is the
  documented behavior — but **these runs measure the fallback configuration, not
  the shipping one.** The cost numbers are therefore an *upper* bound on Claude
  spend for the standard lane.
- **`gh` is absent**; Phase 6.5 was skipped by instruction in both runs.
- **M2 (the effort change) is not measured by this layer at all** — effort is inert
  in the harness. It remains owed to a real CLI run.
- The task-24 driver **referenced** its gate summaries in the final return
  ("see the full text posted above") rather than reproducing them verbatim as the
  preamble asked. Gate discipline is therefore scored on partial evidence and
  flagged below; this is a collection gap, not proof of a malformed gate.

## Result

| Run | Route | Turns | Ctx hi | Ctx first | Cold | Units | rtrip | bounce | rt-free | Green | Escaped |
|---|---|---|---|---|---|---|---|---|---|---|---|
| task 24 (standard, floor-pinned) | standard | 99 | 126,847 | 43,158 | 0 | 14 | 0 | 0 | 100% | ✓ 3/3 pkgs | 0 |
| Mode (scoped, fast path) | scoped | 60 | 89,531 | 42,999 | 0 | 3 | 0 | 0 | 100% | ✓ | 0 |

Task 24 agent split: architect 8 units / 9 dispatches (1 by-design plan-revision
iteration), coder 5, reviewer 1. Both runs: 0 cold context re-entries, 0 dangling
manifest paths, 0 stray worktree artifacts, 0 workflow-repo contamination.

## Task 24 — every planted control passed

The task exists to catch a **cross-slice contract mismatch**. It did not occur:

- `plan-pins-contract`: **yes** — the merged design+plan artifact names the shared
  error identity before any coder was dispatched. This is the P2 merged-artifact
  path working.
- `store` exports `ErrNotFound`; `validate` exports `ErrInvalidID`.
- `api` matches on **both, via `errors.Is`** — on the identities the other two
  packages actually define. No private duplicate error vocabulary inside `api`,
  which is the specific defect this task scores ≤25 for.
- `lookup-sig`: `func Lookup(s *store.Store, id string) (string, int)`.
- `statuses-tested`: `StatusOK`, `StatusBadRequest`, `StatusNotFound`,
  `StatusInternalServerError` — all four.
- **`rtrip 0` with the contract pinned at plan review is the best outcome the task
  defines**, and the one S3 predicts.

The run also reported that Phase 2's adversarial review caught two real plan
defects before implementation (a wrong verify command, an unscoped step), and that
GATE 4's learnings write was blocked by the harness sandbox — recorded honestly as
a deviation rather than silently dropped.

## Cost vs. baseline

Per-task against directly comparable prior runs. A suite-score diff is **not**
reported: a 2-task subset is not comparable to a 24-task baseline mean.

**Task 24** vs `2026-08-11-readiness-route-controlled` (same task, same
`ROUTE_FLOOR=standard`, baseline arm):

| Run | Turns | Ctx hi | Units | rtrip | bounce |
|---|---|---|---|---|---|
| baseline-1 (2026-08-11) | 282 | 169k | 14 | 0 | 0 |
| baseline-2 (2026-08-11) | 115 | 128k | 10 | 0 | 2 |
| **tuned (2026-09-07)** | **99** | **126.8k** | 14 | 0 | **0** |

**Mode task** vs `2026-07-29-dispatch-brief-lifecycle-ab` (same task, fast path,
baseline arm):

| Run | Turns | Ctx hi | Units | rtrip | Empty tested |
|---|---|---|---|---|---|
| baseline-1 (2026-07-29) | 75 | 90,257 | 4 | 0 | 2 |
| baseline-2 (2026-07-29) | 105 | 101,376 | 4 | 0 | 4 |
| **tuned (2026-09-07)** | **60** | **89,531** | **3** | 0 | 2 |

Both tuned runs land at or below the lowest baseline run on turns and context
high-water, with quality equal (0 escaped defects everywhere).

**This is not evidence the tuning caused the saving.** Baseline within-arm spread
is 115–282 turns on task 24 and 75–105 on Mode — wider than the gap to the tuned
run in both cases. At n=1 per lane the honest reading is: **no regression on any
measured dimension, and a cost signal pointing the right way that a repeat would
have to confirm.** The `codex`-absent caveat cuts the same way — the standard lane
bought its second opinion from a Claude architect, which inflates its own cost
number relative to a real run.

## Scores

| Dimension | Task 24 | Mode |
|---|---|---|
| Routing (25) | 100 | 100 |
| Outcome correctness (25) | 100 | 100 |
| No escaped defects (20) | 100 | 100 |
| Gate discipline (15) | 70 (partial evidence — see caveats) | 95 |
| Efficiency (15) | 100 | 90 |
| **Task score** | **95.5** | **97.8** |

## Regressions

**None.** No dimension dropped >10 points against any comparable prior run, and
**zero escaped defects** in both lanes.

## Open finding — untyped implementation dispatch (fast-path lane)

On the Mode run the implementation was dispatched with **no `subagent_type`**: the
prompt read "Implement Mode function and test" and went out as a generic agent
rather than as `coder`. `dispatch-trace.sh` surfaced it as the `unspecified` row.

The work completed correctly, but that dispatch never received `agents/coder.md` —
so no comment policy, no `<ambiguity-policy>`, no `verify-fix` obligation, no
capped report format. **The agent contract was silently bypassed.** An untyped
dispatch is indistinguishable from a typed one in the result, and only the trace
shows it.

**Attribution is unresolved.** The delegation cap added in this pass governs
*whether* to dispatch, not how to type it, and no baseline transcript survives to
compare typing against — the 2026-07-29 scorecard's prose ("lone coder dispatch")
suggests baseline typed it, but that is prose, not a trace. Recorded as an open
finding at n=1, not as a regression caused by this pass.

Worth fixing regardless of cause: the spawn instructions never state that a
dispatch must name its `subagent_type`, and nothing downstream enforces it.

## What this run does and does not settle

Settles: the pass introduces **no regression** on routing, outcome, escaped
defects, or roundtrips in either lane; the P2 merged design+plan artifact pins a
cross-slice contract correctly; the codex-absent fallback path degrades cleanly and
reports itself.

Does not settle: whether the delegation cap or the reviewer change *caused* the
cost movement (n=1, inside baseline variance); anything about M2's effort change
(inert in-harness); anything about the real codex-backed configuration; and the
two standing backlog items, `verify-scaffold-trim` and the delegation-floor re-A/B.
