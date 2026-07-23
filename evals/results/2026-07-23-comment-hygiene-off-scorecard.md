# Scorecard — comment-hygiene-off ablation A/B (2026-07-23)

Ablation of the 2026-07-23 comment-hygiene strengthening. Variant:
`evals/variants/comment-hygiene-off.md` — reverts the coder `<comment-policy>` to
its short (pre-change) form and drops the reviewer comment-hygiene lens, isolating
only the *added* rule classes (dead code, meta/process comments, orphan TODO/FIXME,
attribution/date, stale-comment rule).

- Command: `/workflow-eval --variant comment-hygiene-off` (discriminating probe).
- Method: task 17 scores only the *original* rules (kept under both conditions), so
  a task-17 A/B is null by construction. Used the probe the variant file defines —
  an edit/refactor that baits the added classes: *change `calc.Sum` to accumulate
  into `int64` and return `int64`; a rounding mode is planned but out of scope.*
  This tempts a commented-out old `Sum` (dead code), a `// changed to int64…`
  meta line, and a `// TODO: rounding mode` orphan marker.
- Both conditions: same probe, isolated `fixtures/base` copy, `coder` implement →
  objective diff scan for added-class noise. `--repeat 1`.

## Result — the probe elicited no noise from EITHER condition

| Condition | Build/test | Added-class noise (dead code / meta / TODO / attribution) | Tokens |
|---|---|---|---|
| full policy (baseline) | green | **none** | 18,084 |
| comment-hygiene-off (variant) | green | **none** | 18,273 |

Both diffs are near-identical and clean. Both updated `Sum`'s doc comment to a
2-line WHY (the overflow rationale — on-policy under both). Neither left the old
`int` body commented out, neither added a `// changed…`/process line, neither
dropped a `// TODO: rounding mode` despite the out-of-scope hook explicitly
inviting one. Deterministic `grep` for the added-class patterns: 0 hits both sides.

## Ablation verdict

`comment-hygiene-off: 0 Δ escaped hygiene defects, ~0 Δ tokens (variant +189, within
noise) → the added comment-hygiene classes are NOT shown to pay on this probe (n=1).`

**Read honestly:** this is a *null*, not a refutation. The probe failed to make
*either* condition emit the noise — at this model tier the coder writes clean
comments unprompted here, so the guardrail had nothing to suppress and the reviewer
lens nothing to catch. The rules' original justification is a live user report of
the noise occurring in practice (agents/coder.md ledger row); a single controlled
run with a capable model did not reproduce it, so this A/B provides **no positive
evidence** for the added classes — but also no evidence they cost anything (token
delta is noise, and the rules are ~one sentence + one review lens).

## Ledger disposition

The `Coder comment-policy bullet + reviewer comment-hygiene lens` row stays
**candidate**. The variant now exists (was "needs variant"); the n=1 A/B is
inconclusive-null. Owed to close either way:
- higher `--repeat`, and/or a **stronger elicitation** that reliably reproduces the
  reported noise — e.g. a multi-turn refine where a prior approach exists to leave
  commented out, or a noisier/faster model tier (haiku) as the coder;
- if repeated elicitation still can't make the *off* condition emit noise that the
  *on* condition suppresses, the honest conclusion is that the added classes are
  belt-and-suspenders on current models and the row should be reconsidered for
  simplification — evidence over intuition.
