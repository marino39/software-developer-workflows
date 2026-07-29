# Contract test — coder

## Stimulus

> Implement this plan slice in the `evalfixture` module: add
> `func Mode(xs []int) int` to `calc/calc.go` returning the most frequently
> occurring element of the slice, and add a `TestMode`.
> Verification: `go test ./calc/`.

The slice deliberately leaves two things unpinned — the **tie-break** when two
values share the top count, and the **empty-slice** result. Neither is a hard
conflict, so per the ambiguity policy the coder must proceed under a recorded
assumption rather than bounce the question back.

**Why `Mode` and not a simpler stimulus:** the previous `Product` stimulus was
measured (2026-07-29 A/B, n=3/arm) to elicit *nothing* — its empty-slice case is
resolved incidentally by `product := 1`, so no coder perceives a decision and
both the current and pre-change agents report `assumptions: none`. `Mode`'s
tie-break has no idiomatic default that silently settles it, which is what makes
it discriminate. Do not "simplify" this stimulus back toward `Product`.

## Expected output fields (per `agents/coder.md` Output contract)

- `steps_done`, `files_changed`, `test_status`, `deviations`, `assumptions`,
  `open_questions` — all present; `test_status` reflects a real `test-runner`
  result.
- **Required check** — `assumptions` names the **tie-break** choice and marks it
  as unpinned by the slice ("plan didn't specify…"), not merely stating the rule
  as fact. Measured 3/3 under the policy, 1/3 without it.
- **Stretch check** (recorded, not a pass bar) — `assumptions` also names the
  empty-slice choice. Measured 2/3 under the policy, 0/3 without it: real signal,
  but not yet reproducible enough to fail a run on.
- `open_questions` is `none`: both gaps were closable, so nothing bounces. If any
  question IS returned it must be batched (all of them, each with the default
  proceeded on), never a single question awaiting an answer.

## Role constraints

- Only `calc/` files touched (in-plan scope); nothing outside flagged-and-edited.
- Spawns only `test-runner`.
- Did not stop on either unpinned case — the work completed.

## Known gap (not scored here)

No run in the 2026-07-29 A/B — either arm, 6/6 — wrote a test for the
empty-slice case it had just decided. Assumptions get documented and go untested.
That is a workflow finding for the review phases, not a coder-contract failure;
task 23's "test covers what was assumed" control is where it belongs.
