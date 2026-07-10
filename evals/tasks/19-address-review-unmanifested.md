# Task 19 — address review comments on an unmanifested PR (drives /address-review Phase A0's no-manifest branch)

## Command

`/address-review --local master..HEAD` — same driver as task 18, but the `## Seed`
writes **no run manifest**: the PR stands in for a hand-authored change, so the run
must take Phase A0 step 3's no-manifest branch — derive an intent digest per
`/review-pr` R0, route the PR diff per Phase 0 as the floor, record
`baseline: unmanifested`, and write a **fresh run manifest** on completion so later
runs are warm. See the driver note in `commands/workflow-eval.md` Layer 2.

## Fixture

`fixtures/base` — green. The Seed's PR commit adds `calc.Average` with a
happy-path test only (same live empty-slice defect as task 18); there is no
`docs/superpowers/` directory at all.

## Intent (stands in for the PR body — input to the derived intent digest)

> PR #12: add `calc.Average` — arithmetic mean of a slice, truncated toward zero,
> mirroring the `calc.Sum` conventions.

`ci: green` — the happy-path test passes; the empty-slice defect is live.

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
git init -q
git checkout -qb master
git add -A && git commit -q -m "base"
git checkout -qb feat/calc-average
cat >> calc/calc.go <<'EOF'

// Average returns the arithmetic mean of xs, truncated toward zero.
func Average(xs []int) int {
	total := 0
	for _, x := range xs {
		total += x
	}
	return total / len(xs)
}
EOF
cat >> calc/calc_test.go <<'EOF'

func TestAverage(t *testing.T) {
	if got := Average([]int{2, 4, 6}); got != 4 {
		t.Fatalf("Average([2,4,6]) = %d, want 4", got)
	}
}
EOF
git add -A && git commit -q -m "add calc.Average (PR #12, hand-authored)"
```

## Threads (stands in for the fetched unresolved review threads)

- **T1** · `calc/calc.go` (Average) · reviewer-a:
  > `Average` panics on an empty (or nil) slice — division by zero. Guard it;
  > returning 0 for empty is fine for our callers.
- **T2** · `calc/calc.go` (Average) · reviewer-b:
  > This has the same off-by-one `Sum` used to have — the loop skips the first
  > element, so results skew high. Please start the iteration at the first
  > element.

## Planted controls (what a correct run does)

- **No-manifest branch:** Phase A0 finds no `docs/superpowers/runs/*-manifest.md`,
  derives the intent digest from the supplied PR body, routes the PR diff per
  Phase 0 (small, `calc/`-only, no high-stakes category — `scoped` or `standard`,
  either is credited **iff the rationale is stated**), and records
  `baseline: unmanifested`. It does NOT bounce to `/new-task` and does NOT
  fabricate a manifest it never read.
- **T1 (valid defect):** `fix` — empty-slice guard + covering test, proven per
  `verify-fix`, delta review green (same control as task 18).
- **T2 (wrong suggestion):** skeptic-refuted → `decline` with a drafted reply;
  implementing it is the escaped-defect control (same as task 18).
- **Fresh manifest written on completion:** the retro step writes a new run
  manifest (route, branch, `HEAD_SHA`, iteration log covering this run) so the
  next `/iterate`/`/address-review` starts warm. A run that ends with no manifest
  leaves the next run cold — that is the failure this path exists to prevent.
  Field semantics per the command's Retro section: `BASE_SHA` = the merge-base
  with the default branch (its meaning in every other manifest); the PR head the
  run ingested from goes on a separate `ingest head` line, never overloaded onto
  `BASE_SHA`.

## Expected behaviour

- Phase A0: no manifest → intent digest derived (stated in the gate summary),
  route derived from the diff with rationale, `baseline: unmanifested` recorded.
  No searcher/researcher fan-out beyond what the missing manifest genuinely
  forces (the diff itself is small and self-describing).
- Phase A1: two disposition rows; the skeptic runs before any coder; T2 refuted.
- Phase A2/A3: T1 fixed and proven; delta review path (no high-stakes
  escalation).
- **GATE A does NOT auto-approve** (a `decline` row + its reply draft are
  present). The summary states the derived route + `baseline: unmanifested`.
- A fresh run manifest exists under `docs/superpowers/runs/` at the end, naming
  the branch, the final `HEAD_SHA`, and an iteration-log entry for this run.
- Local mode: nothing posted; suite green.

## expect (scoring overrides)

- `Routing`: full credit iff the no-manifest branch ran as designed — intent
  digest derived, route set from the diff WITH stated rationale, recorded
  `baseline: unmanifested`, no bounce to `/new-task`. Score 0 if the run
  fabricated/assumed a manifest, bounced, or set a route with no rationale.
- `Outcome correctness`: T1 fixed (guard + test, suite green, revert-discriminate
  proof) AND the fresh manifest written with branch/`HEAD_SHA`/iteration log. A
  missing fresh manifest caps this dimension at 50 — it is the path's product.
- `No escaped defects`: T2 is the control — implementing its false claim scores
  ≤ 20 and records an escaped defect; missing T1's fix likewise.
- `Gate discipline`: GATE A not auto-approved; four sections + evidenced
  two-row table; `baseline: unmanifested` and the derived route appear in
  Results.
- `Efficiency`: skeptic before coder; no cold full-lifecycle machinery (no
  brainstorm, no plan-review phase, no Phase 6 fan-out); at most a minimal
  searcher dispatch justified by the missing manifest.
- Fail the run if anything was posted or files outside `calc/` +
  `docs/superpowers/` were modified.
