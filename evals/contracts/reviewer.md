# Contract test — reviewer

## Stimulus

Setup: in the fixture copy, apply the one-line `Sum` fix (loop starts at `0`) and
commit it so a `BASE..HEAD` diff exists. Then:

> Review this diff against the plan: "Fix `calc.Sum` off-by-one so it includes
> `xs[0]`; no other change."

## Expected output fields (per `agents/reviewer.md` Output contract)

- `verdict` — `PASS` or `FAIL`.
- `issues` — numbered issues each with `severity`, `confidence` (0–100 that the
  finding is real), `file:line`, and what's wrong (empty/none is acceptable under
  PASS). A response that reports a `severity` but no `confidence` FAILS the
  contract: consolidation scores confidence, and an unstated one is guessed rather
  than read.

## Finding-bearing stimulus (exercises `severity` + `confidence`)

The stimulus above is a **clean** diff: a conforming reviewer returns PASS with no
issues, so `severity` and `confidence` are never exercised by it and the
per-finding rules below cannot fail. This second stimulus plants defects so they
are.

Setup: seed the off-by-one as above and commit as BASE. Then apply the fix AND
append to `calc/calc.go`:

```go
// Mean computes the mean.
func Mean(xs []int) int {
	// loop over xs and add each element to total
	total := Sum(xs)
	// divide the total by the length to get the mean
	return total / len(xs)
}
```

Commit as HEAD and dispatch with the same plan ("no other change").

Three defects are planted: an out-of-plan public function, an unguarded
division by `len(xs)` (`Sum` supports nil per `TestSumEmpty`), and two
WHAT-restating comments. Expected additionally:

- `verdict` — `FAIL` (the scope violation and the division are blockers).
- Every issue carries a `confidence`, and the values **discriminate** — a uniform
  confidence across findings of visibly different certainty is a contract smell,
  not a pass.
- The comment-hygiene findings are **reported**, not suppressed for being minor.
- `severity` uses only the declared enum (`blocker` | `minor`). A third value
  invented at report time (e.g. `note`) is a contract deviation: consolidation
  buckets on this field.

## Merged-remit stimulus (Phase 6 Channel A shape)

Same setup, but dispatched with the merged four-lens `focus`:

> Review this diff against the plan at `<plan path>`. Focus — carry all four lenses:
> (a) plan compliance, (b) bug scan, (c) git history of the modified code,
> (d) CLAUDE.md compliance for the modified dirs.

Expected additionally:

- `lens_coverage` — one line per lens (a)–(d), each with its findings or `none`.
  A response that omits a lens entirely FAILS the contract: an unreported lens is
  indistinguishable from a clean one at consolidation.
- Length within the ~500-word merged-remit cap.

## Role constraints

- Read-only: reviewer makes no edits to the fixture.
- No pre-filtering on severity: a reviewer that states it withheld findings for
  being minor, stylistic, or uncertain FAILS the contract — filtering belongs to
  the orchestrator's consolidation pass, not the reviewer.
