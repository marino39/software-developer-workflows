# Variant — single-lens-review

Ablates Channel C's three-lens split (C1 shallow bug scan / C2 git history / C3
compliance) down to one thorough reviewer, to measure whether lens diversity earns
its extra fan-out.

## Delta (prepended to the dispatched /new-task)

> VARIANT single-lens-review: In Phase 6 step 3 Channel C, dispatch **one**
> `reviewer` that covers correctness, git-history context, and CLAUDE.md compliance
> together, instead of three parallel lens reviewers. Consolidation, scoring, and
> the skeptic pass are unchanged.

## What to read from the A/B

- **No escaped defects** — does collapsing the lenses miss bugs the three-lens
  fan-out would have caught (esp. history- or compliance-only findings)?
- **Efficiency** — token/latency delta from three reviewers → one.

Verdict shape: `single-lens-review: <Δ escaped defects>, <Δ cost> → justified | not
justified on this suite`. Single-run variance applies — raise `--repeat` first.
