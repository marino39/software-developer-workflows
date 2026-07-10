# Variant — triage-cold

Ablates the `/new-task` triage warm-start seam (Phase 0 step 3 + the route floor in
step 5) to measure what it actually saves. Applies to the warm-start task (task 09):
the same task is run **ignoring** the referenced triage manifest, so `/new-task`
re-derives classification, investigation, and route from cold.

## Delta (prepended to the dispatched /new-task for task 09)

> VARIANT triage-cold: **Ignore the triage manifest entirely** — do not read
> `docs/superpowers/triage/*.md`, do not seed from its `searcher`/`researcher`
> digests, repro, or root-cause, and do not inherit its route as a floor. Run Phase 0
> from cold: fan out `searcher`/`researcher` to rediscover the codebase context
> yourself, and set the route fresh from your own judgment of the task. Everything
> else in the workflow is unchanged.

## What to read from the A/B

Run task 09 once as baseline (the warm path, seam on) and once with this variant
(cold, manifest ignored), then compare per the rubric:

- **Efficiency** — the headline: the token/wall-clock/subagent-count delta from the
  cold Phase 0 re-investigation the warm path skips. This is where the seam must earn
  its keep. (Expect the saving to be a Phase-0-legwork saving, not a whole-run saving —
  the implement/review phases are identical.)
- **Routing** — the safety guard: the warm path inherits the triage route as a
  **monotonic floor**, so a triage-classified high-stakes issue can never be
  cold-downgraded. If the cold run ever routes *below* what triage set on a task where
  that matters, the floor is doing real safety work, not just saving tokens.
- **Outcome correctness / No escaped defects** — the warm path must not buy speed by
  seeding a wrong root-cause the run then trusts. If the cold run reaches a better
  outcome, the seam is paying for its speed in quality.

Verdict shape: `triage-cold: <Δ escaped defects>, <Δ tokens/subagents>, <route-floor
bound? y/n> → <the triage warm-start seam is justified | not justified> on this task`.
If the warm path cuts Phase 0 cost with no quality loss (or the floor demonstrably
prevents a downgrade), the seam is justified; if it saves nothing and the floor never
binds, cut it. Single-run variance applies — raise `--repeat` before trusting a small
delta.
