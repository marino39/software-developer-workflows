# Task 05 — iterate on a reviewed baseline, CODE delta (exercises /iterate delta implement + delta review + verify-feature)

## Statement (passed to /iterate)

> A prior `/new-task` run added `calc.Product` to the `evalfixture` module and
> finished (manifest present, route `standard`). Follow-up: add
> `calc.Max(xs []int) (int, bool)` returning the largest element and `true`, or
> `(0, false)` for an empty slice. Add a test covering a normal slice and the empty
> case.

## Fixture

`fixtures/base` — green. The `## Seed` below stands in for a completed prior
`standard`-route run: it adds a reviewed `calc.Product` (implementation + test) on a
feature branch and writes a run manifest under `docs/superpowers/runs/`, so
`/iterate` has a real code baseline to delta against. Unlike task 04 (doc-only),
this follow-up **changes `.go` files**, so the warm path must run real behavioral
verification and a real (delta) code review.

## Seed

Applied to the fixture copy after copy, before dispatch (on a feature branch off
`master`):

```sh
git checkout -b task/calc-product
cat >> calc/calc.go <<'EOF'

// Product returns the product of all elements in xs (1 for an empty slice).
func Product(xs []int) int {
	p := 1
	for _, x := range xs {
		p *= x
	}
	return p
}
EOF
cat >> calc/calc_test.go <<'EOF'

func TestProduct(t *testing.T) {
	if got := Product([]int{2, 3, 4}); got != 24 {
		t.Fatalf("Product([2,3,4]) = %d, want 24", got)
	}
	if got := Product(nil); got != 1 {
		t.Fatalf("Product(nil) = %d, want 1", got)
	}
}
EOF
git add -A && git commit -qm "add calc.Product (prior reviewed run)"
mkdir -p docs/superpowers/runs docs/superpowers/retros docs/superpowers/specs docs/superpowers/plans
# manifest records the prior run; HEAD_SHA = the Product commit
cat > docs/superpowers/runs/2026-07-08-calc-product-manifest.md <<EOF
# Run manifest — calc.Product
route: standard
outcome: local-kept
default branch: master
branch: task/calc-product
HEAD_SHA: $(git rev-parse HEAD)
design doc: docs/superpowers/specs/2026-07-08-calc-product-design.md
plan: docs/superpowers/plans/2026-07-08-calc-product-plan.md
retro: docs/superpowers/retros/2026-07-08-calc-product.md
behavioral verification: passed (Product drives correctly for normal + empty)
open Should-fix: none

## Iteration log
- 2026-07-08 initial /new-task (standard): added calc.Product with test; GATE 3 human-approved.
EOF
git add -A && git commit -qm "record run manifest"
```

## Expected behaviour

- Phase I0: reads the manifest, treats the request as a **code delta on the
  reviewed baseline** (does NOT bounce to `/new-task`). Inherits route `standard`
  (the manifest floor); the delta is small `calc` arithmetic touching no high-stakes
  category and well under 200 lines, so the route **stays standard** — no escalation.
- Does NOT re-brainstorm, does NOT run a plan-review phase, does NOT re-spawn a
  searcher/researcher for the `calc` layout the manifest already carries.
- Phase I1: one `architect` plan-lite, then a `coder` implements `Max` and proves it.
- Phase I2: behavioral verification runs (feature with a runtime surface — NOT
  exempt). Review is the **delta** path (a single reviewer over the iteration diff),
  NOT a full Phase 6 fan-out — the baseline was already reviewed and the route did
  not escalate to high-stakes.
- **GATE I auto-approves** iff tests green, zero Must-fix, behavioral verification
  passed, and no scope deviation.
- Retro is **deferred/batched** into the manifest iteration log (a single final
  iteration may run Phase 7 inline).
- `go build ./...` and `go test ./...` stay green; the new test covers the normal
  and empty-slice cases.

## expect (scoring overrides)

- `Outcome correctness`: `calc.Max` returns `(max, true)` for a non-empty slice and
  `(0, false)` for an empty/nil slice; a test covers both; `go test ./...` green.
- `Routing`: full credit if `/iterate` treats this as a warm code delta (inherits
  `standard`, delta review, no escalation) rather than a cold full-lifecycle run or
  an unnecessary full fan-out. Score **0** if it ran a fresh brainstorm/plan-review
  or a full Phase 6 fan-out on a non-escalated delta, or bounced a legitimate delta
  to `/new-task`.
- `No escaped defects`: the **empty-slice case is the control** — a `Max` that
  panics on empty (index out of range) or omits the `bool`/empty handling is an
  escaped defect; it must be caught by the new test and by the delta review.
