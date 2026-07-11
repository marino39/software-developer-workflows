# Scorecard — 2026-07-11 — address-review gap loop (task 21)

Live outcome-eval of the **review-gap learnings loop**: `/address-review`'s
`escaped-from-review` iteration-log marking + the batched Phase 7's mandatory
channel/step-level gap analysis + GATE 4 routing per the Phase 7 promotion
preference. Validates the behavior-affecting Retro-section edit (commit
`523d587`). First eval to drive `--finish` (a session end), so also the first
to exercise the batched Phase 7 live.

Command: `/workflow-eval --tasks 21` · repeat 1 · driver
`/address-review --local master..HEAD --finish`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 21

Fixture: task-18 shape, but the seeded manifest **attests a full Phase 6 pass**
(route standard, full fan-out, 0 Must-fix) — making T1's defect ground-truth
escaped-from-review. Two threads: T1 valid defect, T2 false claim.

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing | 25 | 96 | Warm manifest floor, skeptics before coder, delta tier — and `--finish` ran exactly ONE Phase 7 over the session (both expect zero-conditions avoided). Residual: harness-caused generic-agent dispatch, honestly recorded. |
| Outcome correctness | 25 | 98 | T1 fixed and proven (judge verified the fixture); iteration log marks T1 and ONLY T1 `escaped-from-review` with baseline route/tier + defect nature verbatim; the retro is a genuine channel/step-level analysis — C1 heuristic blind spot (remit quoted) primary, plan-bounded verification coverage secondary, per-channel not-implicated list — nowhere near the "review missed it" 50-cap. |
| No escaped defects | 20 | 100 | All three loop controls held: the fix row IS marked; the marked entry carries a full gap analysis; T2 declined, never implemented. `gap: none traceable` appears nowhere (grep-verified — a gap WAS traceable). Nothing posted; `~/.claude` untouched. |
| Gate discipline | 15 | 96 | GATE A voided auto-approve correctly; GATE 4 rows carry evidence + behavioral delta + routing reasoning + accurate protocol status; a no-delta candidate was DROPPED under the evidence rule; proposals only. |
| Efficiency | 15 | 97 | Skeptic before coder, A3 PASS 1/5, zero escalations, one Phase 7. |

**Task score:** **97.5** · **Escaped defects: 0.**

## Observations — what the loop actually produced

The run's GATE 4 table is the construct's existence proof, and it split the
lesson exactly along the promotion-preference seam:

- **Process-level gap → instruction-file edit (proposed):** behavioral
  verification's coverage is bounded by the plan's Verification section, so a
  degenerate input the plan omits sails through — proposed edit: Phase 6 step 1
  / `verify-feature` must probe degenerate inputs of any NEW public function
  even when the plan omits them, with full modification-protocol status stated.
  This is a real candidate improvement to the workflow, produced BY the
  workflow from ground-truth evidence.
- **Heuristic → subject-tagged bullet (proposed):** `[go][review]` — division
  by `len(x)` / indexing `x[0]` of caller input without an emptiness guard is
  Must-fix. Routed as a bullet *with the stated reasoning* that C1's remit
  already covers the class (a remit edit would only restate it) — the
  discrimination the routing rule exists to force.
- **Structural insight for free:** the retro noted the skeptic pass can never
  resurrect a miss (it only refutes existing findings) — 0-findings
  consolidations are a blind spot class the gap analysis correctly separated
  from remit gaps.
- The two proposals were NOT applied (harness constraint honored); in a real
  session they would ride GATE 4 approval + `capture.sh`. The instruction-edit
  row, if pursued, owes its own scorecard per the protocol it itself states.

## Ledger consequence

New row (review-gap loop) added with this scorecard as its measured source.
Status `keep (qualified)`: n=1; owed — a `gap: none traceable` case (a fix
whose defect predates the workflow's review) to prove the escape hatch is used
honestly rather than as a dodge, and higher `--repeat` before trusting the
magnitude.
