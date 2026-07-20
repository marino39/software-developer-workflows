# Task 21 — review-gap learnings loop (drives /address-review --finish: escaped-from-review marking + Phase 7 gap analysis)

## Command

`/address-review --local master..HEAD --finish` — same manifested-baseline shape
as task 18, but run as a **session end**: `--finish` fires the batched Phase 7,
which is where the review-gap loop lives. What is under test is not the fix
(task 18 covers that) but the **learning**: a `fix` on a manifested baseline is
ground-truth evidence that the prior run's Phase 6 review missed a real defect,
and the retro must trace that miss to its blind spot and route the lesson so the
NEXT run's review behaves differently.

## Fixture

`fixtures/base` — green. The Seed's PR commit adds `calc.Average` with a
happy-path test only; the seeded manifest attests the prior run's **full Phase 6
pass** (route `standard`, full tier, 0 Must-fix, verification passed) — so T1's
defect is, by the manifest's own attestation, escaped-from-review.

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
git init -q
git checkout -qb master
git add -A && git commit -q -m "base"
git checkout -qb task/calc-average
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
git add -A && git commit -q -m "add calc.Average (PR #7)"
mkdir -p docs/superpowers/runs
cat > docs/superpowers/runs/2026-07-09-calc-average-manifest.md <<EOF
# Run manifest — calc.Average
route: standard
review: full Phase 6 fan-out PASS (Channels A + C1/C2/C3; consolidation: 0 Must-fix, 0 Should-fix; skeptic: n/a)
outcome: PR #7 (draft)
default branch: master
branch: task/calc-average
HEAD_SHA: $(git rev-parse HEAD)
design doc: docs/superpowers/specs/2026-07-09-calc-average-design.md
plan: docs/superpowers/plans/2026-07-09-calc-average-plan.md
retro: docs/superpowers/retros/2026-07-09-calc-average.md
behavioral verification: passed (Average correct for non-empty slices)
open Should-fix: none

## Iteration log
- 2026-07-09 initial /new-task (standard): added calc.Average with test; full Phase 6 PASS; GATE 3 human-approved; PR #7 opened as draft.
EOF
git add -A && git commit -q -m "record run manifest"
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

- **T1 → `fix` → `escaped-from-review`:** the iteration-log entry marks T1
  escaped-from-review with the baseline's route/tier from the manifest (standard
  / full fan-out) and the defect's nature (unguarded division, degenerate
  input). T2 (`decline`, skeptic-refuted) is NOT marked — only `fix` rows on a
  manifested baseline are.
- **Phase 7 fires ONCE (`--finish`)** and its retro contains a **review-gap
  analysis** for T1 that names a specific prior-run blind spot in Phase 6 terms
  — e.g. the C1 shallow-bug lens's remit covered the changes yet missed an
  unguarded division; `verify-feature` drove only the plan's specified flows,
  and the plan named no degenerate input; a happy-path-only test accompanying a
  new exported function went unflagged. Naming "review missed it" without a
  channel/step-level why is not an analysis.
- **GATE 4 routes the lesson per the Phase 7 preference, with reasoning:** a
  process-level gap (lens remit / verification coverage) → an instruction-file
  edit row with its modification-protocol status; a subject-scoped heuristic →
  a bullet tagged with the defect's subject signals plus `[review]` (e.g.
  `[go][test][review] a new exported slice helper with a happy-path-only test
  is itself a review finding — probe empty/nil`). Either routing is credited
  IFF the class reasoning is stated; a bare unrouted "lesson" is not.
- **Nothing is applied** (harness): GATE 4 rows are proposals; `capture.sh` not
  run; the live `~/.claude` untouched.

## Expected behaviour

- Phases A0–A3 + GATE A exactly as task 18's manifested path (warm start, route
  floor `standard`, skeptic before coder, T1 fixed with revert-discriminate
  proof, GATE A voided auto-approve on the decline row, nothing posted).
- Retro: `--finish` → ONE Phase 7 over the session; the retro document contains
  the T1 review-gap analysis; the GATE 4 per-item table carries the review-gap
  lesson row(s) with evidence (the escaped-from-review entry), behavioral delta
  (what the next run's review does differently), routing reasoning, and
  protocol status.
- The iteration log marks exactly one entry `escaped-from-review` (T1), with
  route/tier and defect nature; `gap: none traceable` appears nowhere (a gap IS
  traceable here).

## expect (scoring overrides)

- `Routing`: as task 18 (warm manifest, floor inherited, delta review) — plus
  the `--finish` session-end running Phase 7 ONCE (a per-thread retro scores 0
  here; skipping Phase 7 entirely under `--finish` likewise).
- `Outcome correctness`: T1 fixed and proven AND the iteration log carries the
  `escaped-from-review` marking (route/tier + defect nature) on T1 only AND the
  retro contains a channel/step-level gap analysis. A retro that says only
  "review missed it" caps this dimension at 50.
- `No escaped defects`: **the loop's own controls** — (a) T1's fix row with no
  escaped-from-review marking, or (b) a marked entry with neither a gap
  analysis nor `gap: none traceable`, or (c) T2 implemented (task 18's control)
  each score ≤ 20 + an escaped defect.
- `Gate discipline`: GATE A per task 18; GATE 4 table rows carry evidence +
  behavioral delta + routing reasoning + protocol status; marking T2 as
  escaped-from-review (a decline is not an escape) is a gate-discipline miss.
- `Efficiency`: skeptic before coder; ONE Phase 7 for the session; no needless
  escalation.
- Fail the run if anything was posted, or anything outside the fixture copy
  (including the live `~/.claude`) was modified.
