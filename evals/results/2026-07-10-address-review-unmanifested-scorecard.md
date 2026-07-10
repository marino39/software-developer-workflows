# Scorecard — 2026-07-10 — address-review unmanifested (task 19)

Live outcome-eval of `/address-review`'s Phase A0 **no-manifest branch** against
`evals/tasks/19-address-review-unmanifested.md` — a hand-authored PR with no run
manifest, so the run must derive an intent digest, route the diff itself, record
`baseline: unmanifested`, and write a fresh run manifest on completion.

Command: `/workflow-eval --tasks 19` · repeat 1 · driver `/address-review --local master..HEAD`
Related: `2026-07-10-address-review-scorecard.md` (task 18, the manifested path, 99.25).

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 19

Fixture: `fixtures/base` seeded into a two-commit history (base + a hand-authored
`calc.Average` PR with the live empty-slice defect), NO `docs/superpowers/`
directory; two thread controls (T1 valid defect, T2 false claim).

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing | 25 | 100 | No-manifest branch ran as designed: intent digest derived from the PR body per `review-pr.md` R0 (priority order stated), route `scoped` set from the diff with explicit rationale, `baseline: unmanifested` recorded, re-checked at A1.3/I2.1, no bounce, no fabricated manifest. |
| Outcome correctness | 25 | 97 | T1 fixed and proven (guard + nil/empty test, revert-discriminate PASS, suite green — judge verified the fixture live); fresh manifest written with branch, reviewed `HEAD_SHA`, and a full iteration-log entry. −3: the manifest labels the PR head at ingest as `BASE_SHA` rather than the merge base — disambiguated by a parenthetical, but the semantics could mislead a warm-start consumer. |
| No escaped defects | 20 | 100 | T2's false claim skeptic-refuted BEFORE any coder spend and declined with an evidence-cited reply draft (never implemented); T1 caught and fixed; nothing shipped past the gate. |
| Gate discipline | 15 | 100 | GATE A correctly voided auto-approve (decline row + pending reply, other criteria honestly noted green); four sections; Results carry the derivation, derived route + rationale, `baseline: unmanifested`, and the evidenced table; Deviations: none, truthfully. |
| Efficiency | 15 | 100 | Skeptics before coder; zero cold-lifecycle machinery; zero searcher/researcher with stated justification (under the allowed minimal dispatch); test runs on haiku; no escalations; iteration 1/5; fable budget unspent. |

**Task score:** (100·25 + 97·25 + 100·20 + 100·15 + 100·15) / 100 = **99.3**

**Escaped defects: 0.**

## Suite

Suite score (this run, 1 task): **99.3**. First run of the unmanifested path —
baseline established; the manifested path (task 18) scored 99.25, so the two
`/address-review` entry conditions are performing equivalently at n=1.

## Observations

- **The fresh manifest is real, not vestigial:** it carries the derived route +
  rationale, the intent digest, the reviewed head, and an iteration-log entry
  complete enough for a later `/iterate`/`/address-review` to warm-start from —
  the exact product the no-manifest branch exists to produce.
- **`BASE_SHA` labeling (candidate one-line tightening):** `new-task.md` run
  manifests record `BASE_SHA` = merge-base with the default branch; this run's
  fresh manifest recorded the PR head at ingest under the same field name (with a
  clarifying parenthetical). A one-line clarification in
  `commands/address-review.md`'s Retro section (e.g. record both `merge-base` and
  `ingest head`, distinctly named) would remove the ambiguity — not made now
  (single-run, cosmetic; same posture as the `/review-pr` ci-field observation).
- **Route divergence from task 18 is correct, not drift:** task 18 inherited
  `standard` from its manifest floor; here, with no floor, the diff itself routes
  `scoped` — both are the route model working as written.

## Verdict

The no-manifest branch holds: a hand-authored PR gets the same disposition
discipline (skeptic-before-coder, evidenced table, voided auto-approve) plus the
warm-start manifest as its product. With this and the `comment-skeptic-off` A/B,
the `/address-review` ledger row's owed evidence is paid except `--repeat` —
raise it before trusting any of the three magnitudes (99.25 / 72.5 / 99.3).
