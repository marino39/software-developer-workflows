# Workflow eval scorecard — 2026-07-09 (iterate-cold ablation)

**Label:** iterate-cold · **Task:** 04 only · **Repeat:** 1 · **Variant:** iterate-cold
**Baseline compared against:** `2026-07-09-iterate-scorecard.md` (task 04, the warm
`/iterate` path).
**Trigger:** the `/iterate` complexity-ledger row is `candidate` — this A/B is the
earn-its-cost evidence. The variant (`evals/variants/iterate-cold.md`) forces task
04's follow-up through a cold `/new-task` (manifest ignored) so the only difference
vs the warm run is the workflow path, not the task.

## Layer 1 — lint

n/a for a variant run (unchanged instruction files; lint covered by the baseline
scorecard's commit + the pre-commit hook).

## Layer 2 — A/B (identical task, identical output)

Both paths produced the **same deliverable**: `README.md` +1 line
(`calc.Product([]int{2, 3, 4}) // 24`), zero `.go` files changed, `go build/vet/test`
green. So the comparison is purely cost vs quality of getting there.

| Dimension | Warm `/iterate` | Cold `/new-task` (variant) | Read |
|---|---|---|---|
| Subagents dispatched | **3** (plan-lite architect, coder, 1 delta reviewer) | **6** (searcher, plan-lite architect, coder, 2 review-channel reviewers, 1 skeptic) | warm halves the fan-out |
| Phase 0 rediscovery | skipped (manifest-seeded) | ran — **searcher** re-derived layout/API the manifest already held (~6.9k tok) | pure redundancy |
| Review | 1 delta reviewer over the +1 line | reduced-tier fan-out: Channel A + combined C1+C3 + **skeptic** (~13.1k + 15.2k tok) | warm skips the 2nd channel + skeptic |
| Retro | deferred → batched iteration-log entry | full Phase 7 + GATE 4 per tweak | warm defers the per-tweak tax |
| Gates | 2 (GATE I + one inline Phase 7 GATE 4) | 3 (scope, GATE 3, GATE 4) | similar |
| Nested subagent tokens | ~40k (estimated from cold's per-agent proxies) | **~75k** (measured, itemized) | ~1.9× |
| **Escaped defects** | **0** | **0** | — |
| Outcome quality | identical | identical | — |

### The quality guard — the decisive point

The cold run's extra machinery caught **nothing** the warm run missed. Both
surfaced the same fact — the follow-up documents `calc.Product`, which doesn't exist
in `calc.go`. The warm delta carried it directly as a **Should-fix note**. The cold
run raised it as a **Must-fix**, then spent a **skeptic pass** (~15k tokens) to
demote it to Should-fix — arriving at the *identical conclusion* the warm path
reached without the round-trip. So the cold path's ~35k tokens of extra
searcher + second-channel + skeptic machinery bought **zero** additional defect
detection on this task.

## Ablation verdict

`iterate-cold: Δ escaped defects = 0, Δ cost ≈ +100% subagents (3 → 6) and ~+35k
tokens (~1.9× nested) for byte-identical output → the /iterate warm path is
**JUSTIFIED** on this task.`

The warm path cut the subagent count in half and skipped ~45% of the nested
review/impl/rediscovery tokens **with no quality loss** — the removed work
(Phase 0 rediscovery, the second review channel, the skeptic pass, the per-tweak
retro) was pure redundancy against an already-reviewed baseline. This moves the
complexity-ledger row from `candidate` to `keep`.

## Honesty / caveats

- **Single un-repeated run.** One task, one sample each side. The direction (warm
  cheaper, quality equal) is unambiguous, but the *magnitude* (1.9× vs the cold
  agent's own qualitative "4–6×" self-estimate) is soft — the 4–6× includes
  rediscovery/gate overhead the agent estimated rather than measured. The defensible
  measured figures are: subagents 3 vs 6, and the ~35k tokens of specific machinery
  (searcher 6.9k + 2nd review channel 13.1k + skeptic 15.2k) the warm path did not
  run. Raise `--repeat` and add a second, larger iterate task (a real code delta,
  not doc-only) before treating the ratio as precise.
- **Doc-only is the mildest case for the warm path.** A doc-only delta's cold review
  is already cheap (reduced tier). On a larger standard-route baseline the cold run
  would pay the *full* Phase 6 fan-out + brainstorm + plan-review, so the warm
  path's advantage should widen — untested here; a follow-up task should cover it.
- Environment limits (fable out of credits, codex absent, `superpowers:*`
  unregistered) applied equally to both sides, so they cancel in the A/B.
