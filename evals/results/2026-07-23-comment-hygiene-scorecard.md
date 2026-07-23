# Scorecard — strengthened comment hygiene (2026-07-23)

Behavior-affecting change under test:
- `agents/coder.md` `<comment-policy>` extended with the agent-noise classes:
  no commented-out/dead code, no meta/process comments (referencing the task,
  plan, PR, review, or that code was added/changed/fixed), no orphan TODO/FIXME
  (needs a real issue ref), no attribution/changelog/date comments, and a
  stale-comment rule (update or delete a now-inaccurate comment in the edited hunk).
- `agents/reviewer.md` check (3) gains an explicit comment-hygiene lens covering
  the same classes, so violations are caught at review, not only discouraged at
  authoring.
- Ledger row updated to the expanded scope + reviewer enforcement.

- Command: `/workflow-eval --tasks 17` (the directly-affected frozen task).
- Method: exercised the affected lifecycle slice directly — `coder` implement →
  `reviewer` review (with the new lens) → fresh `reviewer` judge — on an isolated
  copy of `fixtures/base`. Not a full `/new-task` run (the remote harness makes a
  faithful full-lifecycle dispatch unreliable), so there are no GATE summaries;
  the judge scored Gate discipline `n/a` and reweighted. This mirrors the
  2026-07-10 comment-policy baseline's single-task, comment-focused scope.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (reference integrity ×2, route/tier,
phase completeness, gate-format, agent contracts, complexity ledger, learnings
bullets). Exit 0.

## Layer 2 — outcome-eval

| Task | Routing | Outcome | No-escaped-defects (comment lens, primary) | Gate | Efficiency | Task score | Escaped |
|---|---|---|---|---|---|---|---|
| 17 comment-discipline | 95 | 100 | 95 | n/a | 85 | **≈95** | 0 |

Suite score (this run): **≈95** (single task, `--repeat 1`).

Cost (usage trailers, two separately-metered subagents): coder 18.6k tok / 7
tool-uses / 36.8s; reviewer 13.5k tok / 2 tool-uses / 13.0s.

### Comment-discipline verdict (the point of this run)

The strengthened policy held with no removal pass and no over-firing:

- Exported `Median` → **one-line** doc (`// Median returns the median of xs, or 0
  for an empty slice.`) — within the ≤~3-line cap, matches peer `Sum`.
- Unexported `sortedCopy` → **no doc comment** — private-default-none held.
- Function bodies → **zero inline narration**; no dead code, no meta/process
  comment, no TODO/FIXME, no attribution/date line — the new rule classes all held.
- WHY escape hatch not needed (no borderline step) → neither over- nor under-fired.
- **Reviewer's new lens did not false-positive**: PASS, no issues, and it
  explicitly reported checking the new classes (dead code, meta/TODO comments)
  against the clean diff. This is the enforcement half of the change working
  without punishing on-policy code.

None of task 17's three ≤40 penalty triggers fired.

## Regression

Baseline: `2026-07-10-comment-policy-scorecard.md` (task 17, **99.25**).

- **No new escaped defects** (0 both runs) and **no behavioral regression** in the
  dimension the change targets: the comment-discipline lens scored 95 vs the
  baseline's 100 with identical on-policy output — a judge-instance/annotation
  conservatism gap, not a change in what the coder emitted.
- The **Efficiency 100→85** and **Routing 100→95** deltas are **methodology
  artifacts, not regressions**: this run metered two standalone subagents and had
  no gate machinery to score, whereas the baseline scored a full `/new-task`
  usage trailer with gates. Cost per the trailers is in-band for a small additive
  feature. No dimension dropped for a reason attributable to the policy edit.
- Scope note (honest, same caveat as the 2026-07-10 baseline): only the
  directly-affected task was run. The other frozen tasks' `expect` blocks don't
  assert on comments, so the policy is not expected to move their dimensions; the
  reviewer-lens addition is additive (a new thing to flag, not a changed verdict
  rule) and the run confirms it does not false-positive on clean code. A
  full-suite sweep was not run this pass.

## Ledger

The `Coder comment-policy bullet + reviewer comment-hygiene lens` row stays
`candidate` (needs an ablation variant to fully close). This run is the regression
+ enforcement evidence, not the A/B — an `evals/variants/comment-hygiene-off`
delta and a `--variant` A/B are still owed to price the layer.
