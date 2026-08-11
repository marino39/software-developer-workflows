# Scorecard — dispatch-brief lifecycle A/B, Layer 2 (2026-07-29)

First **lifecycle-scope** measurement of the 2026-07-29 dispatch work. Supersedes
the contract-tier scorecard's claim that the lifecycle layer was unrunnable here —
it is runnable: a top-level `claude -p` session (unlike `claude -p --agent`) has
the Agent tool, so the driver really fans out to architect/coder/reviewer and the
traces read a real orchestrator transcript.

- Task: 23 (thin plan step — `calc.Mode`, tie-break and empty-slice unpinned).
- Arms: baseline vs `dispatch-brief-off` (variant Delta prepended verbatim), n=2 each.
- Driver: `evals/lifecycle-ab.sh` — headless `/new-task` per
  `/root/.claude/commands/new-task.md`, auto-approving gates, on an isolated
  git-initialized `fixtures/base` copy. No remote/CI, so Phase 6.5 is skipped.
- Traces: `evals/context-trace.sh` + `evals/dispatch-trace.sh` over each driver
  transcript.

## Result

| Run | Arm | Route | Turns | Ctx hi-water | Units | Disp | iter | **rtrip** | bounce | rt-free | Empty tested |
|---|---|---|---|---|---|---|---|---|---|---|---|
| baseline-1 | baseline | fast path | 75 | 90,257 | 4 | 4 | 0 | **0** | 0 | 100% | 2 |
| baseline-2 | baseline | fast path | 105 | 101,376 | 4 | 4 | 0 | **0** | 0 | 100% | 4 |
| brief-off-1 | variant | fast path | 93 | 106,814 | 6 | 6 | 0 | **0** | 1 | 100% | 4 |
| brief-off-2 | variant | **standard** | 179 | 137,992 | 14 | 18 | 4 | **0** | 2 | 100% | **0** |

All four: `go test ./...` green, `Mode` + `TestMode` shipped, 0 files touched
outside the sandbox, 0 cold context re-entries.

## Headline — still zero roundtrips, now at lifecycle scope

`rtrip 0` in all four runs. The contract-tier finding holds one layer up: the
underspecification roundtrip the whole proposal is built on **did not occur** in
any of these runs, briefed or unbriefed. S1's and S2's cost claims remain
unsupported in-harness across both tiers now.

Bounces did occur (baseline 0/2 runs, variant 2/2 — 3 bounces total), but none
led to the unit being re-dispatched: the orchestrator absorbed the question and
carried on. A bounce that costs no re-dispatch costs far less than the proposal
assumed.

## No verdict on the Dispatch brief — route variance dominates at n=2

`brief-off-2` took the **standard route** (design doc, Phase 2 review loop, 179
turns, 138k context) while the other three took the fast path. That single route
difference explains essentially all of its cost and dispatch count. This is the
same cold-routing bimodality already recorded for `/iterate` and `/address-review`
in the ledger — the same task routes `scoped` or `standard` across runs.

At n=2 per arm, arm and route are not separable:

`dispatch-brief-off: 0 Δ escaped defects, 0 Δ rtrip (0 vs 0), cost delta confounded
by route (variant 93/179 turns vs baseline 75/105) → NO VERDICT at n=2; needs
route-controlled repeats.`

The one non-cost signal worth keeping: `brief-off-2` is the **only run of the four
that shipped the empty-slice case untested** (`empty-tested: 0`, vs 2/4/4). One
run is not evidence, but it is the direction the brief predicts — an unbriefed
dispatch with no `done_when` leaving the degenerate case unverified.

## Instrumentation defect found — and it was mine

The first pass of this A/B reported **4 roundtrips** in `brief-off-2`. All four
were false. Reading the spawn prompts at those turns:

- turns 35/36/37 — the Phase 1 **three-lens brainstorm fan-out**, issued in three
  consecutive turns instead of one message. Three *different* lenses, same repo
  path: by-design parallelism that merely wasn't batched.
- turns 71/73 and 76/78 — Phase 2 **revise → delta re-review**, the review loop
  doing exactly what it exists to do.

`dispatch-trace.sh`'s `redisp` counted "same unit dispatched in a later turn",
which conflates by-design iteration with underspecification roundtrips. The
turn-boundary rule separated *parallel* fan-out from sequential repeats, but every
review loop in the workflow is a sequential repeat — so on any standard-route run
the metric was structurally guaranteed to report roundtrips that were not.

**Fixed:** a re-dispatch now counts as `rtrip` only when the unit's previous
return carried a bounce signature; otherwise it is `iter` (counted, never
charged). The headline column is `rt-free`; `1-shot` is retained as a coarse
secondary. Re-tracing the same four transcripts with the corrected metric moves
`brief-off-2` from "4 roundtrips" to `iter 4, rtrip 0`, and the synthetic
regression fixture still catches a genuine bounce-driven roundtrip.

The lesson generalizes: **re-dispatch alone does not mean underspecified.** A
workflow built out of bounded review loops re-dispatches constantly by design, and
a roundtrip metric that cannot see the difference will indict the loops.

## What this changes

- Contract-tier gap closed from the other side: at lifecycle scope the empty-slice
  assumption **is** tested in 3 of 4 runs (0 of 6 at contract tier). The review and
  verification phases close the "assumption documented but untested" gap that a
  lone coder dispatch leaves open — so that gap belongs to Phase 6, as
  `evals/contracts/coder.md` already notes, and the lifecycle evidence now supports it.
- Both S1 and S2 have now failed to show a roundtrip effect at the tier each was
  supposed to act on. Their remaining justification is disclosure (S1, measured)
  and unverified for S2.

## Owed

- **Route-controlled repeats** before any dispatch-brief verdict: pin the route
  (force `scoped`, or run enough repeats to compare within-route) at n≥3/arm.
- `dispatch-readiness-off` (S3) is untested here by construction — three of four
  runs took the fast path, which skips Phase 4 entirely. It needs a task that
  routes standard.
- No token/cost column: `claude -p` returns no usage trailer. Turns and context
  high-water are the cost proxies used above.
