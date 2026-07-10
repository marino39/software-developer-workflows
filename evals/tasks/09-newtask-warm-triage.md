# Task 09 — /new-task warm-started from a triage manifest (exercises the Phase 0 triage seam)

## Command

`/new-task Fix the calc.Sum off-by-one in the evalfixture module — triage-seeded, see the triage manifest at docs/superpowers/triage/2026-07-10-issue-calc-sum.md`

This task drives **`/new-task`**, but references a **triage manifest** the `## Seed`
writes into the fixture. It exercises the Phase 0 **triage warm-start seam** (step 3 +
the route floor in step 5): `/new-task` should load the manifest, seed its investigation
from it, inherit the `scoped` route as a floor, and NOT re-run the Phase 0
`searcher`/`researcher` legwork the manifest already carries. Paired with the
`triage-cold` variant for the warm-vs-cold A/B.

## Fixture

`fixtures/base` — green. The `## Seed` reintroduces the calc off-by-one (same as tasks
02/07) so `TestSum` fails, AND writes a triage manifest describing that bug — the
artifact a prior `/triage-issue` run would have produced.

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
sed -i 's/for i := 0; i < len(xs)/for i := 1; i < len(xs)/' calc/calc.go
mkdir -p docs/superpowers/triage
cat > docs/superpowers/triage/2026-07-10-issue-calc-sum.md <<'EOF'
# Triage manifest — issue: calc.Sum returns the wrong total

- classification: bug
- route (floor): scoped
- searcher digest: the summation lives in `calc/calc.go` (`func Sum(xs []int) int`,
  package `calc`, module `evalfixture`); the accumulate loop is the only logic. Tests
  are in `calc/calc_test.go` — `TestSum` (happy path) and `TestSumEmpty` (nil → 0).
- researcher digest: n/a — pure in-repo arithmetic, no external dependency.
- repro (proven): CI-exact `go test ./...` → `TestSum` fails
  (`Sum([1,2,3]) = 5, want 6`). `TestSum` is the discriminating test; `TestSumEmpty`
  does not discriminate (0 for both loop bounds). No new repro test needed.
- root-cause: `calc/calc.go` — the loop starts at `i := 1`, skipping `xs[0]`; should be
  `i := 0`.
- scope: one-line change in `calc/calc.go`; ~1 LOC; no new files; `TestSum` will flip
  green. Cold bug fix → `/new-task` (scoped).
EOF
```

## Expected behaviour

- **Triage warm-start fires:** Phase 0 loads the manifest, states the run is
  triage-seeded (naming the manifest) at the first touchpoint, and does **not** re-run
  `searcher`/`researcher` to rediscover what the manifest's digests already give (fan-out
  only for genuine gaps — here, none).
- **Route floor inherited:** the route is **scoped** (the manifest's floor), monotonic —
  not re-judged from cold.
- **Fix + proof:** the coder changes the loop start to `i := 0` and proves it per
  `verify-fix` (CI-exact `go test ./...`; `TestSum` discriminates). Suite ends green.
- **GATE 3:** fast-path auto-approve is acceptable (criteria hold); a human gate is also
  acceptable if a deviation was recorded.

## expect (scoring overrides)

- `Routing`: **inherited the scoped floor** from the manifest (not re-derived), stated as
  triage-seeded with rationale = 100; re-routing from cold or ignoring the floor drops it.
- `Outcome correctness`: `go test ./...` passes; the fix is the loop-start change, not a
  test edit masking the bug.
- `No escaped defects`: no Must-fix escaped; a fix without the `verify-fix`
  revert-discriminate proof scores this ≤ 40.
- `Efficiency`: **the headline for the seam** — Phase 0 did NOT re-run the
  `searcher`/`researcher` legwork the manifest supplied (that saving is what the seam
  buys). Re-investigating from scratch despite the manifest is the failure mode the
  `triage-cold` A/B measures.
- `Gate discipline`: gate summary well-formed; the triage-seed + inherited floor are
  surfaced in Results / Key decisions.

## A/B

Baseline (this task, seam on) vs `--variant triage-cold` (manifest ignored, cold Phase 0)
sizes the warm-start saving and confirms the route floor. See `evals/variants/triage-cold.md`.
