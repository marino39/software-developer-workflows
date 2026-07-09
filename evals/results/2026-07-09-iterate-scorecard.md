# Workflow eval scorecard — 2026-07-09 (iterate)

**Label:** iterate · **Suite:** tasks 01, 02, 03, 04 · **Repeat:** 1 · **Variant:** none
**Trigger:** behavior-affecting change under the modification protocol — the new
`/iterate` warm-start command (`commands/iterate.md`) + its run-manifest seam in
`commands/new-task.md` (Phase 6 step 10 manifest write; Phase 7 batched-retro note).
Task 04 is new and exercises `/iterate`; tasks 01–03 re-run `/new-task` to check the
additive manifest seam did not regress the existing paths. Ablation A/B
(`--variant iterate-cold`) is reported in the companion variant scorecard.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (exit 0), including the pre-commit hook run
on the `/iterate` commit. New complexity-ledger row (`/iterate` + run manifest)
carries a Prevents + Source (Check 6). No reference-integrity break — `iterate.md`
names only existing skills/agents.

## Layer 2 — outcome-eval

| Task | Cmd | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score | Cost (tok / tools / s) |
|---|---|---|---|---|---|---|---|---|---|---|
| 01 doc-only | /new-task | scoped → **scoped** ✓ | 100 | 100 | n/a¹ | 100 | 95 | none | **99.25** | 52.6k / 15 / 277 |
| 02 bugfix | /new-task | scoped → **scoped** ✓ | 100 | 100 | 100 | 100 | 100 | none | **100** | 54.8k / 17 / 312 |
| 03 route-correct | /new-task | scoped→high-stakes → **high-stakes** ✓ | 100 | 100 | 100 | 100 | 95 | none | **99.0** | 85.4k / 33 / 738 |
| 04 iterate | **/iterate** | scoped (inherited) → **scoped** ✓ | 100 | 95 | n/a¹ | 100 | 100 | none | **98.75** | 61.9k / 15 / 323 |

¹ Tasks 01 & 04 `expect` mark *No escaped defects* n/a and reweight its 20 pts
(+10 Routing, +10 Gate discipline).

**Suite score = 99.25** (mean of task scores). **Escaped defects: 0.**

## Regression section (vs `2026-07-08-baseline-scorecard.md`, tasks 01–03)

No regression. Every dimension held or rose; none dropped > 10 points; no new
escaped defect.

| Task | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Task score |
|---|---|---|---|---|---|---|
| 01 | 97 → 100 | 95 → 100 | n/a | 88 → 100 | 90 → 95 | 93.2 → 99.25 |
| 02 | 95 → 100 | 100 → 100 | 95 → 100 | 90 → 100 | 90 → 100 | 94.75 → 100 |
| 03 | 100 → 100 | 100 → 100 | 100 → 100 | 90 → 100 | 65 → 95 | 93.25 → 99.0 |

**Honesty on the deltas — this is a single un-repeated run; the ~5.5-pt suite rise
is mostly variance, not a claimed quality gain from this change:**
- **Judge non-determinism.** The 88–90 → 100 Gate-discipline jump is largely a
  more-lenient judge instance, not tighter gates — the baseline's dings were
  procedural (section placement). Treat absolute cross-run scores as non-comparable;
  the load-bearing signal is *no regression + zero escaped defects*.
- **Task-03 efficiency 65 → 95** is the baseline run hitting a coder/test-runner
  source-mutation flake during revert-discriminate (documented in the baseline's
  Observation 2); this run simply didn't hit it. Not attributable to this change.
- The change under test is **additive** to `/new-task` (write a manifest at the end;
  one Phase 7 note) — it touches no gate decision, and tasks 01–03 behaved
  identically in route/tier/gate terms. That is what this row set is here to show.

## What the change under test did (task 04, `/iterate`)

The `/iterate` warm path behaved exactly to spec (judge verdict: correct on every
`expect` criterion):

- **Warm delta, not a cold run.** Read the run manifest and seeded context from it;
  ran **no** cold Phase 0 rediscovery, **no** brainstorm fan-out, **no** plan-review
  phase, and spawned **no** searcher/researcher — the only architect call was the
  Phase I1 plan-lite. This is the whole point of the command.
- **Route inherited + held.** Inherited `scoped` (the manifest floor), monotonic
  re-check against the +1-line delta found no trigger → stayed scoped, no escalation.
- **Delta review, not a fan-out.** Phase I2 ran a single fresh reviewer over the
  iteration diff (the existing iterations-2+ Review-loop machinery from iteration 1),
  not the full Channel A/C + consolidator + skeptic — correct because the baseline
  was already fully reviewed and the route didn't escalate. Verdict computed PASS.
- **GATE I auto-approved** on the full criteria set (route not escalated above floor
  ∧ tests green ∧ 0 Must-fix ∧ verification exempt ∧ 0 scope deviations).
- **Retro deferred + batched.** Appended a compact iteration-log entry to the
  manifest, bumped its HEAD_SHA, recorded 2 newly-opened Should-fixes; ran Phase 7
  **once** inline (single final iteration) with an empty GATE 4 table → nothing
  written to `~/.claude`. No per-tweak retro tax — the design goal.
- **Honest defect surfacing.** The follow-up documents `calc.Product`, which does
  not exist in `calc.go` (the doc-only constraint forbids adding it). `/iterate`
  neither silently shipped the doc/code drift nor over-blocked on it — it flagged a
  carried **Should-fix** and auto-approved. Outcome scored 95 (the −5 is that
  inherent drift, correctly handled), not a defect.

## Observations / follow-ups

1. **`/iterate` command clarifications (from the task-04 run's own notes), applied in
   the same change** — both codify behavior the run already produced, so no
   re-score is owed:
   - Phase I0/I2: a doc-only delta that documents or relies on a symbol **absent
     from the baseline tree** is a carried Should-fix under the doc-only constraint,
     not a scope-bounce to `/new-task`.
   - Phase I0 step 2: for a **local-kept** baseline the manifest records no worktree
     path, so "reuse the worktree warm" falls back to the current checkout.
2. **Shared-fixture red baseline** (carried from the baseline scorecard, still open):
   `evals/fixtures/base` is green, but task 02's `## Seed` reds `calc`. Task 04's
   base is green (no seed), so its "tests green" criterion is literally satisfiable —
   unlike task 01/03 per the prior note.
3. **Ablation still owed → now runnable.** The complexity-ledger row for `/iterate`
   is `candidate`; the `iterate-cold` variant + its A/B (companion scorecard) supply
   the earn-its-cost evidence to move it to `keep` or cut it.

## Notes

- Runs dispatched as subagents with the eval-harness preamble (auto-approver at every
  gate; propose-only at GATE 4 — nothing written to `~/.claude`, no `capture.sh`).
  Only structured artifacts collected; no raw transcripts.
- Each task ran against an isolated, git-initialized copy of `evals/fixtures/base`;
  task 04's copy was pre-seeded with a simulated completed prior `/new-task` run
  (baseline `calc.Sum` doc commit + a run manifest) so `/iterate` had a real
  reviewed baseline to delta against.
- **Environment limits, not scored as workflow defects:** Fable was out of API
  credits (clean recorded fallback to opus), `codex` absent (Channel B degrades
  free), `superpowers:*` skills unregistered in-harness (procedures executed
  directly). Judge instructed to treat these as harness, not workflow.
- Cost figures are measured `subagent_tokens` / `tool_uses` / wall-seconds per run —
  the first scorecard to carry them (the baseline scored Efficiency qualitatively).
