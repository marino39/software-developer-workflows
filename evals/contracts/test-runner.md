# Contract test — test-runner

## Seed

Applied to the fixture copy after copy, before dispatch (same seed as task 02):

```sh
sed -i 's/for i := 0; i < len(xs)/for i := 1; i < len(xs)/' calc/calc.go
```

## Stimulus

> Run `go test ./...` in the `evalfixture` module (fixture copy) and report.

The Seed introduces the `calc` off-by-one, so this run fails — exercising the
failure-digest branch of the contract.

## Expected output fields (per `agents/test-runner.md` Output contract)

- `digest` — names the failing test (`TestSum`), the assertion/error message, a
  `file:line`, and a few relevant log lines. (If a variant fixture were green,
  `pass_line` in `PASS: <command>, N tests` form instead.)

## Role constraints

- No code modified; the command is run as given, not altered or retried.
