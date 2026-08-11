# Variant — retro-skip-off

Ablates proposal P4's Phase 7 step 0 (the clean-fast-path retro skip) so every
run pays the full retrospective again — measuring whether the skip loses durable
lessons. Applies to the scoped/fast-path tasks (01–05, 17); standard-routing
tasks never satisfy the skip criteria and are inert here.

## Delta (prepended to the dispatched /new-task)

> VARIANT retro-skip-off: Treat `new-task.md` Phase 7 step 0 as absent — run the
> full Phase 7 (retrospective, lesson distillation, GATE 4) on every run
> regardless of how clean it was. Everything else is unchanged.

## What to read from the A/B

- **Lesson yield on clean runs** — the claim under test: a clean scoped run has
  nothing durable to distill. Count GATE 4 rows with real in-run evidence that
  the variant produces on runs the baseline skipped. Zero rows at n≥3 → the
  skip is free and stands; recurring evidenced rows → the skip is eating real
  lessons and its criteria must tighten (or the row is cut).
- **Cost delta** — the retro write + distillation + GATE 4 per skipped run;
  read turns/dispatches after GATE 3 in both arms.
- **Manifest honesty** — baseline runs that skip must show
  `retro: skipped (clean scoped run)` in the manifest; a skip with no recorded
  marker is a silent-pass defect, not a saving.

Verdict shape: `retro-skip-off: <GATE 4 evidenced rows on clean runs>,
<Δ post-GATE-3 cost>, <skip marker present y/n>`.
