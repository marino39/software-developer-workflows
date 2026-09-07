# Variant — codex-skeptic-batched-on

Tests R6 of `docs/proposals/2026-09-07-codex-astra-model-allocation.md`: replacing
`/address-review`'s per-item Claude skeptic fan-out (A3: "one fresh parallel
`reviewer` per item, default-refute") with ONE batched out-of-model pass — the same
move Phase 6 already made when per-finding skeptics became one batched dispatch.

Applies to `/address-review` tasks: 18, 19, 21. The comparison is only meaningful
where A3 sees ≥3 candidate items; report smaller runs separately.

**Control the item set.** The delta names A3, which only exists once threads have been
ingested, and its cost case scales with item count — so both arms must run the same
seeded thread set. An arm with fewer candidate items measures the seed, not the pass.

## Delta (prepended to the dispatched /address-review)

> VARIANT codex-skeptic-batched-on: A3's per-item `reviewer` fan-out is replaced by
> ONE batched codex pass per the `codex-exec` skill (`--model gpt-5.6-sol -c
> model_reasoning_effort=high`, `--sandbox read-only`), given all candidate items at
> once with the same default-refute instruction and the same per-item output shape;
> consolidation stays orchestrator-side. Items whose claim turns on repo convention,
> plan intent, or `CLAUDE.md` compliance still go to a Claude `reviewer` — codex does
> not carry that context. Codex unavailable or quota-exhausted → the full Claude
> fan-out is the named fallback, recorded as a Deviation.

## What to read from the A/B

- **Δ Claude dispatches per run** — the cost case: N per-item skeptics → 1 codex pass
  plus the repo-context remainder. Report the remainder count; if most items route
  back to Claude anyway, the split is not paying.
- **Disposition agreement** — per item, does the batched codex verdict match the
  per-item Claude verdict? Count disagreements in both directions. A **refute** the
  Claude arm accepted is the expensive error (a real reviewer ask silently dropped),
  and `/address-review` gates every reply behind the disposition table, so a wrong
  disposition reaches a human reviewer. Weight it accordingly.
- **Batching loss** — does one pass over N items degrade per-item reasoning versus N
  passes over one? The failure signature is short, undifferentiated verdicts late in
  the list.
- **Δ wall-clock** — one 10-min codex pass versus N parallel Claude dispatches. The
  Claude fan-out is parallel, so the batched pass may well be *slower*; this is a
  cost-vs-latency trade, and the verdict must state which one the run was short of.

Verdict shape: `codex-skeptic-batched-on: <Δ Claude dispatches>, <disposition
agreement n/N, wrong-refutes>, <Δ wall-clock>`.
