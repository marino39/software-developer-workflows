# Task 12 — explain LOCATE (drives /explain case 1)

## Command

`/explain Where is calc.Sum defined and where is it tested in the evalfixture module?` —
drives **`/explain`**, exercising **case 1 (Locate)**.

## Fixture

`fixtures/base` — green. `## Seed` only makes it a git repo. `calc.Sum` is defined in
`calc/calc.go`; its tests (`TestSum`, `TestSumEmpty`) are in `calc/calc_test.go`.

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Locate (case 1)**, stated in the header.
- **Output is a ranked location list** — each entry `path:line` + a one-line role, **no
  prose walkthrough** (that would be the Mechanism contract, not Locate).
- Correctly lists `calc/calc.go` (the `Sum` definition) and `calc/calc_test.go`
  (`TestSum`, `TestSumEmpty`), each cited.
- **Read-only:** no files modified.

## expect (scoring overrides)

- `Routing`: resolved to **Locate (case 1)** with the header = 100; a wrong case = 0.
- `Outcome correctness`: the answer is the **ranked location list** contract (each
  `path:line` + role, no mechanism walkthrough), correctly pointing to the `Sum`
  definition in `calc/calc.go` and the tests in `calc/calc_test.go`. A wrong/missing
  location or an uncited claim scores this dimension ≤ 40.
- `No escaped defects`: **n/a** — renormalize.
- `Gate discipline`: **n/a** — renormalize.
- `Efficiency`: searcher-tier only; NO `architect`/opus; synthesis inline.
- Fail the run if any fixture file was modified, the case was misclassified, or the output
  is a prose walkthrough rather than a location list.
