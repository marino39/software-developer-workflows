# Workflow eval scorecard — 2026-07-09 (gate-rendering)

**Label:** gate-rendering · **Suite:** tasks 01, 03 (gate-sensitive subset) · **Repeat:** 1 · **Variant:** none
**Baseline diffed against:** `2026-07-08-refresh-scorecard.md` (tasks 01 & 03)
**Trigger:** behavior-affecting change to `commands/new-task.md` + `commands/iterate.md` —
gates now render as plain-text messages that end the turn (never `AskUserQuestion`),
and clarifying questions at a gate are answered in-band with the gate re-presented.
Per CLAUDE.md the change owes a live scorecard before merge; this is it.

**Scope note:** the change only affects **how a gate is surfaced** (rendering + follow-up
handling), not routing, tier selection, review rigor, or verdict computation. The two
tasks whose expectations pin gate behavior were run: **01** (doc-only → fast-path
GATE 3 auto-approve) and **03** (auth hardening → high-stakes, full tier, human GATE 3).
Tasks 02/04/05 are not differentially affected by gate rendering and were not re-run.

**Environment caveat:** `superpowers:*` skills are not installed in this run environment,
so dispatched `/new-task` agents improvised those procedural steps (worktrees, brainstorm,
plan, review, finish) directly — the same condition prior scorecards ran under. Fixtures
were isolated green git copies; the harness was the non-interactive auto-approver.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (exit 0).

## Layer 2 — outcome-eval

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score | Δ vs baseline |
|---|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ | 100 | 100 | n/a¹ | 100 | 100 | none | **100** | +2.0 |
| 03 route-correct | high-stakes → **high-stakes** ✓ (Phase 0 directly; controls held) | 100 | 100 | 100 | 95 | 85 | none | **97** | +17.0² |

¹ Task 01 `expect` marks *No escaped defects* n/a and reweights (+10 Routing → 35, +10 Gate discipline → 25).
² Δ vs the refresh baseline's Task-03 score of 80. The +17 is **not** produced by this
change — it is the task-03 `expect` fix that landed in the refresh PR (full Routing credit
for reaching high-stakes by *either* valid path). Under the current `expect`, this run's
Phase-0-direct route earns Routing 100 instead of the artifactual 40. See Regression section.

**Suite score = 98.5** (baseline, same two tasks: (98+80)/2 = 89.0 → **+9.5**). **Escaped defects: 0.**

## Regression section (vs 2026-07-08-refresh)

**No regression.** No dimension dropped > 10 points on either task, and there are zero new
escaped defects. Per-dimension movement (all flat or up):

- **Task 01** — Routing 100→100, Outcome 100→100, Gate discipline **95→100** (+5),
  Efficiency **95→100** (+5). Gate summaries were well-formed and decidable, auto-approve
  used only on held criteria — the rendering change preserved decidability.
- **Task 03** — Routing **40→100** (scoring-artifact resolution, not this change — see
  note ² and the refresh scorecard's "task 03 Routing resolved" section: the fixture doc
  comment was de-biased and the `expect` was widened to reward either valid high-stakes
  path). Outcome 100→100, No-escaped 100→100, Gate discipline **90→95** (+5), Efficiency
  **78→85** (+7). The anti-regression controls held: **full tier + human GATE 3**, never a
  fast-path auto-approve, never the reduced tier — Proposition #4 intact.

### Gate-rendering-specific observations

The dimension this change targets is **Gate discipline**; it held at or above baseline on
both tasks (01: 95→100; 03: 90→95). Both runs emitted every gate summary in the full
four-section format with its decision evidence inline (route rationale at the first
touchpoint; GATE 1 rejected-alternatives; GATE 2 mapping table; GATE 4 per-item decision
table), and both used auto-approve only where its criteria held. The judges flagged no
missing/garbled summary and no evidence-absent decision — i.e. the rendering rule did not
degrade what reaches the approver. (The `AskUserQuestion`-vs-plain-text distinction the
change turns on is a live-UI property the auto-approver harness cannot exercise directly;
the eval confirms the *content* contract is unregressed, and the fix's mechanism — end the
turn on the summary — is a text-rendering guarantee validated by inspection of the edited
Human contract.)

## Summary

- **Lint:** 8/8 PASS (exit 0).
- **Suite:** 98.5 on the gate-sensitive subset (01, 03); +9.5 vs the same two baseline
  tasks, all of which is the task-03 `expect` fix plus small Gate/Efficiency gains — no
  dimension regressed, 0 escaped defects.
- **Verdict:** the gate-rendering change (plain-text gates + in-band follow-ups) does **not**
  regress the suite; Gate discipline is unregressed-to-improved. Scorecard obligation for
  the behavior-affecting change satisfied on the affected tasks.
