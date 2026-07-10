# Scorecard — 2026-07-10 — triage-issue feature path (task 08)

Live outcome-eval of `/triage-issue` on a **feature** request — the companion to the
bug-path run (`2026-07-10-triage-issue`, task 07). Establishes the feature-class
baseline and specifically tests the light-design decision (2(a)): triage produces ONE
approach sketch and defers the full Phase 1 brainstorm to `/new-task`.

Command: `/workflow-eval --tasks 08` · repeat 1 · driver `/triage-issue --local`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 08

Fixture: `fixtures/base` unmodified (green; no seed). `calc.Sum` exists as the peer
pattern; the requested `calc.Product` does not — the run must classify, mirror the
convention, and scope, without implementing.

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing (classify + route) | 25 | 100 | Classified **feature**, routed **scoped** with rationale (single additive pure function ~10 LOC, no high-stakes category, well under 200 lines). |
| Outcome correctness | 25 | 100 | Report well-formed (classification · route · investigation · approach sketch · acceptance criteria · scope/handoff); explicitly mirrors the `calc.Sum` convention found via investigation — and correctly uses the **multiplicative** identity (empty → 1), not a blind copy of Sum's additive `0`. No file edited. |
| No escaped defects | 20 | n/a | Feature request — no seeded defect. Renormalized away. |
| Gate discipline | 15 | n/a | Local mode has no gates. Renormalized away. |
| Efficiency | 15 | 100 | **The feature-specific check:** exactly ONE approach sketch; the full three-lens brainstorm was explicitly deferred to `/new-task` Phase 1, not run inline (no double-design). No `debugger`; 7 tool calls total — light. |

**Task score (renormalized over 65): 100.**

**Escaped defects: n/a** (feature).

## Observations

- **Light-design path confirmed.** The whole point of decision 2(a) — triage does not
  pay for design twice — held: one architect approach, brainstorm deferred, 7 tool
  calls. A run that had spawned the full 3-architect fan-out would have scored
  Efficiency ≤ 40; it didn't.
- **Convention understanding, not duplication.** The run adapted the identity element
  (Sum's `0` → Product's `1`) and proposed `TestProduct`/`TestProductEmpty` mirroring the
  existing test shape — evidence the investigation informed the sketch rather than a
  literal copy.
- **Clean read-only** with no seed caveat: unlike task 07 (uncommitted seed), task 08 has
  no seed, so `git status` was genuinely empty — a cleaner read-only assertion.

## Verdict

`/triage-issue`'s feature path works: correct classification + route, real convention
investigation, a light single-approach sketch with acceptance criteria, a scoped
`/new-task` handoff, and no implementation. Together with task 07 (bug, 100), the command
is now MEASURED on both its paths at n=1 — bug and feature both 100, 0 escaped, correct
light/heavy split. Raise `--repeat` before treating either as more than a single sample.
The `/new-task` manifest-consumption seam remains the one owed follow-up.
