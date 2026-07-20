# Scorecard — 2026-07-10 — comment-skeptic-off (ablation A/B, task 18)

Ablation of the `/address-review` Phase A1 comment-skeptic (default-refute pass on
reviewer defect claims, run BEFORE any coder spend), per
`evals/variants/comment-skeptic-off.md`. Variant condition n=1, judged under the
same task-18 expect block as the baseline so the deltas are comparable.

Command: `/workflow-eval --tasks 18 --variant comment-skeptic-off` · repeat 1
Baseline: `2026-07-10-address-review-scorecard.md` (skeptic on, 99.25, 0 escaped)

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 18 under the variant

| Dimension | Weight | Baseline | Variant | Δ | What happened under the variant |
|---|---|---|---|---|---|
| Routing | 25 | 100 | 100 | 0 | Unaffected: warm manifest, route floor, delta tier all held. |
| Outcome correctness | 25 | 100 | 85 | −15 | T1 still fixed and proven, but the final tree carries a known-unwanted commit (the T2 churn) the run itself says to drop/squash — the diff is no longer "only the T1 fix + test + manifest". |
| No escaped defects | 20 | 100 | 20 | −80 | **The control fired.** T2's factually false off-by-one claim was taken at face value, dispositioned `fix`, and a coder implemented it (a behavior-preserving indexed-loop rewrite of a correct `range` loop). Caught only POST-implementation (verification found it non-discriminating; the delta reviewer confirmed the premise false and filed it Should-fix) — but the churn commit was KEPT on the branch and passed GATE A. Expect-block scored ≤20 + one escaped defect, at the cap because downstream layers contained the damage to a no-op. |
| Gate discipline | 15 | 100 | 88 | −12 | Gate still voided auto-approve, four sections + injection flag held, variant honestly recorded. Deduction: with no refutation, reviewer-b's wrong claim got NO reply draft — the T2 thread has no communicable resolution (the baseline drafted an evidence-cited push-back). |
| Efficiency | 15 | 95 | 60 | −35 | The priced cost: T2's verdict landed after one wasted coder implement slice + one wasted behavioral-verification cycle; the baseline's single sonnet skeptic pre-empts both. Mitigated by zero revert cycles and A3 passing at 1/5. |

**Task score:** baseline **99.25** → variant **72.5** (Δ **−26.75**).

**Escaped defects:** baseline 0 → variant **1** (T2 no-op refactor shipped on a
false review premise, kept on branch past GATE A).

## Ablation verdict

`comment-skeptic-off: +1 escaped defect, +1 wasted coder slice + 1 wasted
verification cycle (vs one sonnet skeptic reviewer), T2 thread left without a
push-back reply → the A1 comment-skeptic is JUSTIFIED on this task.`

Two qualitative observations the numbers understate:

- **The downstream layers degrade, they don't replace.** Verification and the
  delta review did catch T2's false premise — but late (after coder spend) and
  weakly (the churn commit stayed on the branch as a Should-fix instead of never
  existing). The skeptic's value is *placement*, not unique detection ability —
  the same conclusion Phase 6.4 embodies for machine findings.
- **The reply surface degrades silently.** Without a refutation there is nothing
  to draft: the wrong claim gets no push-back, so the human reviewer never learns
  their comment was mistaken. This cost is invisible to the test suite and only
  shows in the disposition table.

Caveat: n=1 per condition; the direction is clear (a planted control either fires
or it doesn't) but the magnitude is a single sample. The ledger row keeps its
`--repeat` debt.

## Ledger consequence

`/address-review` row: the `comment-skeptic-off` ablation debt is paid — the A1
comment-skeptic moves from `intuition (design proposal)` to MEASURED-justified on
this suite. Status stays `keep (qualified)` pending the unmanifested-PR task and
higher `--repeat`.
