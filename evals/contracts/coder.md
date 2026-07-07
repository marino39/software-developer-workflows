# Contract test — coder

## Stimulus

> Implement this plan slice in the `evalfixture` module: add
> `func Product(xs []int) int` to `calc/calc.go` returning the product of the
> elements (empty slice → 1), and add a `TestProduct` covering `[2,3,4] → 24`.
> Verification: `go test ./calc/`.

## Expected output fields (per `agents/coder.md` Output contract)

- `steps_done`, `files_changed`, `test_status`, `deviations`, `open_questions` —
  all present; `test_status` reflects a real `test-runner` result.

## Role constraints

- Only `calc/` files touched (in-plan scope); nothing outside flagged-and-edited.
- Spawns only `test-runner`.
