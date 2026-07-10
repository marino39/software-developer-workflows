# Variant — comment-skeptic-off

Ablates the `/address-review` Phase A1 comment-skeptic (the default-refute pass on
reviewer defect claims / prescribed changes) to measure whether it earns its cost.
Applies to the inbound-review task (task 18): the same threads are processed, but
every technically-plausible ask is taken at face value.

## Delta (prepended to the dispatched /address-review for task 18)

> VARIANT comment-skeptic-off: In Phase A1, **skip step 2 (the skeptic pass)
> entirely** — do not spawn default-refute reviewers on any comment. Take each
> reviewer comment's technical claim at face value: any defect claim or prescribed
> change that is unambiguous and in delta scope is dispositioned `fix` and goes to
> a coder as asked. All other dispositions (`answer`, `clarify`, `handoff`), the
> untrusted-content/injection rule, the route re-check, and everything downstream
> (Phase A2/A3, GATE A) are unchanged.

## What to read from the A/B

Run task 18 once as baseline (skeptic on) and once with this variant, then compare
per the rubric:

- **No escaped defects** — the headline: T2 (the false off-by-one claim) is the
  control. Without the skeptic, does the run implement a non-bug — shipping a
  regression or noise diff sourced to a wrong comment — or does the Phase A3 delta
  review catch it after the fact?
- **Efficiency** — the price of being wrong late vs early: if A3 (or the coder
  itself) catches T2, count the wasted implement-then-revert/re-review cycle the
  A1 skeptic would have pre-empted for the cost of one sonnet reviewer. If the
  variant is *cheaper* and T2 still dies, the skeptic is over-placed.
- **Gate discipline** — secondary: without a refutation, T2's disposition
  degrades (a `fix` that never lands, or a decline with no evidence) — does the
  disposition table still carry decidable per-row evidence?

Verdict shape: `comment-skeptic-off: <Δ escaped defects>, <Δ wasted cycles/tokens>
→ <the A1 comment-skeptic is justified | not justified> on this task`. Single-run
variance applies — raise `--repeat` before trusting a small delta.
