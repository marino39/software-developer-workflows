# Variant — agent-effort-xhigh-restore

Reverse ablation for the 2026-09-07 model-tuning pass (M2): restores `effort: xhigh`
on `architect` and `debugger` to measure whether the higher effort level earns its
cost on Opus 5, whose vendor guidance calls `high` the default starting point and
`xhigh`/`max` "for measured wins, not a starting point".

## Delta (prepended to the dispatched /new-task)

> VARIANT agent-effort-xhigh-restore: run `architect` and `debugger` at
> `effort: xhigh` instead of the `high` default. Everything else in the workflow is
> unchanged.

## What to read from the A/B

**This variant cannot be settled by `/workflow-eval` alone** — effort is inert in the
eval harness (see the effort-defaults row in `evals/complexity-ledger.md`), so a
harness run measures nothing about it. The A/B must be a **real CLI run** of the same
tasks under each setting, comparing:

- **Design/debug quality** — escaped defects, and whether the architect's design
  survived Phase 2's adversarial review without a blocking-issue loop.
- **Efficiency** — token spend and wall-clock on the two most expensive agents in the
  fleet; `xhigh` is expected to cost more, so it must buy a quality delta to hold.
- **Over-deliberation** — vendor guidance warns `xhigh` "can show diminishing returns
  and overthink simpler tasks"; watch for scoped-route runs where the extra depth
  produced no different plan.

Verdict shape: `agent-effort-xhigh-restore: <Δ escaped defects>, <Δ tokens>, <Δ
wall-clock> → <justified | not justified> in a real CLI run`.
