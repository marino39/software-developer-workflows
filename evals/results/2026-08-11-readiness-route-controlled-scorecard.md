# Scorecard — dispatch-readiness A/B, route-controlled (2026-08-11)

The re-run the 2026-08-10 confounded A/B owed: task 24, baseline vs
`dispatch-readiness-off`, n=2/arm, with two fixes applied first — the variant
Delta rewritten to a terse subtraction, and the **route pinned in both arms** via
the workflow's own triage-manifest floor mechanism (`route floor: standard`,
identical text both sides).

## Route control worked

4/4 runs routed **standard** and reached Phase 4 (vs 2/4 unpinned yesterday).
Both variant runs honored the ablation *and disclosed it* at GATE 2 ("3-column
mapping table, no readiness verdict — variant in force"). This is also the first
live validation that the route-floor mechanism binds — the triage-cold A/B had
left "floor did not bind" as an open gap.

## Result

| Run | Arm | Plan pinned the error contract | GATE 2 readiness verdict | Turns | Ctx hi | Units | rtrip | bounce |
|---|---|---|---|---|---|---|---|---|
| baseline-1 | baseline | **yes** (sentinels named at GATE 1/2) | present — "5 dispatch-ready steps" | 282 | 169k | 14 | 0 | 0 |
| baseline-2 | baseline | **yes** (plan: sentinels + `errors.Is`) | present | 115 | 128k | 10 | 0 | 2 |
| ready-off-1 | variant | **yes** — most detailed of the four (sentinels, `errors.Is`-not-`==`, an inspection checklist for grep-verifiable requirements) | correctly absent, disclosed | 177 | 159k | 19 | 0 | 0 |
| ready-off-2 | variant | **yes** (sentinels + a `Getter` interface in `api`) | correctly absent, disclosed | 128 | 143k | 12 | 0 | 0 |

All four: green across all three packages, `store.ErrNotFound` +
`validate.ErrInvalidID` exported and matched via `errors.Is`, status codes
tested (ready-off-2 also tested 500). **0 escaped defects, 0 cross-slice
mismatches, 0 roundtrips — both arms.**

## Verdict — NULL: the construct never bound

`dispatch-readiness-off: 0 Δ escaped defects, 0 Δ rtrip, 0 Δ contract-pinning
(4/4 plans pinned it, both arms), cost within-arm spread (115–282 turns) exceeds
the between-arm gap → dispatch-readiness DID NOT BIND on this suite; no cost or
quality effect measurable at n=2.`

The mechanism is visible in the artifacts: on a standard route, the
**architect's own plan format already mandates an Interfaces section**
("signatures/types/contracts the coder must honor"), and the Phase 2 fable design
review has already fixed the contract before Phase 4 ever sees the plan. The
readiness column re-checks a guarantee two upstream constructs already deliver.
Every real architect in 4/4 runs produced a plan *thicker* than the hand-written
thin plan the strand probe used — the probe's stranding condition may simply not
be reachable through this workflow's own front half.

Same epistemic shape as the comment-hygiene null: the guarded failure occurred in
**neither** arm, so the layer neither paid nor cost. A null is not a refutation —
but a backstop whose failure mode has now failed to appear through the workflow's
own pipeline is a legitimate simplification candidate.

## Disposition

S3 stays, re-sourced honestly: **zero-marginal-cost backstop against architect
format drift** (a fourth column on an existing pass; it produced no false
unready rows and blocked nothing), with the cut explicitly on the table — it
joins the simplification backlog unless a case appears where an architect-written
plan actually under-pins a cross-slice contract. Its remit was real in the strand
probe; the strand probe's plan was hand-written to be thinner than any observed
architect output.

## Cumulative

**30 runs — 12 contract, 8 lifecycle (tasks 23+24), 6 strand, 4 route-controlled
— zero underspecification roundtrips in any arm of any experiment.** Bounces
occur (4 total) and are always absorbed without re-dispatch.

## Side findings

- **Artifact lifetime:** baseline-1's plan and design doc were destroyed with its
  worktree at finish (workflow artifacts are untracked by design, and this one
  wrote them inside the worktree). The gate summaries and run manifest carried
  the decision evidence, which is what the run-ledger rule exists for — but a
  warm-start `/iterate` on such a run would find no plan file to Read.
- baseline-2's retro self-reports "dispatch-readiness in the plan meant the coder
  needed zero round-trips" — pleasant, but self-report; the variant arm got the
  same zero round-trips without the column.
