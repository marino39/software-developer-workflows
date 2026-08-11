# Variant — codex-reduced-off

Ablates proposal P3 in `/review-pr`: the reduced tier goes back to Channel A
alone (codex skipped on small diffs), measuring whether the second channel earns
its wall-clock on exactly the diffs the tier logic calls low-risk. Applies to
`/review-pr` runs whose diff picks the reduced tier (task 06 with a trimmed
fixture diff, or any small-PR case); full-tier runs are inert here. The in-loop
commands (new-task Phase 6, iterate I2) keep the skip in BOTH arms — this
variant isolates the command-gated half of the rule.

## Delta (prepended to the dispatched /review-pr)

> VARIANT codex-reduced-off: Treat R0.5's both-tiers codex rule as absent — the
> reduced tier runs Channel A alone and records `codex: skipped (small diff)`,
> exactly per new-task.md Phase 6 step 2. Everything else is unchanged.

## What to read from the A/B

- **Δ findings on small diffs** — the headline: findings the codex channel
  surfaced that Channel A missed, plus cross-channel confirmations that bumped
  a finding's confidence past a tag threshold (Should-fix → Must-fix). Zero at
  n≥3 → the skip never cost quality and P3 reverts; recurring uniques → codex
  pays on small diffs too.
- **Wall-clock** — the only cost axis (codex is off the Claude bill): report
  per-run review latency in both arms.
- **Degrades-free honesty** — in the both-tiers arm a codex error/timeout must
  be recorded as skipped and never hold consolidation; an arm that waits on a
  dead codex has re-imported the old stdin/timeout failure, not measured the
  channel.

Verdict shape: `codex-reduced-off: <Δ unique + confirming findings>,
<Δ wall-clock>, <degrades-free held y/n>`.
