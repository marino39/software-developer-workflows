# Variant — skeptic-off

Ablates the Phase 6 skeptic pass to measure whether it earns its cost.

## Delta (prepended to the dispatched /new-task)

> VARIANT skeptic-off: In Phase 6 step 4, **skip the skeptic pass entirely**.
> Take the consolidator's Must-fix set as final — do not spawn default-refute
> skeptic reviewers, and do not demote any Must-fix finding. Everything else in
> the workflow is unchanged.

## What to read from the A/B

Run the suite (or a subset) once as baseline and once with this variant, then
compare per the rubric:

- **No escaped defects** — does removing the skeptic let a real defect through, or
  conversely was the skeptic only ever demoting false positives?
- **Efficiency** — token/iteration delta from dropping the extra reviewer fan-out.

Verdict shape: `skeptic-off: <Δ escaped defects>, <Δ tokens> → <justified | not
justified> on this suite`. Single-run variance applies — raise `--repeat` before
trusting a small delta.
