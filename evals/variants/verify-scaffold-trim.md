# Variant — verify-scaffold-trim

Ablates the workflow's explicit verification scaffolding, to test Anthropic's Opus 5
guidance that instructions telling the model to verify now cause **over**-verification
and that "removing them reduces over-verification with no capability regression."
Queued, not applied: the same guidance is contradicted for Fable-tier models, which the
escalation ladder can put in these seats, and most of this scaffolding is read by
Sonnet agents rather than by Opus 5. See `docs/proposals/2026-09-07-opus5-fable51-model-tuning.md` F6.

## Delta (prepended to the dispatched /new-task)

> VARIANT verify-scaffold-trim: skip Phase 6 step 1's behavioral-verification pass
> entirely (record `verification: trimmed (variant)`), and drop the instruction to
> the `coder` to verify each step after implementing it — let it report when it
> judges the slice done. The PASS criterion becomes tests-green AND zero Must-fix,
> without the behavioral-verification term. Everything else — the skeptic pass, the
> `verify-fix` proof on bug fixes, the review loop — is unchanged.

## What to read from the A/B

- **No escaped defects** — the load-bearing dimension. Verification scaffolding that
  is genuinely redundant should cost nothing here; if defects escape, the model's
  unprompted self-verification is not covering what the explicit pass covered.
- **Efficiency** — tokens and iterations saved, and specifically whether trimming
  moves failures *later* (into the review loop or Phase 6.5 CI), where they cost
  more than the pass that was cut.
- **Gate evidence** — GATE 3 currently surfaces a per-item behavioral-verification
  result to the human. A trim that keeps quality but empties that gate field has
  traded human-decidability for tokens; score it under Gate discipline, not
  Efficiency.

Verdict shape: `verify-scaffold-trim: <Δ escaped defects>, <Δ tokens>, <Δ gate
discipline> → <justified | not justified> on this suite`. Single-run variance
applies — raise `--repeat` before trusting a small delta.
