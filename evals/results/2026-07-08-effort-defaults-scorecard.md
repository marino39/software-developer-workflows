# Workflow eval scorecard — 2026-07-08 (effort-defaults)

**Label:** effort-defaults · **Suite:** tasks 01, 02, 03 · **Repeat:** 1 · **Variant:** none (frontmatter-swap A/B — see caveat)
**Trigger:** behavior-neutrality regression check for the per-agent reasoning-`effort`
defaults added to `agents/{searcher,test-runner}.md` (`low`) and
`agents/{architect,debugger}.md` (`xhigh`); coder/reviewer/researcher unchanged
(`high` default). Change committed at `0631958`.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (exit 0), both standalone and via the
pre-commit hook on `0631958`.

## Layer 2 — outcome-eval

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score |
|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ | 98 | 100 | n/a¹ | 95 | 95 | none | **97.3** |
| 02 bugfix | scoped → **scoped** ✓ | 97 | 100 | 100 | 92 | 95 | none | **97.3** |
| 03 route-correct | scoped→high-stakes → **high-stakes** ✓² | 100 | 100 | 100 | 95 | 90 | none | **97.75** |

¹ Task 01 `expect` marks *No escaped defects* n/a and reweights its 20 pts (+10 Routing, +10 Gate discipline).
² Reached high-stakes via **Path (a): Phase 0 direct** (auth = high-stakes category); full tier + human GATE 3 held. Prop #4 invariant intact.

**Suite score = 97.45** (mean of task scores). **Escaped defects: 0.**

## Regression section (vs `2026-07-08-baseline-scorecard.md`)

**No regressions.** No dimension dropped > 10 points; no new escaped defects (0 → 0
suite-wide). One >10-pt swing, and it is an *improvement, not attributable to this
change*:

- **Task 03 Efficiency 65 → 90 (+25).** The baseline's 65 was a coder/tool-reliability
  ding (revert-discriminate mutated source through the test-runner and left the tree
  reverted mid-swap). This run's revert-discriminate executed cleanly, so that ding
  did not recur. This is run-to-run coder-tooling variance, **not** an effect of the
  effort defaults. Do not credit the effort change for it.

The remaining per-dimension movements (Routing/Outcome/Gate ±2–7) are within
single-run noise; the suite is behaviorally equivalent to baseline.

## What this run can and cannot show (read before trusting the delta)

- **CAN show:** the effort-defaults change is **outcome-neutral** — all three task
  classes (fast-path doc-only, scoped bugfix with verify-fix, high-stakes routing
  guard) landed on their expected route, outcome, and gate behavior with **zero
  escaped defects**, same as baseline. It does not break the workflow.
