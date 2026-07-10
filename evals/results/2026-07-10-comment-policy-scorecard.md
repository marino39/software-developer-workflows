# Scorecard — coder comment-policy (2026-07-10)

Behavior-affecting change under test: `agents/coder.md` gains a `<comment-policy>`
bullet (comments explain WHY not WHAT; private members no doc by default; public
interfaces ≤~3 lines; no per-line narration; escape hatch for non-obvious intent;
match surrounding density). New frozen test: `evals/tasks/17-comment-discipline.md`.

- Command: `/workflow-eval --tasks 17`
- Driver: `/new-task "add calc.Median + TestMedian"` on `fixtures/base` (isolated copy).
- Judge: fresh `reviewer`, fed only run artifacts + task 17 `expect` block + rubric.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (reference integrity ×2, route/tier,
phase completeness, gate-format, agent contracts, complexity ledger, learnings
bullets). Exit 0.

## Layer 2 — outcome-eval

| Task | Routing | Outcome | No-escaped-defects (comment lens) | Gate discipline | Efficiency | Task score | Escaped |
|---|---|---|---|---|---|---|---|
| 17 comment-discipline | 100 | 100 | 100 | 95 | 100 | **99.25** | 0 |

Suite score (this run): **99.25** (single task, `--repeat 1`).

### Comment-discipline verdict (the point of this run)

The coder produced on-policy comments with no removal pass:

- Exported `Median` → **one-line** doc comment (`// Median returns the median of
  xs, or 0 if xs is empty.`) — within the ≤~3-line cap, matches peer `Sum`.
- Unexported `sortedCopy` → **no doc comment** — the private-default-none rule held.
- Function bodies → **zero inline narration** of control flow.
- Comment density (~1 doc line / 22 added lines) does not exceed the `calc.go` peer.
- The WHY escape hatch was not needed (no borderline comment), so it neither
  over- nor under-fired here.

None of task 17's three ≤40 penalty triggers (doc on unexported helper; line-restating
inline comment; >~3-line public doc) fired.

## Regression

- **Task 17**: baseline established, no prior scorecard (new frozen task).
- **Scope note (honest):** only the directly-affected/added task was run. The
  `coder.md` edit touches every `/new-task` run, but the other frozen tasks
  (01 doc-only, 02 bugfix, 03 route, 04/05 iterate) have `expect` blocks that do
  not assert on comments, so the policy is not expected to move their dimensions —
  it constrains comment output, not routing/correctness/gates. No full-suite
  regression sweep was run this pass; the next `/workflow-eval` (all tasks) will
  confirm no collateral drop. No dimension on any run so far dropped >10 pts.

## Notes

- Reduced review tier fired correctly (58-line diff, not high-stakes): Channel A +
  combined C1+C3, codex skipped (small diff); 0 Must-fix, 1 out-of-scope Should-fix
  (theoretical int-overflow in even-average, matches peer `Sum`'s unguarded-int
  pattern — correctly deferred, not a comment-policy artifact).
- No escalations; both by-design fable slots unused. First-pass PASS.
