# Task 08 — triage a feature request (drives /triage-issue, exercises the light-design path)

## Command

`/triage-issue --local` — this task drives **`/triage-issue`** (local/offline mode) on
a **feature** request, not a bug. There is no `## Seed`: the base is green and the
requested function does not yet exist (that absence is the point). The run classifies,
investigates the convention to mirror, and produces a **light** approach sketch + scope
— without implementing and without paying for the full Phase 1 brainstorm. See the
driver note in `commands/workflow-eval.md` Layer 2.

## Issue (stands in for the fetched GitHub issue — passed as the issue text)

> **Title:** Add `calc.Product`
> **Body:** The `evalfixture` module has `calc.Sum` for adding a slice of ints. Please
> add a matching `calc.Product([]int) int` that returns the product of all elements,
> with an empty slice returning 1 (the multiplicative identity), following the same
> style as `Sum`.

## Fixture

`fixtures/base` — unmodified (green; no `## Seed`). `calc.Sum` exists as the peer
pattern to mirror; `calc.Product` does not exist yet.

## Expected behaviour

- **Classify: feature** — a request for new capability, not a defect report.
- **Route: scoped** — one new pure function mirroring an existing one; tiny surface, no
  high-stakes category (auth/payments/migrations/data-deletion).
- **Investigate the convention:** find `calc.Sum` in `calc/calc.go` as the peer pattern
  (package `calc`, `func(xs []int) int`, accumulate loop, test in `calc/calc_test.go`) —
  the thing the new function should mirror.
- **Light approach sketch:** ONE `architect` proposes the recommended approach (add
  `Product` mirroring `Sum`; empty slice → 1 as the identity; add a `TestProduct`) with
  acceptance criteria (e.g. `Product([]int{2,3,4}) == 24`, `Product(nil) == 1`). It must
  **NOT** run the full Phase 1 three-lens brainstorm fan-out — that design is deferred to
  `/new-task` Phase 1.
- **Scope + handoff:** target `calc/calc.go` (+ `calc/calc_test.go`), ~10 lines; cold
  feature → a scoped `/new-task` invocation, ready to paste.
- **Read-only / no implementation:** no `Product` function is written, no file is edited;
  `--local` writes no manifest, so `git status` stays clean.

## expect (scoring overrides)

- `Routing`: scores **classification + route** — feature + scoped with a stated
  rationale = 100; a wrong class (e.g. "bug") or wrong route = 0.
- `Outcome correctness`: the triage report is well-formed (classification · route ·
  approach sketch · acceptance criteria · scope/handoff) AND the approach explicitly
  mirrors the existing `calc.Sum` convention (found via investigation, incl. the empty →
  1 identity). A triage that writes the `Product` implementation or edits any file scores
  this dimension ≤ 40 (triage must not implement).
- `No escaped defects`: **n/a** (a feature request has no seeded defect to catch) —
  renormalize onto the others.
- `Gate discipline`: **n/a** (local mode has no gates) — renormalize onto the others.
- `Efficiency`: **the feature-specific check** — the design stays **light**: ONE
  `architect` for the approach, NOT the full Phase 1 three-lens brainstorm (that would
  pay for design twice, the exact cost `/triage-issue`'s light path avoids). No
  `debugger`; within the shared fable budget. A run that spawns the full 3-architect
  brainstorm scores this dimension ≤ 40.
- Fail the run if any fixture file was modified (no implementation), the issue was
  misclassified as a bug, or the full brainstorm fan-out was run instead of the light
  sketch.
