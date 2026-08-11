# Variant — phase34-split-restore

Restores the pre-2026-08-11 split lifecycle on the `standard` route: a separate
plan phase (Phase 3), a separate mapping-table plan review (Phase 4), and GATE 2
— ablating proposal P2's merged design-plan artifact to measure whether the
second loop earns its cost. Applies to tasks that route standard (24 with the
route floor pinned, plus 23); scoped tasks skip Phases 1–4 entirely and are
inert here.

## Delta (prepended to the dispatched /new-task)

> VARIANT phase34-split-restore: On the `standard` route, treat the merged
> design-plan rules as absent: Phase 1 step 3 writes the design doc only,
> Phase 2 reviews the design only (no coverage/readiness remit), GATE 1 carries
> design evidence only, and Phases 3–4 + GATE 2 run exactly as written for
> high-stakes. Everything else is unchanged.

## What to read from the A/B

The merge's claim is that the second loop largely re-verifies the first (the
dispatch-readiness NULL), so read what only a split loop could have caught:

- **Escaped defects + coverage misses** — the headline. A defect traceable to a
  design decision with no implementing step, or a step whose verification was
  never pinned, is the class the separate mapping table existed to catch. Zero Δ
  at n≥3 → the merge stands; any Δ → the mapping table does real work and the
  merge must be re-scoped or reverted.
- **Cost split** — merged runs should show one fewer architect dispatch, one
  fewer reviewer dispatch, one fewer human gate, and fewer pre-code turns. If
  the merged arm's Phase 2 loop runs MORE iterations (a combined artifact can
  converge slower — each blocker revision re-reviews design AND plan), the
  saving shrinks; count it honestly against the split arm's Phase 4 iterations.
- **Gate decidability** — the merged GATE 1 must still surface the coverage/
  readiness verdict (every decision → step(s) → verification; steps ready). A
  merged run whose gate cannot show it has lost decidability — a
  Gate-discipline regression, not a saving.

Verdict shape: `phase34-split-restore: <Δ escaped>, <Δ coverage misses>,
<Δ pre-code dispatches/turns>, <merged-gate decidability held y/n>`.
