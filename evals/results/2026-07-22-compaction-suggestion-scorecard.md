# Workflow eval scorecard — 2026-07-22 (compaction-suggestion)

**Label:** compaction-suggestion · **Suite:** tasks 04 (n=1), 05 (n=1) · **Trigger:**
behavior-affecting change under the modification protocol — orchestrator-driven
compaction *suggestions* at safe boundaries (`commands/new-task.md` Human-contract
rule + `commands/iterate.md` Retro step 1 accumulation marker; ledger row
2026-07-22, candidate). Prompted by a design discussion on cutting orchestrator
context growth (proposal `2026-07-20-orchestrator-context-compaction` S5/S6).

**What this run measures.** The change is **suggestion-only and opt-in** — it adds
a `/compact` nudge to a gate's **Next** on structurally heavy runs (new-task) or on
`/iterate` accumulation (≥3 log rows since the last `compact-suggested` marker). No
frozen task runs a heavy `/new-task` or a ≥3-iteration `/iterate` session, so the
suggestion **never fires** on this suite. This scorecard therefore evidences
**regression-safety** — that the new rule is inert on normal single-delta `/iterate`
runs and perturbs neither routing, outcome, gates, nor the verdict — and that the
**suppression half** of the rule is correctly evaluated (both triggers checked,
neither met, log row left untagged). The **firing** half (accumulation nudge,
heavy-gate nudge) is NOT exercised here; see Owed.

**Environment (material, same as the 2026-07-22 delegation-floor scorecards):** the
remote harness did not expose the Agent tool to the driver subagents, so each driver
executed the delegated roles inline while following the workflow's phase/gate/verdict
logic. Per the delegation-floor ledger row this is a known harness constraint, not a
workflow defect; judges scored the workflow logic and treated inline execution as an
Efficiency artifact (noted, not zeroed). Both drivers recorded it as a GATE I
deviation. Cost/latency figures below price *this* harness, not the parallel
Agent-tool path.

## Layer 1 — lint

```
PASS  reference integrity (skills referenced all exist)
PASS  reference integrity (agents referenced all exist)
PASS  route/tier consistency (monotonic route; escalation voids auto-approve & reduced tier)
PASS  phase completeness (iteration caps present; escalation ladder present)
PASS  gate-format consistency (four sections + GATE 4 per-item evidence + scope-gate route rationale)
PASS  agent contracts (all agents declare Input + Output contract, fields, Role)
PASS  complexity ledger (every row has Prevents + Source)
PASS  learnings bullets (every dated bullet has a tag + src:)
workflow-lint: all checks passed
```

8/8 checks pass (also enforced on the commit by the pre-commit hook).

## Layer 2 — judge scores + cost

| Run | Routing | Outcome | No-escaped | Gate | Efficiency | Task score | Escaped | Driver cost (tok / tools / s) | ctx hiwater / mean / first / cold |
|---|---|---|---|---|---|---|---|---|---|
| 04-r1 (doc delta) | 100 | 100 | n/a¹ | 100 | 90 | 98.5 | none | 58.0k / 18 / 221 | 57.7k / 46.3k / 27.3k / 2 |
| 05-r1 (code delta) | 100 | 100 | 100 | 100 | 90 | 98.5 | none | 80.8k / 22 / 332 | 80.5k / 59.7k / 27.4k / 0 |

¹ Task 04 `expect`: *No escaped defects* n/a → reweight +10 Routing, +10 Gate discipline.

**Suite score: 98.5** (mean of task scores).

### Compaction-rule behavior (the change under test)

- **Task 04 (scoped, doc-only, single delta):** no `/compact` suggestion surfaced —
  **correct**. Rule (a) suppressed (not heavy: scoped, single delta reviewer, no
  Phase 6.5 CI wait). Rule (b) not met (iteration log = 2 rows since last marker,
  below the ≥3 threshold). GATE I row **not** tagged `compact-suggested`; counter not
  reset. Judge: "held as expected."
- **Task 05 (standard, code delta, single delta):** no `/compact` suggestion
  surfaced — **correct**. Rule (a) not met (route never high-stakes → no full
  fan-out; local-kept → no CI wait). Rule (b) not met (2 log rows < 3). Row not
  tagged. Judge: "correctly withheld per both trigger conditions."

Both drivers evaluated *both* triggers explicitly and recorded the reasoning in the
iteration-log row — the rule is being read and applied, not ignored.

## Regression section (vs baseline)

Baseline = the `post` delegation-floor state of `iterate.md` (commit `f048e72`),
scored in `2026-07-22-delegation-floor-ab-scorecard.md` — the immediate parent state
before this change:

- **Task 04:** baseline post-04-r1 = 95.2 (Routing 100 / Outcome 100 / Gate 100 /
  Efficiency 68) → this run 98.5 (same dims, Efficiency 90). No dimension dropped.
- **Task 05:** baseline post-05 mean ≈ 92.85 (r1 90.25 / r2 93.55 / r3 94.75; Outcome
  100, 0 escaped every run) → this run 98.5. No dimension dropped.
- **Escaped defects:** 0 baseline, 0 this run. None new. The task-05 empty/nil
  `(0,false)` control was caught by both `TestMax` and the delta review.

**No regression** — no dimension dropped > 10 points, zero new escaped defects. The
small score *rises* are not claimed as improvement: n=1 here vs the baseline's n=1/n=3,
single-run deltas are noise (per `CLAUDE.md`), and the Efficiency uptick is within
judge variance on the same inline-execution harness. The result that matters is
**inert-and-correct**: the new rule changed no routing, outcome, gate, or verdict, and
its suppression logic evaluated correctly on both routes.

## Owed to fully close

1. **Positively exercise the firing path.** Author a multi-`/iterate`-session fixture
   task (≥3 short deltas in one session) so the accumulation trigger (rule (b)) fires
   and tags a row `compact-suggested`, then resets — the one behavior this suite
   cannot reach. Likewise a heavy `/new-task` task (GATE 3 approving a PR, or ≥2 review
   iterations) to exercise the new-task-side rule (a).
2. **Cost telemetry for the win it targets.** The proposal's cold-re-entry signal
   (`/usage` cache-read vs full-price input) over a post-GATE-3 CI-wait run — the
   scenario the suggestion is meant to shrink — to price the benefit, not just confirm
   safety. Suggestion-only + opt-in → NOT ablation-gated (per the ledger row); value
   lands in the context-trace cost column, not the rubric.
3. Re-run in a local CLI where the Agent tool reaches drivers (shared with the
   delegation-floor owed run) so Efficiency prices the real parallel dispatch path.