- **CANNOT show:** the *cost benefit* that motivates the change. The rubric's
  **Efficiency** dimension is scored on qualitative signals (tier, iteration count,
  escalations), and — as the baseline notes — the collected artifacts carry **no
  measured per-agent token/wall figures**. Reasoning effort is also **not surfaced**
  by this harness (the Agent tool has no per-invocation effort readout; #43083). So
  this scorecard **cannot** measure whether `effort: low` on searcher/test-runner
  actually reduced token spend, and therefore cannot reach the ablation's
  "quality unchanged + cost down → justified" verdict.
- **Instrument caveat:** task 01 (the pilot) ran before the effort-tagged custom
  agents were registered in the harness, so it exercised generic agent types; tasks
  02 and 03 confirmed they spawned the effort-tagged agents (searcher/test-runner
  `low`, architect `xhigh`). This is a true frontmatter-swap A/B vs baseline in
  *config*, but the harness cannot attribute the (unmeasured) token delta to it.

## Verdict

**Outcome-neutral: safe to keep on quality grounds.** The cost A/B remains **deferred**
to an environment that surfaces per-agent effort/token figures (real Claude Code CLI,
or the harness extended to collect per-agent token counts). Ledger row stays
`ablation-queued` pending that measurement.

## Metrics — tokens & wall-clock (baseline A/B)

Real per-run figures from each dispatched run's harness telemetry
(`subagent_tokens`, `duration_ms`). To get a comparison the prior scorecards lack,
the **baseline condition was re-run** with the `effort:` lines stripped from the live
`~/.claude/agents/*.md` copies (repo commits untouched; restored via `./install.sh`).
Both conditions ran the same three tasks against fresh, git-initialized copies of
`evals/fixtures/base` (task 02's seed applied). Single sample per cell.

| Task | Baseline tok | Effort tok | Δ tok | Baseline time | Effort time | Δ time |
|---|---|---|---|---|---|---|
| 01 doc-only | 48,762 | 47,627 | −1,135 (−2.3%) | 2m16s | 1m56s | −20s (−15%) |
| 02 bugfix | 47,555 | 56,806 | +9,251 (+19.5%) | 2m18s | 5m23s | +3m05s (+134%) |
| 03 route-correct | 81,848 | 67,555 | −14,293 (−17.5%) | 10m48s | 7m44s | −3m04s (−28%) |
| **Suite total** | **178,165** | **171,988** | **−6,177 (−3.5%)** | **15m22s** | **15m03s** | **−19s (−2.1%)** |

### Interpretation — noise-dominated, no systematic signal

The **aggregate is a wash** (−3.5% tokens, −2.1% wall-clock — inside run-to-run
variance), and the **per-task deltas swing hard in both directions** (task 02 +19.5%,
task 03 −17.5%). The swings track orchestration non-determinism, not the effort lever:

- **Task 02 (+19.5% tok, +134% time) under effort:** the run took a heavier
  plan/review path; the `xhigh` architect on plan-lite is the plausible driver, and it
  *outweighs* the `low` searcher/test-runner savings at run level. This is the expected
  shape of the conservative config — deeper design agent, cheaper mechanical agents —
  and at run-level totals the architect dominates.
- **Task 03 (−17.5% tok) under effort:** the *baseline* run happened to take an extra
  Phase-3 plan iteration (its architect strayed into a look-alike dir, caught at
  GATE 2), inflating baseline cost. That iteration difference — not effort — is the
  delta. Both task-03 runs also hit the same fable-credit outage (→ opus fallback), so
  that confound at least cancels.
- **Task 01 (−2.3% tok, −15% time) under effort:** a doc-only run barely exercises the
  architect, so the low-effort mechanical agents show through as a small, clean win —
  the one cell where the lever's intended direction is visible.

**Why run-level totals can't settle this:** the effort change moves reasoning depth in
the *small* searcher/test-runner (down) and architect/debugger (up) sub-agents; a single
run's total is dominated by how many review/plan iterations the orchestrator happened to
take, which is far larger than the effort delta. `subagent_tokens` scope (whether it
includes recursive children) is also ambiguous — applied identically to both conditions,
so the *delta* stays apples-to-apples, but the absolute values are soft.

**Verdict:** these numbers are an **indicative run-level envelope** (~170–180k tok,
~15 min for the 3-task suite in either condition), **not** a cost proof. They neither
demonstrate nor refute the lever's cost benefit — see the per-agent mining attempt below,
which was the intended way to isolate the signal, and why it also fell short.

### Per-agent token mining — attempted, data source inadequate

To isolate the effort effect from run-level noise, this session's per-agent transcripts
were mined (`~/.claude/projects/.../subagents/agent-<id>.jsonl`, 68 files; agent type from
`.attributionAgent`, condition from a fixture-path fingerprint). **The attempt does not
yield a usable per-agent cost signal**, for two concrete reasons:

1. **The recorded `output_tokens` is not the real generation.** Architect files log
   **4–60 output_tokens** each, while the same files' input+cache totals are **10–15k** and
   the notification-level `subagent_tokens` were tens of thousands. An `xhigh` architect
   doing real design work cannot have emitted 4 tokens — so this per-message field is a
   partial/handoff artifact in these transcripts, far too small and inconsistent to compare
   reasoning depth across effort levels. (No separate thinking-token field exists either.)
2. **The fixture-path fingerprint maps only 1 of 13 architect files** — architects receive a
   design/task prompt, not the raw worktree path, so 12 fall unmapped. `sessionId` is global
   (one per session) and can't group runs; only a full parent-UUID spawn-tree would recover
   them, and reason (1) makes that recovery pointless.

The only trustworthy token figure the harness exposes is the top-level dispatched run's
`subagent_tokens` (the run-level A/B above). So the measurement was moved out of the
orchestration entirely — see the isolated microbenchmark below.

### Per-agent effort microbenchmark (isolated dispatch, n=6 per cell)

The decisive experiment: dispatch a single agent **directly** (no orchestration) on a fixed
prompt, toggling only its frontmatter `effort`, so the dispatch's own `subagent_tokens` +
`duration_ms` are the agent's metric with zero orchestration variance. Two changed agents, both
effort directions, 6 samples per condition (batch-parallel per condition, unique per-dispatch
nonce). Architect prompt: a self-contained rate-limiter design (0 tool calls — pure reasoning,
where `xhigh` should bite hardest). test-runner prompt: `go build`+`go test` on a fixed module.

| Agent | Condition | n | Tokens mean (range) | Duration mean (range) | Δ vs baseline |
|---|---|---|---|---|---|
| architect | **high** (baseline) | 6 | 7,424 (7,424) | 38.7s (27.8–46.4) | — |
| architect | **xhigh** | 6 | 7,428 (7,427–7,431) | 38.3s (31.5–46.1) | tok +0.05%, time **−1%** |
| test-runner | **high** (baseline) | 6 | 9,067 (9,015–9,103) | 9.1s (6.7–12.1) | — |
| test-runner | **low** | 6 | 9,076 (9,040–9,117) | 7.5s (6.8–8.0) | tok +0.1%, time −17%¹ |

¹ test-runner's −17% duration is inside the noise: the two conditions' ranges overlap almost
entirely (high 6.7–12.1 vs low 6.8–8.0); the high mean is pulled up by two slow samples, not a
systematic effect. Tokens are flat.

**Result: no measurable effort effect in this SDK harness — in either direction.**
- **Tokens are essentially constant** per (agent, prompt) regardless of effort: architect
  7,424 vs 7,428; test-runner 9,067 vs 9,076. `subagent_tokens` tracks context size, not
  reasoning depth — it is blind to effort by construction.
- **Duration doesn't separate either:** architect high vs xhigh is 38.7s vs 38.3s (xhigh
  marginally *faster*); test-runner's difference sits inside overlapping ranges. The one-shot
  pilot that appeared to show +44% (architect 88s→127s) was **noise** — it vanished at n=6.

**Verdict — the effort lever is inert *in this harness*, within measurement resolution.** The
harness does not appear to apply frontmatter `effort` in a way that changes observable token or
wall-clock cost. This is not the same as "effort does nothing": Anthropic's effort docs report
real token effects on the production models, and the change is outcome-neutral and near-zero
cost (4 frontmatter lines, no workflow logic). So the defaults are **retained as
documented-best-practice config that will bite on the production Claude Code CLI**, but this
repo's eval environment cannot demonstrate a cost delta from them. A definitive cost
measurement requires a harness/CLI that surfaces real per-call generation+thinking tokens.

**Method caveats:** n=6, single fixed prompt per agent, batch-parallel per condition (symmetric
self-contention, so the between-condition delta is fair but absolute durations are inflated);
the per-dispatch nonce sits at the prompt tail so the cacheable prefix is still shared (doesn't
affect the flat-token conclusion); `subagent_tokens` is the only reliable token figure and it is
constant. searcher (low) and debugger (xhigh) were not benchmarked — architect (the strongest
xhigh case) and test-runner (a clean low case) bracket the question, and both are null.

## Notes

- Runs dispatched as subagents with the eval-harness preamble (auto-approver at every
  gate; propose-only at GATE 4 — nothing written to `~/.claude`, no `capture.sh`).
  Only structured artifacts collected; no raw transcripts. Scored by a fresh
  `reviewer`-as-judge against `evals/rubric.md`.
- Each task ran against an isolated, git-initialized copy of `evals/fixtures/base`
  (task 02's `## Seed` off-by-one applied to its copy before dispatch).
- **Environmental deviation (task 03):** fable was out of usage credits, so the
  Phase 1 synthesizer and Phase 2 adversarial reviewer fell back to opus. Recorded by
  the run as a Deviation; judged environmental (not a needless escalation), so it did
  not lower Efficiency.
