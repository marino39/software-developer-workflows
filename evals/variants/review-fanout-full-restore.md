# Variant — review-fanout-full-restore

**Reverse ablation.** The 2026-08-11 cost pass cut the Phase 6 / `/review-pr` review
engine from {Channel A superpowers review + Channel B codex + C1/C2/C3 lens
reviewers + a consolidator subagent + one skeptic per Must-fix finding} down to
{one Claude `reviewer` carrying the merged four-lens remit + codex, consolidated
orchestrator-side, with one batched skeptic}. This variant **restores the pre-cut
engine** so the quality half of that trade can be measured.

Supersedes `single-lens-review.md`, whose delta ("one reviewer covering all three
lenses") is now the baseline.

## Delta (prepended to the dispatched /new-task or /review-pr)

> VARIANT review-fanout-full-restore: In Phase 6 step 3 (and `/review-pr` R1),
> restore the pre-2026-08-11 fan-out. Run **Channel A** as the
> `superpowers:requesting-code-review` skill's reviewer subagent (DESCRIPTION,
> PLAN_OR_REQUIREMENTS, BASE_SHA, HEAD_SHA), **Channel B** as codex per the
> `codex-exec` skill, and **Channel C** as three parallel `reviewer` subagents —
> C1 shallow bug scan (changes only, no extra context), C2 git history
> (blame/history of the modified code), C3 compliance (CLAUDE.md files covering the
> modified dirs + code comments in modified files). Then run step 4's consolidation
> in a **FRESH `reviewer` subagent** (clean context, fed only the channel reports +
> the plan path) rather than orchestrator-side, and run the skeptic pass as **one
> fresh parallel `reviewer` per Must-fix finding** rather than one batched pass.
> Scoring thresholds, the computed verdict, and everything outside Phase 6 step 3–4
> are unchanged.

## What to read from the A/B

- **Escaped defects, by lens class.** The headline number is total escapes, but the
  diagnostic is *which* lens caught what: history-only findings (C2) and
  compliance-only findings (C3) are the two classes a merged remit is likeliest to
  under-weight, because one reviewer under a ~300-word cap spends its budget on the
  loudest lens. An equal total with a shifted class mix is still a finding.
- **False-positive rate past the skeptic.** Batching gives the skeptic one shared
  context over all Must-fix findings — cheaper, but it risks anchoring (finding 3
  judged in light of 1–2), which per-finding isolation prevented by construction.
  Count findings that flip verdict between arms.
- **Consolidation fidelity.** Orchestrator-side merging is the one step that moved
  *into* the expensive context. Check the context trace: if consolidation is pulling
  diff or source content in to adjudicate findings, the subagent should come back
  regardless of the defect numbers.
- **Cost** — 6+K Claude dispatches per review iteration vs 1 Claude dispatch + 1 free
  codex pass + 1 batched skeptic. This is the largest recurring cost delta in the
  workflow, and it is paid on every review iteration of every run.

Run it on the review-heavy tasks (02, 06, 24) at `--repeat ≥ 3`; single-run variance
on defect counts is high. Verdict shape: `review-fanout-full-restore: <Δ escaped
defects, by lens class>, <Δ false positives>, <Δ cost> → the 2026-08-11 cut is
<safe | a quality regression | safe except on high-stakes>`.
