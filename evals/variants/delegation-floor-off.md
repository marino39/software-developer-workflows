# Variant — delegation-floor-off

Ablates the `/iterate` delegation floor (the 2026-07-22 addition: the intro's
**Delegation floor** paragraph, Phase I0.3's gap-dispatch sentence, Phase I2.2's
named verification executor, and the Token-hygiene "substantive work never done
inline" clause) to measure whether the floor actually changes how often the
orchestrator delegates. Applies to the `/iterate` tasks (04, 05).

## Delta (prepended to the dispatched command for tasks 04–05)

> VARIANT delegation-floor-off: Run `/iterate` as written, EXCEPT treat the
> command as if the following were absent: the intro's "Delegation floor"
> paragraph; the Phase I0 step 3 sentence "A genuine gap is still dispatched …
> inline Grep/Read exploration"; the Phase I2 step 2 clause "delegated to a
> `coder` (or `test-runner` when it is pure command-driving) exactly per
> `new-task.md` Phase 6 step 1, never driven by the orchestrator"; and the
> Token-hygiene clause "substantive work never done inline (the Delegation
> floor above — small deltas included)". Where those passages would have
> constrained you, fall back to your own judgment about what to do inline
> versus what to delegate. Everything else is unchanged.

This reproduces the pre-2026-07-22 command text by subtraction (the floor was
purely additive), so baseline-vs-variant ≈ post-vs-pre on the same harness.

## What to read from the A/B

The floor's claim is about WHO does the work, so score the usual rubric but
read the deterministic traces first — `evals/delegation-trace.sh` over each
driver transcript (spawns / self-edit / self-test), alongside
`evals/context-trace.sh`:

- **Delegation frequency** — the headline: with the floor, orchestrator
  self-edit and self-test should be ~0 and verification should be executed by
  a `coder`/`test-runner`; without it, expect inline drift on small deltas.
  First measurement (2026-07-22 remote A/B, dispatch-hostile harness — the
  Agent tool was unavailable, so delegation required initiative): floor-on
  preserved full delegation in 2 of 4 runs (0 self-edit / 0 self-test, CLI
  fallback dispatch) and named the floor in deviations in the other 2;
  floor-off (the literal pre-change file) delegated in 0 of 4 and inlined all
  source edits, tests, and verification.
- **Efficiency** — token/wall-clock delta. Caution: delegating costs
  wall-clock when dispatch is serial subprocess spawning; in a real session
  the Agent tool parallelizes lanes. Driver-context tokens alone undercount
  the delegating side (children are separately metered).
- **Outcome correctness / No escaped defects** — the guard: the floor must
  not change results (2026-07-22: equal — all 8 runs correct, 0 escaped).

Verdict shape: `delegation-floor-off: <Δ escaped defects>, <Δ self-edit/self-test
and spawns>, <Δ cost> → <the floor is justified | not justified> on this suite`.
Single-run variance applies — raise `--repeat` before trusting a small delta.
