# Workflow eval scorecard — 2026-07-08 (refresh)

**Label:** refresh · **Suite:** tasks 01, 02, 03 · **Repeat:** 1 · **Variant:** none
**Baseline diffed against:** `2026-07-08-baseline-scorecard.md`
**Trigger:** re-run after the eval follow-ups — green fixture base + per-scenario
`## Seed` (commit 1) and verify-fix revert-discriminate hardening (commit 2).

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (exit 0).

## Layer 2 — outcome-eval

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate disc. | Efficiency | Escaped | Task score | Δ vs baseline |
|---|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ | 100 | 100 | n/a¹ | 95 | 95 | none | **98** | +4.8 |
| 02 bugfix | scoped → **scoped** ✓ | 100 | 100 | 95 | 90 | 95 | none | **97** | +2.25 |
| 03 route-correct | high-stakes → **high-stakes** ✓ (via Phase 0, not re-class) | 40 | 100 | 100 | 90 | 78 | none | **80** | −13.25 |

¹ Task 01 `expect` marks *No escaped defects* n/a and reweights (+10 Routing, +10 Gate discipline).

**Suite score = 91.7** (baseline 93.7, **−2.0**). **Escaped defects: 0.**

## Regression section (vs 2026-07-08 baseline)

One dimension dropped >10 points — **Task 03 Routing: 100 → 40**. It is **not caused
by this change** and is not an escaped defect:

- Both runs reached the correct destination (high-stakes, full tier, human GATE 3);
  the anti-regression controls held (GATE 3 was *not* fast-path auto-approved; the
  reduced tier was *not* taken). No control failure.
- The baseline run reached high-stakes *via* the scoped→high-stakes re-classification
  at fast-path step 3.5 — the path task 03's `expect` rewards. This run routed
  high-stakes **at Phase 0 directly**, so no re-classification event and no Deviation
  occurred; the `expect` grants full Routing credit only for the re-classification
  path, hence 40.
- Root cause is routing **non-determinism**, amplified by a fixture artifact: the base
  `auth/auth.go` doc comment literally says hardening is "a high-stakes change (auth
  path)", which primes Phase 0 to classify high-stakes immediately and bypass the
  step-3.5 escalation task 03 is built to regression-test. This is a **new candidate
  follow-up** (de-bias the comment), listed below. Per the suite's own caveat,
  single-run routing swings are noise until confirmed with `--repeat`.

## What the follow-ups did (targeted effects — all landed)

- **Green base + seed (commit 1):** Task 01 **GATE 3 now auto-approves via the fast
  path** — the "tests green" criterion is genuinely satisfied on the green base, which
  the red baseline made impossible (Routing 97→100, Gate 88→95, task 93.2→98). Task 02
  still fails on its seeded precondition and is fixed + proven (task 94.75→97). The
  seed mechanism worked as designed; no task inherited another's red.
- **verify-fix hardening (commit 2):** On **both** bug-fix runs the coder did the
  revert-discriminate swap **in its own process with a guaranteed restore**, delegated
  only test execution to `test-runner` (which never touched source), and re-adjudicated
  a clean tree. Task 03's baseline **revert-discriminate thrash is gone** — its
  Efficiency recovered 65→78 (the residual cost is an unrelated Phase 4 plan-reviewer
  misfire, not the swap). Judges on tasks 02 and 03 explicitly confirmed the hardened
  procedure was honored.

## Observations (candidate follow-ups)

1. **Base `auth/auth.go` comment biases routing (new).** The comment naming the change
   "high-stakes" lets Phase 0 shortcut to high-stakes and skip the step-3.5
   re-classification task 03 exists to test. De-bias the comment (state the behavior,
   not its risk class) so the routing signal must be *inferred*, and/or run task 03
   with `--repeat ≥ 3` to characterize the routing distribution.
2. **Prior fixture/coder items now resolved by this PR:** the red-baseline tension
   (fixed — green base + seed) and the revert-discriminate tool-reliability issue
   (fixed — verify-fix hardening).

## Notes

- Runs dispatched as subagents under the eval-harness preamble (auto-approver at every
  gate; GATE 4 propose-only — nothing written to `~/.claude`, no `capture.sh`). Only
  structured artifacts collected.
- Each task ran against an isolated, git-initialized fixture copy: 01/03 on the green
  base, 02 with its `## Seed` pre-applied.
- Environment artifacts (not scored against the change): fable was out of credits, so
  the by-design fable slots + high-stakes skeptic degraded to opus on task 03; the
  worktree skill was run inside the confined fixture dir rather than a sibling.
