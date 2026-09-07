# Variant — codex-review-remit-split

Tests R7 of `docs/proposals/2026-09-07-codex-astra-model-allocation.md`: re-weighting
the two review channels by comparative advantage instead of duplicating the bug-scan
lens across both. Today Channel A (one Claude `reviewer`) carries plan compliance ·
bug scan · git history · `CLAUDE.md` compliance, and Channel B (codex) also runs a
bug scan — so the duplicated lens sits on the weaker side, while the three lenses
codex structurally cannot do well share a ~500-word budget with it.

Applies to every task reaching Phase 6.3 / `review-pr` R1 / `iterate` I2 (02, 04, 05,
06, 18, 21, 24).

**Route-control this A/B.** The delta names Phase 6's channel remits, and the reduced
tier changes which channels run at all — pin the route and the tier so both arms
review the same diff through the same number of channels.

## Delta (prepended to the dispatched command)

> VARIANT codex-review-remit-split: Channel A's merged remit is re-weighted, not
> reduced — it LEADS on plan compliance, `CLAUDE.md`/convention compliance and git
> history (the lenses that need the plan, the repo conventions and the history), and
> keeps the bug scan as an explicit SECONDARY lens reported after the other three.
> Channel B's codex prompt leads on correctness and cross-file bug scan. Both
> channels still report PER LENS, naming each lens and its findings or `none` — an
> unreported lens must never read as clean to consolidation. Consolidation,
> confidence scoring and the batched skeptic are unchanged.

## What to read from the A/B

- **Δ findings on the three repo-context lenses** — the case for the change: does
  giving plan compliance, conventions and git history the front of Channel A's budget
  surface findings the merged-equal remit missed? These are the findings codex cannot
  produce at all, so a loss here is unrecoverable by the other channel.
- **Δ bug-scan recall** — the risk: demoting the bug scan to secondary on Channel A
  must not open a hole. Measure escaped defects (the rubric's headline) and, on
  single-file diffs specifically, where Channel B's advantage is smallest.
- **Cross-channel confirmation rate** — how often both channels independently flag
  the same defect. The duplicate-lens design buys those confirmations (they bump
  confidence past the Should-fix → Must-fix threshold); the split trades some away.
  Report the count in both arms, not just the uniques.
- **Per-lens reporting discipline** — count runs where a lens went unreported in
  either arm. The merged remit's known failure mode is one lens consuming the whole
  budget; a re-weighted remit could make that worse, not better.

Verdict shape: `codex-review-remit-split: <Δ repo-context findings>, <Δ escaped
defects>, <Δ cross-channel confirmations>, <lenses dropped n>`.
