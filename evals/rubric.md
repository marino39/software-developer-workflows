# Eval scoring rubric

The shared scoring contract for both regression tracking and ablation A/B. A
judge subagent scores each eval run's collected artifacts — the structured gate
summaries, the Phase 7 retro, and the final fixture diff + `go test` result —
against the five dimensions below. Score each 0–100; the task's `expect` block
may override weights or mark a dimension `n/a`.

Default weights (sum 100):

| Dimension | Weight | 100 means | 0 means |
|---|---|---|---|
| **Routing** | 25 | Landed on the task's expected route, including any expected self-correction, with a stated rationale at the first gate. | Wrong route, or a required re-classification never happened. |
| **Outcome correctness** | 25 | Fixture ends as the task specifies (build green; target test green; bug provably fixed per `verify-fix`). | Fixture left broken or the change does not meet the task's acceptance check. |
| **No escaped defects** | 20 | Every seeded/expected issue was caught in review; zero Must-fix findings escaped to GATE 3. | A real defect shipped past review. |
| **Gate discipline** | 15 | Gate summaries well-formed (Results / Key decisions / Deviations / Next) AND decidable — each gate's Results carry the decision evidence the human needs (route rationale at the first touchpoint; GATE 1 review outcome; GATE 2 mapping table; GATE 4 per-item evidence + behavioral delta); deviations recorded honestly; auto-approve used only when its criteria held. | Missing/garbled summaries; a decision asked with its supporting evidence absent or left as a bare artifact/diff reference; silent deviations; auto-approve on unmet criteria. |
| **Efficiency** | 15 | Iterations within caps; escalations used only when warranted; token/wall-clock in the expected band. | Cap exhaustion, needless escalations, or large cost overrun. |

## Scoring guide

- Score from evidence in the artifacts, not intuition. If an artifact needed to
  judge a dimension is missing, score that dimension ≤ 25 and note it.
- **Escaped defect** = a finding that a later review round or the fixture test
  proves was real but that GATE 3 passed without addressing. This is the most
  severe failure class — weight it accordingly in the summary verdict even when
  the numeric score is a blend.
- A task's `expect` block is authoritative where it conflicts with the defaults
  (e.g. task 01 marks *No escaped defects* `n/a` and reweights).

## Aggregation

- **Task score** = weighted mean of its dimensions (skipping `n/a`, renormalizing).
- **Suite score** = unweighted mean of task scores.
- **Regression** = any dimension dropping > 10 points vs the baseline scorecard, OR
  any new escaped defect. Regressions are listed explicitly, never averaged away.
- **Ablation verdict** (per `--variant`): report the per-dimension delta vs the
  baseline and a one-line judgement of whether the removed layer earned its cost
  on this suite (e.g. quality unchanged + cost down → *not justified here*).
