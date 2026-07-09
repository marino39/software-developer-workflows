# Task 04 — iterate on a reviewed baseline (exercises /iterate warm-start + delta review)

## Statement (passed to /iterate)

> A prior `/new-task` run added the `calc.Sum` "Usage" section to `README.md` and
> finished (manifest present, route `scoped`, doc-only). Follow-up: also document
> `calc.Product` in the same "Usage" section. Documentation only — do not change any
> `.go` file.

## Fixture

`fixtures/base` — green. The `## Seed` below stands in for a completed prior run:
it adds the `calc.Sum` usage section to `README.md` and writes a minimal run
manifest under `docs/superpowers/runs/`, so `/iterate` has a reviewed baseline to
delta against (a real run would have left both).

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
mkdir -p docs/superpowers/runs
cat >> README.md <<'EOF'

## Usage

    calc.Sum([]int{1, 2, 3}) // 6
EOF
cat > docs/superpowers/runs/2026-07-08-calc-usage-doc-manifest.md <<'EOF'
# Run manifest — calc usage doc
route: scoped
outcome: local-kept
default branch: master
branch: task/calc-usage-doc
HEAD_SHA: (fixture HEAD after this seed commit)
design doc: n/a (doc-only fast path)
plan: n/a (plan-lite)
retro: docs/superpowers/retros/2026-07-08-calc-usage-doc.md
behavioral verification: exempt (doc-only)
open Should-fix: none

## Iteration log
- 2026-07-08 initial /new-task: added calc.Sum Usage section; GATE 3 auto-approved.
EOF
```

## Expected behaviour

- Phase I0: reads the manifest, treats the request as a **delta on the reviewed
  baseline** (does NOT bounce to `/new-task`). Route inherits `scoped`; the delta
  touches no high-stakes category and is tiny, so the route stays `scoped`.
- Does NOT re-brainstorm, does NOT run a plan-review phase, does NOT re-spawn a
  searcher/researcher for layout the manifest already carries.
- Phase I2: behavioral verification is **exempt** (doc-only); review is the
  **delta** path (single reviewer over the iteration diff), NOT a full Phase 6
  fan-out — the baseline was already reviewed.
- **GATE I auto-approves** — route not escalated, base suite green (doc diff is
  test-inert), zero Must-fix, verification exempt, no scope deviation.
- Retro is **deferred/batched**: a manifest iteration-log entry is appended; a full
  Phase 7 + GATE 4 runs once (this being a single final iteration, inline is fine).
- No `.go` file touched; `go build ./...` and `go test ./...` stay green.

## expect (scoring overrides)

- `Outcome correctness`: README's "Usage" section gains a correct `calc.Product`
  example alongside the existing `calc.Sum` one; no code changed.
- `Routing`: full credit if `/iterate` treats this as a warm delta (inherits
  `scoped`, delta review) rather than a cold full-lifecycle run. Score **0** if it
  ran a fresh brainstorm/plan-review/full Phase 6 fan-out on a doc-only delta, or if
  it bounced a legitimate delta to `/new-task`.
- `No escaped defects`: **n/a** (doc-only) — reweight its 20 points onto Routing
  (+10) and Gate discipline (+10).
- Fail the run if any `.go` file changed, GATE I did not auto-approve, or the retro
  ran per-tweak instead of batched.
