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
| Learnings trigger tags + evidence links (Phase 0 / 7) | misapplying an irrelevant lesson; unauditable rule-overrides | Prop #5 plan 2026-07 | keep | — |
| `/iterate` warm-start command + run manifest (commands/iterate.md; new-task Phase 6 step 10) | re-litigating the route + re-paying lifecycle machinery (cold Phase 0, brainstorm, plan-review, per-tweak retro) to make a small delta on a just-reviewed baseline, AND cold re-routing a follow-up to a risky baseline as under-reviewed | Prop post-task-iteration-perf 2026-07; scorecards 2026-07-09-iterate + A/Bs 2026-07-09-iterate-cold (doc, n=1) + 2026-07-09-iterate-cold-code (code, n=3) | keep (qualified) | MEASURED, mixed: token cost is NOT a flat saving — favorable on doc-only (n=1: warm 3 vs cold 6 subagents, ~1.9×) but ~neutral-to-negative on a small scoped code delta (n=3: warm 68k/4-agents tight vs cold 53–116k/4–11-agents bimodal; warm heavier when cold routes scoped, far lighter when cold routes standard). 0 Δ escaped defects both. Real justification = cost PREDICTABILITY (warm CV~12% vs cold ~48%) + route-floor DETERMINISM/SAFETY (cold re-judged the same task scoped vs standard across runs → a high-stakes-baseline follow-up could be cold-under-reviewed; warm can't de-escalate) + batched retro (by-design, UNMEASURED). Owed: multi-tweak-session + high-stakes-baseline iterate tasks to evidence the last two |
| Per-agent effort defaults (agents/*.md frontmatter) | over-spend on mechanical lookups (searcher/test-runner) + shallow reasoning on design/debug (architect/debugger) | design-note 2026-07-08 (effort levels); Anthropic effort docs; scorecard 2026-07-08-effort-defaults (outcome-neutral, 0 escaped; isolated n=6 microbenchmark) | keep (zero-cost, doc-aligned; inert in-harness) | MEASURED: isolated per-agent microbenchmark (n=6/cell, frontmatter toggle) shows NO effort effect in this SDK harness — architect high vs xhigh 7424 vs 7428 tok / 38.7s vs 38.3s; test-runner high vs low 9067 vs 9076 tok / 9.1s vs 7.5s (overlapping). subagent_tokens is constant (context size, not reasoning). Lever is inert here but zero-cost (4 frontmatter lines) and matches Anthropic effort docs → retained for the production CLI where it bites; revisit if the harness starts honoring frontmatter effort |
