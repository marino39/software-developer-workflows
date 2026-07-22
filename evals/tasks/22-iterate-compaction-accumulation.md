# Task 22 — multi-delta /iterate session (exercises the compaction-suggestion accumulation trigger)

Drives the **firing** half of the 2026-07-22 compaction-suggestion rule
(`commands/iterate.md` Retro step 1): a single `/iterate` **session** that runs
several short deltas back-to-back, so the accumulation trigger (rule (b): ≥3
iteration-log rows since the last `compact-suggested` marker) fires mid-session,
tags the row, and resets. The `2026-07-22-compaction-suggestion` scorecard covered
only single-delta runs, where the suggestion is correctly *suppressed*; this task
covers the case where it must *surface*.

Deliberately **scoped + doc-only** so it isolates rule (b) from rule (a): a scoped
doc delta is never "heavy" (no high-stakes fan-out, no Phase 6.5 CI wait), so any
suggestion that appears comes purely from accumulation — not from heaviness.

## Command

Run ONE `/iterate` **session** over the three sequential deltas in `## Session
deltas` below — each is a normal warm delta on the same reviewed baseline,
auto-approve GATE I after each, and append to the same manifest iteration log. After
the third delta, finish the session (`/iterate --finish`) so the batched Phase 7
runs once over all three. This is a single-session multi-delta driver, not three
separate runs — the manifest (and its iteration log + any `compact-suggested`
marker) is the shared state that carries across the deltas.

## Fixture

`fixtures/base` — green. The `## Seed` stands in for a completed prior `/new-task`
run: it adds a `calc.Sum` "Usage" section to `README.md` and writes a run manifest
with **one** iteration-log row, so `/iterate` has a reviewed doc baseline to delta
against and the accumulation counter starts from a known state (1 row, no marker).

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
git init -q && git add -A && git commit -qm "base fixture"
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
git add -A && git commit -qm "seed: prior /new-task baseline (calc.Sum usage doc)"
```

## Session deltas

Each is a small, self-contained documentation addition to `README.md` — no `.go`
file is touched, and each is a legitimate scoped doc delta:

1. Add a `## Building` section documenting `go build ./...`.
2. Add a `## Testing` section documenting `go test ./...`.
3. Add a `## Contributing` line pointing at the repo's issue tracker.

## Accumulation math (what a correct run does — the crux)

The manifest starts with **1** iteration-log row and **no** `compact-suggested`
marker. Counting "rows since the last marker" per the rule:

| Delta | Appends row → total | Rows since last marker | Rule (b) `≥3`? | Suggestion in GATE I **Next**? | Row tagged? |
|---|---|---|---|---|---|
| 1 (Building) | row 2 → 2 | 2 | no | **no** | no |
| 2 (Testing) | row 3 → 3 | 3 | **yes** | **YES** — surfaces the `/compact` line | **`compact-suggested`** → resets counter |
| 3 (Contributing) | row 4 → 4 | 1 (since row 3 marker) | no | **no** | no |

So the suggestion must surface on **delta 2 only**, that row must be tagged
`compact-suggested`, and the reset must keep delta 3 clean. Rule (a) never fires
(scoped, doc-only, local-kept — no heaviness on any delta), so delta 2's suggestion
is unambiguously the accumulation trigger.

The suggested focus line, when it surfaces, is the shared string:
`/compact preserve the run-ledger path, route + escalations, artifact paths, open
Must-fix/Should-fix, current phase + iteration`.

## Expected behaviour

- Each delta: warm delta on the reviewed baseline — route inherits `scoped`, no
  escalation (doc-only, `DIFF_LINES` tiny, no high-stakes category), delta review
  (single reviewer, no fan-out), behavioral verification exempt (doc-only), **GATE I
  auto-approves**.
- The compaction suggestion surfaces on **delta 2 only** (rule (b)), that
  iteration-log row is tagged `compact-suggested`, and the counter resets so delta 3
  does **not** re-surface it. Deltas 1 and 3 carry no suggestion and no tag.
- Retro is **batched**: one Phase 7 + GATE 4 at `--finish`, covering all three
  logged deltas — not three per-tweak retros.
- No `.go` file touched; `go build ./...` and `go test ./...` stay green (the doc
  deltas are test-inert). Final README carries Usage + Building + Testing +
  Contributing.

## expect (scoring overrides)

- `Outcome correctness`: README ends with all three new sections (Building, Testing,
  Contributing) plus the seeded Usage; no code changed; build/test green.
- `Routing`: full credit if every delta is a warm `scoped` delta (inherited, delta
  review, no escalation). Score **0** if any delta ran a fresh brainstorm/plan-review
  or a full Phase 6 fan-out, or bounced a legitimate delta to `/new-task`.
- `No escaped defects`: **n/a** (doc-only) — reweight its 20 points onto Routing
  (+10) and Gate discipline (+10).
- `Gate discipline` carries the **firing-path control** (the whole point of this
  task). Full credit requires ALL of: the suggestion surfaces on delta 2, is absent
  on deltas 1 and 3, delta 2's log row is tagged `compact-suggested`, and the reset
  is honored. Score this dimension **≤ 25** if the suggestion never surfaces across
  the session (accumulation trigger dead), fires on every delta (no reset / miscount),
  surfaces without tagging the row, or surfaces on the wrong delta.
- `Efficiency`: three delta iterations within caps, one batched retro, no needless
  escalation.
- Fail the run if any `.go` file changed, any GATE I did not auto-approve, or the
  retro ran per-tweak instead of batched at `--finish`.

## Note for the retro (a design question this task may surface)

The rule counts iteration-log **rows**, and the seed's prior-session `/new-task`
baseline row counts toward the first fire — so the suggestion trips on the *second*
in-session delta, not the third. If a run (or a reviewer) argues the accumulation
should count only **in-session** `/iterate` deltas (context growth is per-session,
while the log persists across sessions), that is a legitimate finding for the change's
retro — the marker/reset mechanism is what this task validates; the exact counting
base (all rows vs in-session rows) is the tunable it surfaces.
