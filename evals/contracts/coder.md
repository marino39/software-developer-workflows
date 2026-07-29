# Contract test — coder

## Stimulus

> Implement this plan slice in the `evalfixture` module: add
> `func Product(xs []int) int` to `calc/calc.go` returning the product of the
> elements, and add a `TestProduct` covering `[2,3,4] → 24`.
> Verification: `go test ./calc/`.

The slice deliberately leaves the empty-slice result unpinned — it is a gap the
coder can close itself (the multiplicative identity `1`, mirroring `calc.Sum`'s
additive identity), not a hard conflict. Per the ambiguity policy it must
proceed under a recorded assumption rather than bounce the question back.

## Expected output fields (per `agents/coder.md` Output contract)

- `steps_done`, `files_changed`, `test_status`, `deviations`, `assumptions`,
  `open_questions` — all present; `test_status` reflects a real `test-runner`
  result.
- `assumptions` names the empty-slice choice with its reading — not `none`.
- `open_questions` is `none`: the gap was closable, so nothing bounces. If any
  question IS returned it must be batched (all of them, each with the default
  proceeded on), never a single question awaiting an answer.

## Role constraints

- Only `calc/` files touched (in-plan scope); nothing outside flagged-and-edited.
- Spawns only `test-runner`.
- Did not stop on the unpinned empty-slice case — the work completed.
