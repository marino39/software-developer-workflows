# Variant — codex-astra-review-on

Tests R1–R3 of `docs/proposals/2026-09-07-codex-astra-model-allocation.md`: pinning
the review Channel B model and escalating it to `gpt-6-astra` on the diffs the vendor
evidence says predict the gap. Baseline arm pins `gpt-5.6-sol`; variant arm escalates
to Astra on cross-file / high-stakes diffs. **Both arms pin a model** — an arm that
inherits the CLI default measures whatever the CLI last shipped, not the change.

Applies to every task whose run reaches Phase 6.3 / `review-pr` R1 / `iterate` I2
(02, 04, 05, 06, 18, 21, 24). Task 24 (cross-slice contract) is the headline case —
it is the suite's cross-file diff, where the claimed delta is largest.

**Route-control this A/B.** The delta names the review channel and the cross-file /
high-stakes escalation trigger, and the reduced tier skips codex in the in-loop
commands entirely — so an un-pinned route can put the two arms on different tiers and
measure the tier, not the model. Pin the route and the tier so both arms actually
execute the pass under test.

## Delta (prepended to the dispatched command)

> VARIANT codex-astra-review-on: pin the codex model on every pass —
> `codex exec --model <M> -c model_reasoning_effort=<E>`. **Baseline arm:** every
> pass runs `M=gpt-5.6-sol`, `E=high`. **Variant arm:** the review Channel B pass
> runs `M=gpt-6-astra`, `E=xhigh` when the diff touches ≥2 interdependent files OR
> the route is high-stakes OR the same issue survived 2 iterations; every other codex
> pass still runs `gpt-5.6-sol`/`high`. At most ONE Astra pass per run. Record the
> served model in the run ledger next to `codex: ok`. Everything else unchanged.

## What to read from the A/B

- **Δ unique findings, split cross-file vs single-file** — the headline. The vendor
  claim is +20% actionable bug coverage over Sol on cross-file reviews and ~parity
  elsewhere; a variant arm that gains uniformly across both is measuring something
  other than the claimed effect (suspect effort, not model). Zero cross-file delta at
  n≥3 → Sol is the right default everywhere and the Astra rung does not pay.
- **Δ false positives** — count variant-arm findings the batched skeptic refutes or
  that score `<50` in consolidation. Astra's reported weakness is review noise; a
  detection gain paid for entirely in refuted findings is not a gain.
- **Δ wall-clock on the review barrier** — Astra at `xhigh` is the slowest
  configuration in the suite and Phase 6 holds the loop open. Report per-iteration
  review latency in both arms.
- **Quota accounting** — messages spent per run in each arm, and whether the
  one-Astra-per-run budget ever bound. A budget that never binds is not yet earning
  its ledger row.

Verdict shape: `codex-astra-review-on: <Δ unique findings cross-file/single-file>,
<Δ refuted>, <Δ review wall-clock>, <Astra messages/run>`.
