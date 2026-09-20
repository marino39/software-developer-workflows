# Scorecard — 2026-09-20 — baseline (tasks 01–03)

**Read the Validity section before using any number here.** This run is a valid
measurement of routing, outcome correctness and **prompt-size cost**, and an
invalid measurement of delegation, review independence and escaped defects.

## Validity — what this environment could and could not run

| Condition | Effect |
|---|---|
| **No Agent/Task tool inside a dispatched subagent** | The driver could not spawn anything. Every named dispatch — `searcher`, `architect`, `coder`, `reviewer` Channel A, skeptic, `test-runner` — ran **inline in the orchestrator's own context**, on Opus rather than the pinned tier. All three drivers detected this themselves and declared it. |
| **`codex` not installed** | All three two-head passes (Phase 1.2 lens, Phase 2.1 adversarial review, Phase 6.3 Channel B) ran single-vendor. Phases 1/2 took their named Claude fallbacks; Channel B degraded free. |
| **No `superpowers:*` skills** | Worktree isolation came from the harness fixture copy — the suite's own standing caveat. Phase shapes followed by hand. |
| **No remote in the fixtures** | Outcome is local-kept; Phase 6.5 (CI) unreachable; `verify-fix` §5 unreachable. |

Consequences: **`No escaped defects` is not scored** — the reviewer and the skeptic
shared the author's context, so an independent-review measurement does not exist
here. `dispatch-trace.sh` reports 0 units on every driver, which is the defect, not
a result. The **delegation floor was breached by construction** on all three runs.

## Per-task

| Task | Route | Outcome | Gate behavior | Verdict vs `expect` |
|---|---|---|---|---|
| 01 doc-only | scoped, never escalated ✓ | README `## Usage` added; **zero `.go` changed** ✓; build+test green ✓ | **GATE 3 did NOT auto-approve** | **FAIL** — the expect block fails the run if GATE 3 does not auto-approve |
| 02 bugfix | scoped, never escalated ✓ | one-line loop fix; suite green ✓; full `verify-fix` revert-discriminate proof ✓ | GATE 3 auto-approved ✓ | **PASS** |
| 03 route-correct | **high-stakes at Phase 0** ✓ | `ValidateToken("Bearer ")` → false; 8-case table test; green ✓ | **full tier + human GATE 3** ✓ | **PASS** — the Proposition-#4 control held |

### Task 01's failure is self-inflicted ceremony, not a product defect

The plan-lite wrote itself a cosmetic budget (`≤ 15 added lines`). The idiomatic
gofmt two-group import needs 18. The run kept the idiomatic style and recorded the
3-line overshoot as a deviation from the approved artifact — which, per fast-path
step 4, voids auto-approval and forces a human gate. The product diff is exactly
right; the run paid a human gate for a self-imposed presentation number.

This is a **leanness defect in the fast path**: the auto-approve signal is diluted
by a criterion that buys no safety. The run's own retro reached the same conclusion
independently. Candidate fix (not applied — behavior-affecting, owes its own
scorecard): plan-lite states *content* contracts, never cosmetic size caps.

## Orchestrator cost — and the finding that matters

`evals/context-trace.sh` over each driver transcript, against the 2026-07-20 trace
(same three tasks):

| Task | Turns (7-20 → 9-20) | Ctx mean | Ctx hi-water | **First-turn floor** |
|---|---|---|---|---|
| 01 | 71 → 44 | 57,329 → 78,927 | 81,251 → 109,402 | 27,368 → **40,963** |
| 02 | 57 → 62 | 61,319 → 85,008 | 88,431 → 125,770 | 27,406 → **41,055** |
| 03 | 95 → 54 | 73,729 → 86,273 | 109,888 → 116,760 | 27,370 → **41,169** |

Turn and mean-context deltas are **confounded** by the missing delegation (inline
work moves subagent tokens into the orchestrator's context and changes turn shape),
so do not read them as a trend.

**The first-turn floor is not confounded.** It is the fixed overhead before any work
— command file, agent descriptions, harness preamble — and it is near-identical
across all three tasks in both traces (±200 tokens), exactly as a fixed cost should
be. It grew **27.4k → 41.0k, +50%**.

That is almost entirely prompt growth, and it is attributable by `git`:

| | 2026-07-20 | 2026-09-20 | Δ |
|---|---|---|---|
| `commands/new-task.md` | 35,368 B / **5,236 w** | 56,280 B / **8,544 w** | **+63%** |
| measured first-turn floor | 27.4k tok | 41.0k tok | **+50%** |

Every intervening commit that touched the file **added** words — the 2026-08-11
cost pass (+2,636 B), its P2–P6 follow-up (+3,635 B), the 2026-09-07 model tuning
(+3,291 B), the cross-vendor allocation (+4,832 B). Not one reduced it.

**So every pass that cut dispatches grew the prompt, and nothing measured the second
axis.** The complexity ledger counts *constructs*, not *words*; the lint checked
*consistency*, not *size*. Dispatch cuts are paid once per run; prompt words are
paid on every turn of every run.

In dollars this is modest — ~15k tokens at Opus's $0.50/MTok cache read over ~50
turns is ~$0.35/run — but it is **monotonic and unbounded**, which is the actual
problem.

**Applied in response:** `evals/lint.sh` **Check 9** + `evals/size-budget.txt`, a
per-file word ratchet set at 2026-09-20 sizes +2%. Growth is still allowed; it now
has to be deliberate, because the budget bump appears in the same diff. Verified to
fail on both growth and a missing budget row.

## Regressions vs baseline

No dimension is comparable to the 2026-07-20 scorecard — that run had working
delegation and this one did not. **No suite score is claimed.** Treat this as a
cost-and-controls probe, not a scored suite run.

One control **held** under the degraded conditions, which is worth recording: task
03 routed high-stakes at Phase 0, took the full tier, and refused the fast-path
auto-approve — the Proposition-#4 regression test passes even with review
independence removed, because routing is an orchestrator decision that delegation
does not touch.

## Owed

- A re-run of tasks 01–03 in an environment where a driver can spawn subagents,
  before any turn/mean-context comparison is trusted.
- Task 01's plan-lite cosmetic-cap fix, with its own scorecard.
- The `verify-scaffold-trim` A/B — still unrun; it needs working delegation.
