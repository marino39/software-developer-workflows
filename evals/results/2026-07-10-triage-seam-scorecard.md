# Scorecard — 2026-07-10 — /new-task triage warm-start seam (functional, task 09)

Verifies the new `/new-task` Phase 0 **triage warm-start seam** (step 3 + the route
floor in step 5) that consumes a `/triage-issue` manifest. This is a **functional**
verification — does the seam fire and seed correctly — NOT the warm-vs-cost A/B, which
is set up (task 09 + `triage-cold` variant) and owed.

Command: seam behavior driven on the task-09 fixture (bug + seeded triage manifest).

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS. The Phase 0 renumbering (route moved step 4 → 5)
kept route/tier consistency (Check 2), phase completeness (Check 3), and gate-format
(Check 4) green; the one cross-reference to the old "Phase 0 step 3" (in
`triage-issue.md`) was made number-independent.

## Functional verification (task-09 fixture: calc bug + triage manifest)

Ran `/new-task` Phase 0 against a fixture seeded with the calc off-by-one AND a triage
manifest (what a prior `/triage-issue` would have written), with the task referencing
that manifest. Checked the five seam behaviors:

| # | Behavior | Result |
|---|---|---|
| 1 | Manifest detected + loaded | ✅ referenced path found and read; digests/repro/root-cause/scope parsed |
| 2 | Seeds from manifest, skips redundant legwork | ✅ searcher/researcher/repro/root-cause seeded from the manifest; step-4 fan-out is a **no-op** (no genuine gap for a ~1-LOC arithmetic fix) |
| 3 | Route floor inherited (monotonic) | ✅ route = **scoped**, taken as the manifest's floor, not re-derived; re-checks (fast-path 3.5 / Phase 6 step 0) find no escalation trigger |
| 4 | Triage-seeded disclosure at first touchpoint | ✅ required at the fast-path scope gate, naming the manifest |
| 5 | Additive / inert without a manifest | ✅ step 3 is an explicit no-op when no manifest is referenced → existing tasks 01–08 unaffected |

Read-only: the run modified nothing (git status showed only the fixture's handed-in
seed state).

## Regression posture

The seam is **additive and inert without a referenced manifest** — none of the existing
tasks (01–08) reference one, so the change cannot alter their behavior. That is the
regression argument for this new-task.md edit: no existing eval path is touched. (A
belt-and-braces re-run of 01–03 would show a flat diff; not spent here since the seam
provably cannot fire on them.)

## Owed (the cost A/B)

The magnitude question — *how much* Phase-0 legwork the warm-start actually saves, and
whether the route floor ever binds to prevent a cold downgrade — is the statistical A/B:

```
/workflow-eval --tasks 09 --variant triage-cold --repeat 3
```

Baseline (seam on) vs `triage-cold` (manifest ignored, cold Phase 0). Expect a
Phase-0-legwork saving (not a whole-run saving — implement/review phases are identical),
plus a safety check that a triage high-stakes classification can't be cold-downgraded.
Ledger row `Triage warm-start seam` is **ablation-queued** pending this run — exactly
how the `/iterate` warm-start row was staged before its A/B firmed it.

## Verdict

The seam is correct and wired in: it detects and seeds from the manifest, skips the
redundant Phase 0 legwork, inherits the route as a monotonic floor, discloses the
triage-seed at the gate, and is inert (regression-safe) without a manifest. Functional
n=1 pass. The cost/safety A/B is set up and owed before the layer is called earned.
