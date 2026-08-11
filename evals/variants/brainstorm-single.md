# Variant — brainstorm-single

> **Re-scoped (2026-08-11).** The baseline is no longer 3 architects + a fable
> synthesizer — it is 1 `architect` + 1 codex lens + an opus synthesizer (see the cost
> pass in `evals/complexity-ledger.md`). This variant is now the **floor case**: one
> Claude architect, *no codex lens*, so it measures what the out-of-model second head
> buys. `brainstorm-3head-restore` is the ceiling case. Read the three together.

Ablates the Phase 1 three-architect fan-out + fable synthesizer down to a single
architect, to measure whether multi-lens brainstorming earns its cost on real tasks
(vs only on genuinely wide design spaces).

## Delta (prepended to the dispatched /new-task)

> VARIANT brainstorm-single: In Phase 1, dispatch **one** `architect` (opus) that
> proposes a single recommended approach with its trade-offs; skip the codex design
> lens and skip the separate synthesizer dispatch (the architect writes the design
> doc directly in artifact mode). The design doc records that one approach plus any alternatives
> it explicitly rejected. Phases 2+ are unchanged.

## What to read from the A/B

- **Outcome correctness** — does the single-architect design lead to as good a final
  result, or does it miss the approach the 3-lens fan-out would have surfaced?
- **Gate discipline** — GATE 1 still shows rejected alternatives (now from one
  architect's reasoning rather than three competing digests)?
- **Efficiency** — token delta from four Phase-1 architect calls → one.

Note: brainstorming pays off most on wide/ambiguous design spaces; the fixture tasks
are narrow, so expect this variant to look cheap-and-equal here — that itself is a
signal about *when* the fan-out is worth it. Verdict shape: `brainstorm-single: <Δ
outcome>, <Δ cost> → justified | not justified on this suite (task-space caveat)`.
