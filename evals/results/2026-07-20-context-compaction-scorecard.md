# Workflow eval scorecard — 2026-07-20 (context-compaction)

**Label:** context-compaction · **Suite:** tasks 01, 02, 03 · **Repeat:** 1 · **Variant:** none
**Baseline diffed against:** `2026-07-08-refresh-scorecard.md` (newest scorecard
containing these tasks; its own *Update* section re-scores task 03 to ~95 under
the corrected path-agnostic `expect`, which is the `expect` now in the task file —
that corrected value is the operative comparison).
**Trigger:** the owed live scorecard for the context-compaction change
(`docs/proposals/2026-07-20-orchestrator-context-compaction.md` S1–S5 + S8):
path-passing, architect artifact mode, run ledger at every gate, Opus
orchestrator default. Companion contract report: `2026-07-20-contracts.md`
(architect dual-mode, 2/2 pass).

## Layer 1 — lint

`sh evals/lint.sh` → all 7 checks PASS (exit 0).

## Layer 2 — outcome-eval

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score | Δ vs baseline | Orch. cost³ |
|---|---|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ (auto-approved GATE 3) | 100 | 100 | n/a¹ | 96 | 97 | none | **98.6** | +0.6 | 81.6k tok / 31 calls / 8.7 min |
| 02 bugfix | scoped → **scoped** ✓ (verify-fix proven) | 97 | 98 | 96 | 95 | 97 | none | **96.75** | −0.25 | 88.7k tok / 27 calls / 11.1 min |
| 03 route-correct | high-stakes → **high-stakes** ✓ (Phase 0 direct; full tier; presented GATE 3) | 100 | 100 | 100 | 100 | 100 | none | **100.0** | +5.0² | 110.4k tok / 47 calls / 18.2 min |

¹ Task 01 `expect` marks *No escaped defects* n/a and reweights (+10 Routing, +10 Gate discipline).
² Vs the corrected ~95; vs the as-scored 80 under the old `expect`, +20.
³ **New column (first scorecard carrying it; backfilled from this run's usage
trailers).** Driver-total tokens / tool calls / wall-clock per the Collect step's
orchestrator-cost datapoint — a proxy for orchestrator context accumulation, NOT
per-gate context size (that attribution remains the proposal's open live-run
measurement). No baseline comparison exists: prior scorecards recorded subagent
tokens only ad hoc (e.g. the `/iterate` A/B's warm 68k vs cold 53–116k). These
three values are the baseline for future diffs. Note the shape they already
show: the full high-stakes lifecycle cost ~1.3× a fast-path run in driver
tokens (110k vs ~85k) for a 42-line diff — the eval preamble collapses human
turns and carries no resident-skill overhead, so live-session contexts sit
well above these floors.

**Suite score = 98.5** (baseline corrected ~96.7, **+1.8**). **Escaped defects: 0.**

## Regression section (vs 2026-07-08 refresh)

**No regressions.** No dimension dropped >10 points on any task and no new
escaped defect appeared. Largest per-dimension movements, all upward:
task 03 Efficiency 78 → 100 (the baseline's Phase 4 plan-reviewer misfire did
not recur — mapping table complete on iteration 1) and task 03 Gate discipline
90 → 100. Small sub-5-point per-dimension wobbles on tasks 01/02 are single-run
noise per the suite's own caveat.

## What the change-under-test did in these runs (observed, not scored)

- **Architect artifact mode fired in all three runs**: plan-lite files written
  by the architect on tasks 01/02; on task 03 both the design doc
  (`docs/superpowers/specs/…-design.md`) and the plan were architect-written,
  with the orchestrator handling only path + ≤200-word summary returns. The
  companion contract report confirms mode discipline (no unprompted writes;
  artifact-path-only writes).
- **Path-passing held**: coders received plan path + step numbers; Phase 4/6
  reviewers Read the plan/design themselves; task 03's Channel A got the plan
  path per the template.
- **Run ledger at every gate**: all three manifests carry a gate log written as
  gates passed (task 03's records per-gate outcomes, open findings folded from
  Phase 2, iteration counts, and a Final section) — the compaction-safety
  property the change exists to provide. Gate **Next** sections flagged the
  safe-`/compact` moment as instructed.
- **Route/tier machinery unaffected**: scoped fast path with legitimate
  GATE 3 auto-approve (01, 02); high-stakes full lifecycle with opus-escalated
  reviewers, exactly two by-design fable slots, discretionary fable unspent
  (03). Proposition #4 controls intact — no fast-path auto-approve, no reduced
  tier on the auth diff.
- **Cost shape**: 5 subagents on each fast-path run; 16 on the full high-stakes
  lifecycle; zero review iterations beyond iteration 1 anywhere.

## Notes

- Runs dispatched as subagents under the eval-harness preamble (auto-approver
  at every gate; GATE 4 propose-only — nothing written outside the fixtures).
  Only structured artifacts collected. Judges: fresh reviewer per task fed
  artifacts + `expect` + rubric.
- Each task ran against an isolated, git-initialized fixture copy: 01/03 on the
  green base, 02 with its `## Seed` pre-applied (verified red before dispatch).
- Environment artifacts (not scored): `codex` CLI unavailable (`skipped`
  recorded per workflow text); `superpowers:*` skills followed as intent
  (worktree → branch; finishing → local `--no-ff` merge, no PR → Phase 6.5
  skipped); nested named-subagent spawning unavailable to the coder on task 02
  (ran the CI-exact `go test` directly — disclosed at GATE 3). Both fable
  dispatches on task 03 succeeded (no degradations, unlike the 2026-07-08 run).
- Single-run per task (`--repeat 1`): treat small deltas as noise; the
  no-regression conclusion rests on the absence of >10-point drops and of
  escaped defects, both of which are robust to that noise.
