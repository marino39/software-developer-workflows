# Variant — dispatch-readiness-off

Ablates the `commands/new-task.md` Phase 4 **dispatch-readiness** check (the
2026-07-29 addition: step 1.5, the unready rows in step 2's checklist source and
exit condition, and the readiness verdict in GATE 2's decision evidence) to
measure whether catching thin steps at plan review is worth a stricter phase
exit. Applies to the tasks that produce a real plan — 23 primarily, plus 17 and
20; the fast path skips Phase 4 entirely, so scoped tasks are inert here.

## Delta (prepended to the dispatched /new-task)

> VARIANT dispatch-readiness-off: Run `/new-task` as written, EXCEPT treat Phase
> 4 step 1.5 (dispatch-readiness) as absent. The mapping table has three columns
> only — design decision → plan step(s) → verification — and the phase exits when
> that table is complete with no gaps, regardless of whether a step names its
> files, its interface contract, or an exact verification command. Step 2's
> checklist source is the unmapped rows only; GATE 2's Results carry the
> mapping-table result without a readiness verdict. Everything else — the
> Dispatch brief, the coder's ambiguity policy, review machinery, gates — is
> unchanged.

## What to read from the A/B

The check's claim is that thin steps caught once at Phase 4 are cheaper than the
same thinness rediscovered once per coder, so read where the cost lands:

- **Phase 4 vs Phase 5 cost split** — the headline: the variant should exit
  Phase 4 in fewer iterations (a weaker exit condition is easier to satisfy) and
  pay for it downstream in `coder` roundtrips. Read `evals/dispatch-trace.sh`
  coder `rtrip` alongside the Phase 4 iteration count. If the variant is
  cheaper on BOTH, the check is not earning its cost.
- **Interaction with the coder ambiguity policy** — the confound to watch. With
  the policy in force, a thin step no longer bounces: the coder assumes and
  proceeds. So this variant may show its cost as *assumption volume* rather than
  roundtrips — more decisions made at the cheapest tier with the least context.
  Count `assumptions` entries per run, not only `rtrip`. If readiness mainly
  moves decisions from coder to architect without changing outcomes, say so
  plainly in the verdict — that is a quality argument, not a cost one, and the
  ledger row should be re-sourced accordingly.
- **Outcome correctness / No escaped defects** — the guard, and the real claim:
  a decision made by an architect with the design doc in hand should beat the
  same decision made by a coder holding one plan slice. If escaped defects are
  equal across arms, the check is buying predictability, not correctness.

Verdict shape: `dispatch-readiness-off: <Δ escaped defects>, <Δ Phase 4
iterations>, <Δ coder rtrip and assumption volume> → <dispatch-readiness is
justified | not justified> on this suite`. Single-run variance applies — raise
`--repeat` before trusting a magnitude.
