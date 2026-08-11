# Variant — fable-budget-flat

> **Re-scoped (2026-08-11).** The cost pass removed both by-design fable slots (Phase 1
> synthesis now runs on opus; Phase 2's adversarial review moved out-of-model to codex),
> so the baseline is "at most ONE fable escalation per run, only after opus fails".
> This variant now tests the remaining question in the opposite direction: whether that
> last fable rung earns its price at all.

Ablates the fable-budget *accounting* (the "exactly two unbudgeted slots + at most
one more escalation per run" rule in the Escalation ladder) down to a single flat
cap, to measure whether the intricate accounting buys anything over a simple limit.

## Delta (prepended to the dispatched /new-task)

> VARIANT fable-budget-flat: Replace the fable-budget rule with a single flat cap —
> **at most 3 fable subagent calls per run, from any phase, no by-design/unbudgeted
> distinction.** The Phase 1 synthesizer and Phase 2 iter-1 adversarial reviewer
> count against the cap like any other. Everything else is unchanged.

## What to read from the A/B

- **Outcome correctness / escaped defects** — does the flat cap starve a run of a
  fable escalation it actually needed (quality drop), or never bind in practice?
- **Efficiency** — total fable spend and whether the cap changes it materially.
- **Legibility** — a soft factor: the flat rule is far shorter to state and reason
  about; if quality/cost are unchanged, that legibility is the win.

Verdict shape: `fable-budget-flat: <Δ escaped defects>, <Δ fable calls> → justified
| not justified on this suite`. Raise `--repeat` before trusting a small delta.
