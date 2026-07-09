# Workflow eval scorecard — 2026-07-09 (draft-pr)

**Label:** draft-pr · **Suite:** tasks 01, 02, 03 · **Repeat:** 1 · **Variant:** none
**Baseline diffed against:** `evals/results/2026-07-08-baseline-scorecard.md`
**Trigger:** behavior-affecting change to `commands/new-task.md` Phase 6 step 9 —
the finish step now opens PRs as **draft** PRs (`gh pr create --draft`) so the diff
can be reviewed/iterated before it is marked ready. Doc-guide (`docs/guide/new-task.html`)
updated to match. Per CLAUDE.md modification-protocol tier 2, a live eval + scorecard
diff is owed before merge.

## Observability note (read first)

The eval harness runs each task against an **isolated local fixture copy with no git
remote**, so Phase 6 step 9 never creates a real PR — the runs finalize locally. The
draft-vs-regular-PR distinction is therefore **not directly measurable** by the five
scored dimensions. What this live eval *does* establish:

1. **No regression** — the edited `new-task.md` still drives clean, correctly-routed
   runs with well-formed decidable gates and intact review machinery.
2. **The instruction is followed** — all three runs, at the finish step, explicitly
   stated they *would open a **draft** PR* (verbatim in each run's finish-step
   artifact), confirming the new wording lands and is honored.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (exit 0), confirmed by the pre-commit hook on
the change commit. No new assertions added (the change is instruction-wording only).

## Layer 2 — outcome-eval

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score |
|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ | 98 | 98 | n/a¹ | 97 | 95 | none | **97.3** |
| 02 bugfix | scoped → **scoped** ✓ | 96 | 100 | 95 | 90 | 92 | none | **95.3** |
| 03 route-correct | high-stakes → **high-stakes** ✓ | 100 | 100 | 100 | 95 | 90 | none | **96.75** |

¹ Task 01 `expect` marks *No escaped defects* n/a and reweights its 20 pts (+10 Routing, +10 Gate discipline).

**Suite score = 96.45** (mean of task scores). **Escaped defects: 0.**

Finish-step outcome verbatim in each run:
- Task 01 — "would produce a **draft PR** (`gh pr create --draft`) … (no remote) local ff-merge."
- Task 02 — "**Would open a DRAFT PR** (`gh pr create --draft`) if a git remote existed … local ff-merge."
- Task 03 — "**Would open a DRAFT PR** (`gh pr create --draft`, high-stakes PR path) … finalized locally, commit kept on branch."

## Regression section

vs `2026-07-08-baseline-scorecard.md` (suite 93.7):

- **No dimension dropped > 10 points on any task.** Every dimension held or improved.
- **No new escaped defects** (0 → 0).
- Task deltas: 01 93.2 → 97.3 (+4.1), 02 94.75 → 95.3 (+0.55), 03 93.25 → 96.75 (+3.5).
  Suite 93.7 → 96.45 (+2.75). The gains are run-to-run noise (single sample, non-deterministic),
  **not** attributable to this change — task 03's lift is the baseline's coder revert-discriminate
  tool-reliability ding (Efficiency 65 → 90) not recurring this run, which is orthogonal to the
  draft-PR edit. The material result is **no regression**, as expected for a finish-step wording
  change the harness cannot exercise end-to-end.

## Verdict

`draft-pr: 0 new escaped defects, no dimension regression, finish-step instruction honored in
all 3 runs → change is safe to merge on this suite.` The one behavior the change introduces
(draft PR at finish) is not exercised against a remote in the harness, so its correctness rests
on the instruction being followed (confirmed in the finish-step artifacts) plus the lint; it is
not a scored dimension.

## Notes

- Runs dispatched as subagents with the eval-harness preamble (auto-approver at every gate;
  propose-only at GATE 4 — nothing written to `~/.claude`, no `capture.sh`). Only structured
  artifacts collected; no raw transcripts.
- Each task ran against an isolated, git-initialized copy of `evals/fixtures/base` (task 02
  seeded RED per its `## Seed`).
- Scored by three fresh `reviewer` judges (one per task), each fed only the run artifacts +
  the task `expect` block + `rubric.md`.
