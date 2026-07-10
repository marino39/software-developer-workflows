# Scorecard — 2026-07-10 — explain (task 10)

First live outcome-eval of the new `/explain` command (Mechanism case). Establishes the
baseline; not comparable to the `/new-task` suite (different driver / acceptance check).

Command: `/workflow-eval --tasks 10` · repeat 1 · driver `/explain "How does auth.ValidateToken work?"`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS.

## Layer 2 — task 10

Fixture: `fixtures/base` (green; seeded only as a git repo for the read-only assertion).
Question targets `auth.ValidateToken`, whose source carries a documented empty-token
edge case (`NOTE` comment) — a grounding-contract test.

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing (classification) | 25 | 100 | Correctly resolved to **Mechanism (case 2)** with the classification header + scope note stated. |
| Outcome correctness | 25 | 100 | Followed the Mechanism contract (summary → cited steps → I/O → edge cases); every claim carries a `file:line` in `auth/auth.go` (judge verified each against source); surfaced the documented empty-token quirk from the NOTE; reported "no callers/tests" as **not-found**, not fabricated. |
| No escaped defects | 20 | n/a | `/explain` surfaces understanding, not a seeded defect. Renormalized away. |
| Gate discipline | 15 | n/a | No gates. Renormalized away. |
| Efficiency | 15 | 100 | **The cost check:** searcher-tier only — in fact **zero subagents** (2 file reads + 1 grep), no `architect`/opus, synthesis **inline**. ~33.6k tokens, 5 tool_uses — the cheapest run in the suite. |

**Task score (renormalized over 65): 100.**

**Escaped defects: n/a.**

## Observations

- **Grounding contract held under test.** The run cited every claim, surfaced the NOTE'd
  empty-token quirk *from the code* (not invented), and reported the absent callers/tests
  as "not found in scope" rather than fabricating usage — exactly the anti-hallucination
  behavior the contract demands.
- **Cost discipline confirmed.** The run needed no subagents at all for a small Mechanism
  question and never reached for `architect`/opus — the design's whole premise (cheap by
  construction) held. On a larger codebase the parallel searcher sweep would engage; this
  fixture exercises the floor.

## Verdict

`/explain` works end-to-end on a Mechanism question: correct classification, a
contract-shaped grounded answer, the documented edge case surfaced honestly, and the
cheapest execution in the suite. Functional + quality n=1 pass.

Owed (per the ledger row): higher `--repeat`, and a fixture **per case** — especially the
**Why** case (CLAUDE.md + comments + git `log`/`blame`), the one raw exploration can't do
— to prove each of the seven output contracts holds and each classification is stable.
