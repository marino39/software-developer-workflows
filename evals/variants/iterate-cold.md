# Variant — iterate-cold

Ablates the `/iterate` warm-start path to measure what it actually saves. Applies
to the follow-up task (task 04): instead of the warm `/iterate` lane, the same
follow-up is run cold through `/new-task`, ignoring the prior-run manifest.

## Delta (replaces the dispatched command for task 04)

> VARIANT iterate-cold: Do NOT run `/iterate`. Ignore the run manifest at
> `docs/superpowers/runs/*-manifest.md` entirely — treat the follow-up as a fresh
> task and run the full `/new-task` workflow on it from Phase 0 (cold setup,
> routing, fast-path or standard as `/new-task` decides). The baseline diff already
> in the branch stays, but you rediscover context from scratch — no seeded design/
> plan/layout, no delta-review shortcut, no deferred retro. Everything else is
> unchanged.

## What to read from the A/B

Run task 04 once as baseline (the `/iterate` warm path) and once with this variant
(cold `/new-task`), then compare per the rubric:

- **Efficiency** — the headline: token/wall-clock/iteration delta from cold Phase 0
  rediscovery + brainstorm/plan-review machinery + a per-tweak retro that `/iterate`
  skips. This is where `/iterate` must earn its keep.
- **Outcome correctness / No escaped defects** — the guard: the warm path must NOT
  buy speed by shipping a worse result. If cold `/new-task` catches something the
  delta review missed, that is `/iterate` paying for its speed in quality.
- **Routing / Gate discipline** — confirm the warm path's inherited-route +
  auto-approve is as disciplined as the cold path's routing.

Verdict shape: `iterate-cold: <Δ escaped defects>, <Δ tokens/iterations> → <the
/iterate layer is justified | not justified> on this task`. If the warm path cuts
cost with no quality loss, `/iterate` is justified; if it loses defects or the cold
run was no more expensive, it is not. Single-run variance applies — raise
`--repeat` before trusting a small delta.
