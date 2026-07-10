# Scorecard — 2026-07-10 — triage-issue (task 07)

Live outcome-eval of the new `/triage-issue` command against its frozen fixture
(`evals/tasks/07-triage-issue.md`). First `/triage-issue` run — establishes the
baseline for this command; not comparable to the `/new-task` suite scorecards
(different driver, different acceptance check).

Command: `/workflow-eval --tasks 07` · repeat 1 · driver `/triage-issue --local`

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (0 failures).

## Layer 2 — task 07

Fixture: `fixtures/base` with the calc off-by-one reintroduced (same seed as task 02);
the `## Issue` block stands in for a fetched bug report. The run must classify, route,
prove the repro, and root-cause — read-only, no fix applied.

| Dimension | Weight | Score | Justification |
|---|---|---|---|
| Routing (classify + route) | 25 | 100 | Classified **bug**, routed **scoped** with rationale (single-function off-by-one, ~1-line diff, no high-stakes category — auth package correctly noted as an unrelated red herring). |
| Outcome correctness | 25 | 100 | Report well-formed (classification · route · repro · root-cause · scope/handoff); root cause pinpoints `calc/calc.go:6` with file:line; no fix diff proposed, no file edited. |
| No escaped defects | 20 | 100 | The seeded loop-start bug is exactly what was root-caused, correctly attributed; nothing missed. |
| Gate discipline | 15 | n/a | Local mode has no gates — renormalized away. |
| Efficiency | 15 | 100 | One `go test ./...` repro sufficed; no needless `debugger` escalation for an obvious off-by-one; handoff correctly routed to `/new-task` (cold), not `/iterate`. |

**Task score (renormalized over 85): 100.**

**Escaped defects: 0.**

## Suite

Suite score (this run, 1 task): **100**. Baseline established for `/triage-issue`; no
prior scorecard to diff against.

## Observations

- **Correct read-only discipline under an imperfect seed:** the task-07 seed injects the
  bug as an *uncommitted* working-tree change, so `git status` shows ` M calc/calc.go`
  regardless of what triage does. The run correctly (a) did NOT apply the fix — `calc.go`
  still holds `i := 1` after the run — (b) wrote no new files, and (c) transparently
  flagged that the ` M` entry is the seed, not its own edit. Read-only honored. **Fixture
  polish owed:** commit the seed (as task 06 does) so a future read-only run can assert a
  genuinely clean `git status` rather than relying on the judge's harness note.
- **Discriminating-test reasoning was explicit:** the run noted `TestSumEmpty` does not
  discriminate (0 for both bounds) and only `TestSum` does — the exact revert-discriminate
  judgment `verify-fix` asks for, reached without writing a new test because one exists.

## Verdict

`/triage-issue` works end-to-end on a bug issue: correct classification + route, a proven
repro via the pre-existing discriminating test, a precise `file:line` root cause, and a
scoped `/new-task` handoff — all without touching product code. The ledger row's owed
evidence (classification + root-cause precision) is satisfied for n=1: perfect score, 0
escaped. Raise `--repeat` and add a feature-class fixture before treating the 100 as more
than a single-sample bug-path point. The `/new-task` manifest-consumption seam remains a
separate, owed change.
