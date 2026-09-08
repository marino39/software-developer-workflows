# Variant — codex-astra-review-off

Ablates the flagship from the review channel: both arms pin a model, the variant arm
runs `gpt-5.6-sol` on **every** codex pass including the full-tier review channel,
where the flagship is now the applied default (relaxed 2026-09-08 — see
`docs/proposals/2026-09-07-codex-astra-model-allocation.md` R3, and the superseded
`codex-astra-review-on.md`, whose delta became the baseline).

This is the A/B that prices the relaxation. The claimed effect is ~2 points of extra
actionable bug coverage on ordinary review and ~20% on **cross-file** review; the
claimed cost is latency, review noise, and a metered flagship message. Applies to
every task reaching Phase 6.3 / `review-pr` R1 / `iterate` I2 (02, 04, 05, 06, 18, 21,
24). Task 24 (cross-slice contract) is the headline case — the suite's cross-file
diff, where the delta should be largest if it is real.

**Route-control this A/B.** The delta names the review channel, and the reduced tier
skips codex entirely in the in-loop commands — an un-pinned route can put the two arms
on different tiers and measure the tier, not the model. Pin the route and the tier so
both arms execute the pass under test.

## Delta (prepended to the dispatched command)

> VARIANT codex-astra-review-off: every codex pass runs `--model gpt-5.6-sol -c
> model_reasoning_effort=high`, the review channel included — no flagship pass, no
> advantage-driven tier assignment, no cap to apply. The root-cause rung, if it fires,
> also runs `gpt-5.6-sol`. Everything else is unchanged.

## What to read from the A/B

- **Δ unique findings, split cross-file vs single-file** — the headline. A baseline
  gain concentrated on cross-file diffs matches the claim; a uniform gain across both
  is measuring effort, not model, and a null at n≥3 says `gpt-5.6-sol` should be the
  default everywhere and the relaxation reverts.
- **Δ false positives** — baseline-arm findings the batched skeptic refutes or that
  score `<50` in consolidation. The flagship's reported weakness is review noise; a
  detection gain paid for entirely in refuted findings is not a gain.
- **Δ review wall-clock** — the flagship at `xhigh` is the slowest configuration in the
  suite and Phase 6 holds the loop open. Report per-iteration latency in both arms.
- **Cap and quota behavior** — in the baseline arm, count flagship passes per run and
  whether the soft cap of two ever bound. A cap that never binds is not yet earning its
  ledger row; a cap that binds often means the ladder, not the cap, is mis-set. Any
  `codex: capped → …` or `codex: downshifted (quota) → …` line must show the pass
  continuing, never a halted barrier.

Verdict shape: `codex-astra-review-off: <Δ unique findings cross-file/single-file>,
<Δ refuted>, <Δ review wall-clock>, <flagship passes/run, cap bound n>`.
