# Workflow eval scorecard — 2026-07-08 (baseline)

**Label:** baseline · **Suite:** tasks 01, 02, 03 · **Repeat:** 1 · **Variant:** none
**Trigger:** first live outcome-eval, run to establish a baseline for the
gate-decidability change (`commands/new-task.md` gate contract + GATE 1/2/4 +
scope gate; `rubric.md` Gate discipline; `lint.sh` Check 4).

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (exit 0). Check 4 now also asserts GATE 4's
per-item decision-table structure and the scope-gate route rationale; each new
assertion was confirmed non-vacuous (fails when its structure is removed).

## Layer 2 — outcome-eval

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score |
|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ | 97 | 95 | n/a¹ | 88 | 90 | none | **93.2** |
| 02 bugfix | scoped → **scoped** ✓ | 95 | 100 | 95 | 90 | 90 | none | **94.75** |
| 03 route-correct | scoped→high-stakes → **high-stakes** ✓ | 100 | 100 | 100 | 90 | 65 | none | **93.25** |

¹ Task 01 `expect` marks *No escaped defects* n/a and reweights its 20 pts (+10 Routing, +10 Gate discipline).

**Suite score = 93.7** (mean of task scores). **Escaped defects: 0.**

## Regression section

`baseline established, no prior scorecard` — `evals/results/` was empty before this
run. Future runs diff against this file.

## What the change under test did

The gate-decidability change is exercised by every task and lands cleanly:

- **Scope gate carried the route rationale** in all three runs — each stated the
  signals weighed and *explicitly why the task is not high-stakes* (or, on task 03,
  why it could not truthfully assert that, deferring to the step-3.5 re-check).
- **GATE 4 produced the per-item decision table** in all three runs, with the
  evidence / behavioral-delta / protocol-status columns populated. It correctly
  **dropped** evidence-free lesson candidates (task 02's, and task 01's redundant
  row) and **approved** lessons that carried in-run evidence + a stated delta —
  the new "a lesson with no in-run evidence is not durable; drop it" rule firing.
- **Gate discipline scored 88–90** across the suite: gates were decidable, not just
  well-formed. The only dings were procedural (task 01 placed its inherited-red
  judgment under *Key decisions* rather than *Deviations*).
- **Proposition #4 routing held** (task 03): scoped→high-stakes escalation at
  fast-path step 3.5, auto-approval voided → human GATE 3, full tier with opus
  escalations, deviation recorded. Routing = 100.

## Observations (orthogonal to this change — candidate follow-ups)

1. **Shared-fixture red baseline.** `evals/fixtures/base` carries task 02's seeded
   `calc.Sum` bug, so `go test ./...` is red on the base for *every* task. Task 01's
   `expect` ("GATE 3 auto-approves", green suite) is therefore not literally
   satisfiable — the doc-only run reasonably treated the red as inherited
   (trunk-red style) and still auto-approved. Consider giving task 01/03 a green base
   (per-task fixture, or a green `calc`) so the "tests green" criterion is testable
   as written. Not scored as a defect here.

2. **Revert-discriminate via a source-mutating test-runner (task 03).** The coder
   loop's attempt 2 drove revert-discriminate by mutating source through the
   test-runner and left the tree reverted mid-swap; the orchestrator re-applied the
   one-line fix and re-verified. Dropped task 03's Efficiency to 65. This is a
   coder/tool-reliability issue, not a gate issue — and the run itself proposed the
   matching GATE 4 lesson (keep the swap in the coder's own process with a guaranteed
   restore; adjudicate the final settled tree, not agent prose).

## Notes

- Runs were dispatched as subagents with the eval-harness preamble (auto-approver at
  every gate; propose-only at GATE 4 — nothing written to `~/.claude`, no
  `capture.sh`). Only structured artifacts were collected; no raw transcripts.
- Each task ran against an isolated, git-initialized copy of `evals/fixtures/base`.
- Efficiency for tasks 01/02 is scored on qualitative signals (reduced tier, codex
  skip, single review iteration) — the artifacts didn't include measured token/wall
  figures.
