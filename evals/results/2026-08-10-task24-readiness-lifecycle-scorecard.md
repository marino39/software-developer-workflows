# Scorecard — task 24 lifecycle, dispatch-readiness A/B (2026-08-10)

The run that was supposed to test S3 (Phase 4 dispatch-readiness) properly: task
24 on `fixtures/svc`, baseline vs `dispatch-readiness-off`, n=2 each, full
`/new-task` lifecycles via `evals/lifecycle-ab.sh`.

**Verdict: NO VERDICT — the A/B is uninterpretable, and the reason is worth more
than the result would have been.**

## Result

| Run | Arm | **Route** | Phase 4 ran | Turns | Ctx hi-water | Units | Disp | iter | rtrip | bounce |
|---|---|---|---|---|---|---|---|---|---|---|
| baseline-1 | baseline | **scoped** | **no** | 84 | 106,724 | 5 | 6 | 1 | 0 | 0 |
| baseline-2 | baseline | **scoped** | **no** | 118 | 103,170 | 5 | 5 | 0 | 0 | 0 |
| ready-off-1 | variant | standard | yes | 176 | 134,666 | 16 | 18 | 2 | 0 | 0 |
| ready-off-2 | variant | standard | yes | 232 | 191,661 | 16 | 20 | 4 | 0 | 0 |

Outcomes were **correct in all four**: `go build ./...` clean, all three packages
green, `store.ErrNotFound` + a `validate.Err*` exported and matched by `api` via
`errors.Is`, and all four test the status codes. **Zero escaped defects, zero
cross-slice mismatches, zero roundtrips, both arms.**

## Why there is no verdict — route confounds arm perfectly

Both baseline runs routed **scoped** and took the fast path, which **skips Phase 4
entirely**. So the baseline arm never executed the construct under ablation: this
is not "readiness on vs off", it is "no Phase 4 at all vs Phase 4 without the
readiness column". The cost gap (84/118 vs 176/232 turns) is the fast-path/standard
gap, not the variant's.

**The variant delta probably caused the split.** `dispatch-readiness-off.md`'s
Delta is ~10 lines that discuss Phase 4 at length. Prepending that to the run
plausibly primes it toward a route that *has* a Phase 4 — the two primed runs both
went standard, the two unprimed both went scoped. That is a methodological defect
in how ablations are applied:

> **An ablation delta must not describe machinery whose reachability depends on a
> routing decision the run makes later.** Deltas should be terse subtractions
> ("treat Phase 4 step 1.5 as absent"), not explanations of the phase being
> ablated, or the delta becomes a routing prompt.

## Task 24's central premise is falsified

The task file and the strand-probe scorecard both claimed task 24 would be "the
suite's first reliably **standard**-routing task", which is why it was supposed to
reach Phase 4. Measured: **2 of 4 runs routed scoped**, and both were the unprimed
ones. A three-package change altering three public signatures is routed `scoped`
about half the time.

By task 24's own `expect` block that is a misroute (`scoped` "caps Routing at 40").
But the outcome data complicates that judgment: **the scoped runs were just as
correct**, and got there in ~60% of the turns and a third of the dispatches. Either
the route rule is conservative here, or task 24's expectation is too strict. What
is *not* in doubt is that the task cannot be relied on to exercise Phase 4.

## Useful side-result: the price of the route bimodality, on an identical task

This is the first clean fast-path-vs-standard comparison on the *same* task with
*equally correct* outcomes:

| | scoped (n=2) | standard (n=2) | ratio |
|---|---|---|---|
| Turns | 84, 118 | 176, 232 | ~2.0× |
| Context high-water | 106.7k, 103.2k | 134.7k, 191.7k | ~1.6× |
| Dispatch units | 5, 5 | 16, 16 | ~3.2× |
| Escaped defects | 0 | 0 | — |

That is why route variance has swamped every A/B in this investigation: it moves
cost by 2–3× while leaving outcomes identical. Any future ablation on this suite
must control for route — pin it, or repeat until each route is populated in both
arms and compare within-route.

## Roundtrip count, cumulative

Still zero. **26 runs now — 12 contract, 4 lifecycle (task 23), 6 strand probe, 4
lifecycle (task 24) — across every tier and both fixtures, with no
underspecification roundtrip observed in any arm of any experiment.**

## Instrumentation defect (second one this investigation)

The `status-400-tested` / `status-404-tested` FACTS greps matched string literals
only and reported `0` for three of four runs, which idiomatically use
`http.StatusBadRequest`. Caught before it reached a conclusion; the metric now
matches named constants too. Same lesson as the `redisp` confound: **a metric that
has never been checked against a case it should fire on is not evidence.**

## Owed

- A route-controlled S3 test: either a task the router reliably sends to standard
  (task 24 is not it), or enough repeats to compare within-route.
- A minimal-delta rewrite of `dispatch-readiness-off` before it is run again.
- Task 24's `expect` needs revisiting: `scoped` may be defensible here, and its
  Routing cap encodes an assumption the data does not support.
