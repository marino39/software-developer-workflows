# Scorecard — 2026-07-10 — learnings-retrieval (task 20)

Live outcome-eval of the **learnings hardening**: `/new-task` Phase 0's two-class
tag matching (subject tags match what the task is about; activity tags match the
run's planned activities), the disclosure requirement, and the Phase 7
promotion-preference rule for process lessons. Validates the behavior-affecting
edits to `commands/new-task.md` (Phase 0 step 1, Phase 7 step 2) and the
`LEARNINGS.md` vocabulary split in the same change.

Command: `/workflow-eval --tasks 20` · repeat 1 · driver `/new-task "add calc.Min …"`
with the task's `## Learnings` block standing in for the live general file.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 20

Fixture: `fixtures/base`, green, no seed. Three planted bullets: `[review]`
(activity — MUST apply on every run), `[rust]` (subject — must NOT apply on a Go
task), `[pr][ci]` (activity — must NOT apply on a local run with no PR planned).

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing | 25 | 100 | Scoped route with stated rationale AND the full Phase 0 disclosure at the first touchpoint: one applied, two excluded, each with correct class reasoning — including the subtle case, `[pr][ci]` excluded on activity-not-planned semantics rather than subject mismatch (the planted distinction). |
| Outcome correctness | 25 | 97 | `Min` correct for normal/nil/empty (behavioral verification 6/6 incl. `[]int{}`, negatives, duplicates); suite green; conventions mirrored. −3: the explicit `Min([]int{})` literal assertion stayed an open Should-fix, so the suite's empty coverage rests on the nil case (shared `len==0` path). |
| No escaped defects | 20 | 100 | All three retrieval controls held: `[review]` demonstrably in force (both review channels performed AND stated the degenerate-input check — judge verified via fixture retro/manifest), zero clippy invocations (grep-verified), zero PR machinery. |
| Gate discipline | 15 | 100 | Scope gate carried disclosure + route rationale; GATE 3 auto-approve with all criteria genuinely met; GATE 4 per-item table (evidence + behavioral delta + protocol status); skill-emulation deviations recorded honestly. |
| Efficiency | 15 | 100 | Reduced tier on the 28-line scoped diff, codex skipped, skeptic correctly n/a at 0 Must-fix, PASS iteration 1, no escalations. |

**Task score:** (100·25 + 97·25 + 100·20 + 100·15 + 100·15) / 100 = **99.3**

**Escaped defects: 0.** The real `~/.claude/new-task/LEARNINGS.md` was never read
(harness-supplied block only) — the fail condition stayed clear.

## Observations

- **The activity-class matching did observable work:** the `[review]` bullet was
  not merely listed as applied — it was injected as a mandatory check into both
  review channels, and both stated the degenerate-input result. Under the old
  one-class "task's signals" reading, a strict orchestrator could have skipped
  this bullet on a task that isn't "about" review; the hardening makes the
  always-in-force semantics explicit and testable.
- **Both exclusion directions exercised:** subject mismatch (`[rust]` on Go) and
  planned-activity mismatch (`[pr][ci]` on a local run) — the second is the case
  the two-class model uniquely distinguishes.
- **The promotion-preference rule surfaced naturally:** GATE 4 routed both
  proposed lessons as bullets *with explicit reasoning* ("one-line heuristics,
  not activity procedures") — the new rule being consulted, not ignored.
- **Bonus data point for the fast path:** legitimate GATE 3 auto-approve on
  fully-green criteria, with the scope gate carrying the route rationale — first
  scorecard exercising the fast path since the gate-decidability revision.

## Ledger consequence

`Learnings trigger tags + evidence links` row: extended to the two-class
semantics (subject vs activity) with this scorecard as the measured source. The
disclosure requirement and Phase 7 promotion-preference ride the same row — they
are refinements of the same construct, not new complexity.
