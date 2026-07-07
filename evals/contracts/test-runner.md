# Contract test — test-runner

## Stimulus

> Run `go test ./...` in the `evalfixture` module (fixture copy) and report.

The base fixture carries the seeded `calc` bug, so this run fails — exercising the
failure-digest branch of the contract.

## Expected output fields (per `agents/test-runner.md` Output contract)

- `digest` — names the failing test (`TestSum`), the assertion/error message, a
  `file:line`, and a few relevant log lines. (If a variant fixture were green,
  `pass_line` in `PASS: <command>, N tests` form instead.)

## Role constraints

- No code modified; the command is run as given, not altered or retried.
