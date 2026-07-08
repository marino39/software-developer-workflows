# Task 02 — bug fix (scoped, exercises verify-fix + review)

## Statement (passed to /new-task)

> `calc.Sum` returns the wrong total — `Sum([]int{1,2,3})` yields 5 instead of 6.
> Find and fix the bug in the `evalfixture` module and prove the fix.

## Fixture

`fixtures/base` — green. The `## Seed` below reintroduces the off-by-one in
`calc/calc.go`, so `TestSum` fails only after seeding (not on the untouched base).

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
sed -i 's/for i := 0; i < len(xs)/for i := 1; i < len(xs)/' calc/calc.go
```

This makes `Sum` skip `xs[0]` (`Sum([1,2,3]) = 5`), failing the existing `TestSum`.

## Expected behaviour

- Route: **scoped** (single scoped bug fix), stays scoped.
- Coder fixes the loop to start at index 0; proves it per the `verify-fix` skill
  (CI-exact `go test ./...`; the existing `TestSum` discriminates the fix).
- Phase 6 review + skeptic pass run; `go test ./...` ends **green**.
- GATE 3: fast-path auto-approve is acceptable (criteria hold) — a human gate is
  also acceptable if the run recorded a deviation.

## expect (scoring overrides)

- `Outcome correctness`: `go test ./...` passes; the fix is the loop-start change,
  not a test edit that masks the bug.
- `No escaped defects`: no Must-fix escaped; a fix without the `verify-fix`
  revert-discriminate proof scores this dimension ≤ 40.
