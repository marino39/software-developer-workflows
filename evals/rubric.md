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
| **Efficiency** | 15 | Iterations within caps; escalations used only when warranted; orchestrator turns and token/wall-clock in the expected band (**Turn bands**, below). | Cap exhaustion, needless escalations, or large cost overrun. |

## Scoring guide

- Score from evidence in the artifacts, not intuition. If an artifact needed to
  judge a dimension is missing, score that dimension ≤ 25 and note it.
- **Escaped defect** = a finding that a later review round or the fixture test
  proves was real but that GATE 3 passed without addressing. This is the most
  severe failure class — weight it accordingly in the summary verdict even when
  the numeric score is a blend.
- A task's `expect` block is authoritative where it conflicts with the defaults
  (e.g. task 01 marks *No escaped defects* `n/a` and reweights).

## Turn bands (provisional)

Orchestrator turns multiply every other cost — each turn re-reads the whole context — and
nothing in the workflow bounds them, so the harness does. `evals/context-trace.sh` counts
turns exactly; the orchestrator is never asked to count its own (it cannot do so reliably
deep into a long context, and the instruction would itself cost prompt words).

A turn is one API response (`context-trace.sh` collapses the per-content-block entries
Claude Code writes; before 2026-09-24 it did not, so older scorecards' "turns" are
block counts, ~2.6–3.1× responses — converted estimates below are marked `~`).

| Route | Expected turns | Observed so far (responses) |
|---|---|---|
| scoped | ≤ 30 | 16, 20 (2026-09-20, no delegation) · ~20–27 (2026-07-20, converted) |
| standard | ≤ 70 | ~58–69 (2026-07-29, n=1, converted) |
| high-stakes | ≤ 45 | 21 (2026-09-20, no delegation) · ~31–37 (2026-07-20, converted) |

**Provisional:** n ≤ 2 per route, and the 2026-09-20 runs could not delegate, which
changes turn shape. Recalibrate from the first delegating suite run, and record the
change here. A run over its band is a cost-overrun signal for Efficiency and goes in the
scorecard's regression prose even when no dimension drops — the judge should say where
the turns went (gate overhead, re-dispatch, review iterations, or the work itself).

## Aggregation

- **Task score** = weighted mean of its dimensions (skipping `n/a`, renormalizing).
- **Suite score** = unweighted mean of task scores.
- **Regression** = any dimension dropping > 10 points vs the baseline scorecard, OR
  any new escaped defect. Regressions are listed explicitly, never averaged away.
- **Ablation verdict** (per `--variant`): report the per-dimension delta vs the
  baseline and a one-line judgement of whether the removed layer earned its cost
  on this suite (e.g. quality unchanged + cost down → *not justified here*).
