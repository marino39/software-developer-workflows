# Task 13 — explain IMPACT/USAGE (drives /explain case 5)

## Command

`/explain What calls calc.Sum — who depends on it in the evalfixture module?` — drives
**`/explain`**, exercising **case 5 (Impact / usage)**.

## Fixture

`fixtures/base` — green. `## Seed` only makes it a git repo. `calc.Sum` is referenced
only by its tests (`TestSum`, `TestSumEmpty` in `calc/calc_test.go`) — there are **no
production callers**. `auth/auth.go` does not use it.

## Seed

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Impact / usage (case 5)**, stated in the header.
- **Output is a dependents list** — direct callers (`file:line`) → transitive → a
  blast-radius summary.
- Correctly finds the only references are the tests in `calc/calc_test.go`, and reports
  **no production callers** as a not-found fact (not fabricated), with the blast-radius
  read: a change to `Sum` is guarded by `TestSum` but has no production dependents in scope.
- **Read-only:** no files modified.

## expect (scoring overrides)

- `Routing`: resolved to **Impact / usage (case 5)** with the header = 100; a wrong case = 0.
- `Outcome correctness`: the answer is the **dependents-list** contract (direct callers
  cited `file:line` → transitive → blast radius); it correctly identifies the test-only
  references and reports **no production callers** honestly (not invented). Claiming a
  caller that doesn't exist scores this dimension ≤ 30.
- `No escaped defects`: **n/a** — renormalize.
- `Gate discipline`: **n/a** — renormalize.
- `Efficiency`: searcher-tier only; NO `architect`/opus; synthesis inline.
- Fail the run if any fixture file was modified, the case was misclassified, or a
  non-existent caller is asserted.
