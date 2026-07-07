# Complexity ledger

Every non-obvious construct in the workflow costs tokens, latency, and reader
attention. This ledger is the **complexity budget**: each accreted construct must
name the concrete failure it prevents and where that justification comes from.
Rows sourced to `intuition — unverified` are the standing simplification backlog —
they get an ablation variant and a live A/B (`/workflow-eval --variant`) before we
either keep them on evidence or cut them.

The lint (`evals/lint.sh` Check 6) enforces that every row has a **Prevents** and a
**Source**; it does not (cannot) enforce that every construct is listed —
completeness is a review discipline (see `CLAUDE.md`).

**Status legend:** `keep` = justified, not currently questioned · `ablation-queued`
= has a variant, awaiting an A/B · `candidate` = flagged, no variant authored yet ·
`consolidated` = simplified in place without behavior change.

| Construct (location) | Prevents | Source | Status | Ablation |
|---|---|---|---|---|
| 3-architect brainstorm fan-out (Phase 1.2) | single-approach tunnel vision on wide design spaces | design-note 2026-07 (Cowork); intuition — unverified | ablation-queued | brainstorm-single |
| Fable synthesizer, fresh instance (Phase 1.3) | biased ranking by a design's author-instance | design-note cost/quality 2026-07 | keep | — |
| Phase 2 adversarial design review + fable iter-1 reviewer | a flawed design entering planning | design-note 2026-07 | keep | — |
| Delta re-review, iterations 2+ (Phases 2/4/6) | re-review token blowup on long review loops | design-note loop-placement 2026-07 | consolidated | — |
| Skeptic pass, default-refute (Phase 6.4) | plausible-but-wrong Must-fix reaching coders | learning 2026-07-03 (promoted) | ablation-queued | skeptic-off |
| Reduced/full tier interlock (Phase 6.2) | over-reviewing tiny low-risk diffs | design-note cost/quality 2026-07; intuition — unverified | candidate | — (needs variant) |
| 3-lens Channel C reviewers, C1/C2/C3 (Phase 6.3) | single-lens blind spots (bug / history / compliance) | design-note 2026-07; intuition — unverified | ablation-queued | single-lens-review |
| Codex external channel B (Phase 6.3) | missing an out-of-model review perspective | design-note cost/quality 2026-07 | keep | — (degrades free) |
| Consolidation confidence scoring 0–100 (Phase 6.4) | review noise / false positives reaching the gate | design-note 2026-07 | keep | — |
| Fable budget accounting "2 slots + 1" (Escalation ladder) | runaway fable cost per run | design-note cost/quality 2026-07; intuition — unverified | ablation-queued | fable-budget-flat |
| Route re-check, two checkpoints (Phase 0 / 3.5 / 6.0) | a mis-routed scoped task shipping under-reviewed | Prop #4 plan 2026-07 | keep | — |
| Event-driven CI wait + webhook gap guard (Phase 6.5) | holding the turn open / missed CI success events | loops-article revision 2026-07 | keep | — |
| Behavioral verification via verify-feature (Phase 6.1) | green-tests-but-broken feature shipping | design-note verify-feature 2026-07 | keep | — |
