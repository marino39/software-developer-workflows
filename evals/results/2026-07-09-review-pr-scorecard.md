# Scorecard — 2026-07-09 — review-pr (task 06)

Live outcome-eval of the new `/review-pr` command against its frozen fixture
(`evals/tasks/06-review-pr.md`). First `/review-pr` run — establishes the baseline
for this command; not comparable to the `/new-task` suite scorecards (different
driver, different acceptance check).

Command: `/workflow-eval --tasks 06` · repeat 1 · driver `/review-pr --local HEAD~1..HEAD`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 06

Fixture: `fixtures/base` seeded into a two-commit git repo (base + a "PR" commit
hardening `auth.ValidateToken`). The diff touches `auth/` (high-stakes) and plants
one Must-fix (P1) the green CI misses, one Should-fix (P2), and a signature-change
bait that must be Rejected.

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing (tier) | 25 | 100 | Full tier selected on the auth diff with stated rationale (auth = high-stakes → full regardless of the 13/+7 lines). |
| Outcome correctness | 25 | 88 | Three sections + advisory present; P1 surfaced as Must-fix (survived skeptic); bait correctly Rejected (no false positive reached Must-fix, so the ≤60 clause did not trigger). −12: CI status conveyed inline under CHANNELS RUN rather than as a distinct `ci:` field. |
| No escaped defects | 20 | 100 | P1 caught as Must-fix; P2 caught; bait rejected. Zero seeded defects missed or demoted below their required tier. |
| Gate discipline | 15 | n/a | Local mode has no gates — renormalized away. |
| Efficiency | 15 | 100 | Full tier run once; codex skipped (not installed) not forced; no needless model escalation; within the shared fable budget. |

**Task score (renormalized over 85):** (100·25 + 88·25 + 100·20 + 100·15) / 85 = **96.5**

**Escaped defects: 0.**

## Suite

Suite score (this run, 1 task): **96.5**. Baseline established for `/review-pr`; no
prior `/review-pr` scorecard to diff against.

## Observations

- **P2 severity drift (not a defect):** the engine placed P2 (length cap on
  `len(header)` not the token) at Must-fix (confidence 82) rather than the fixture's
  expected Should-fix. It is a genuinely real bug that contradicts the stated intent,
  so this is a severity-placement call, not a false positive and not an escape — the
  judge scored it as caught. If `/review-pr` runs later show a pattern of inflating
  real-but-minor findings to Must-fix, tighten the consolidator's confidence bands;
  one run is not evidence of that.
- **CI field looseness:** the run reported `ci: green` but under CHANNELS RUN, not as
  a first-class field. Candidate one-line tightening to `commands/review-pr.md` R3 to
  require `ci: <state>` as its own report line — not made now (single-run, cosmetic).

## Verdict

The decoupled Phase 6 engine works on a foreign diff: it picked the correct
(high-stakes) tier, caught the CI-green Must-fix, rejected the plant-bait via the
skeptic pass, and stayed read-only. The ledger row's owed evidence (finding recall +
post-skeptic false-positive rate) is now satisfied for n=1 — recall 2/2 real defects,
0 false positives past the skeptic. Raise `--repeat` before treating the 96.5 as
anything but a single-sample point.
