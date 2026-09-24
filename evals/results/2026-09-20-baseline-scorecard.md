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

## Orchestrator cost

> **Corrected 2026-09-24.** The first version of this section had two errors. (1) It
> attributed the growth of the first-turn floor (27.4k → 41.0k) to the growth of
> `commands/new-task.md`. The transcripts show the floor is measured **before** the
> driver reads the command file — it is environment overhead (system prompt, tool
> definitions, agent/skill lists, preamble) and is not comparable across the two
> environments. (2) Its turn counts came from `context-trace.sh`, which counted one
> "turn" per content block rather than per API response (~2.6–3.1× too many); the
> script is fixed and the numbers below are recounted.

`evals/context-trace.sh` (fixed) over each driver transcript:

| Task | Turns (responses) | Ctx mean | Ctx hi-water | Floor (pre-Read) | Cold |
|---|---|---|---|---|---|
| 01 | 16 | 80,685 | 109,402 | 40,963 | 0 |
| 02 | 20 | 87,120 | 125,770 | 41,055 | 0 |
| 03 | 21 | 91,327 | 130,282 | 41,169 | 0 |

Turn and mean-context values are **confounded** by the missing delegation (inline work
moves subagent tokens into the orchestrator's context). The two "cold re-entries" the
first version reported on task 01 were an artifact of the same counting bug — the
extra content blocks of the first response, each re-counted as a cache-cold sample.

**What the command file actually costs — measured, not inferred.** The context jump
when the driver's Read of `new-task.md` lands is **~22.6k tokens** on all three runs
(22,626 / 22,715 / 22,636 — the Read result carries line-number prefixes, so it is
larger than the raw ~15k). From then on it is re-read on every turn: **25–28% of the
mean context**. On Opus cache reads over these runs that is ~$0.17–0.23 per run — a
small dollar figure, a large share. And the file grew **5,236 → 8,544 words (+63%)**
between 2026-07-20 and 2026-09-20, with every intervening commit adding words and
none removing any.

**Applied in response:** `evals/lint.sh` **Check 9** + `evals/size-budget.txt`, a
two-way per-file word ratchet — growth must land with a visible budget raise, trims
must be banked by lowering the budget. The first trim under it (2026-09-24, moving
the maintainer-only Model-tuning notes to `docs/`) took `new-task.md` to 7,992 words,
measured at **~22.4k → ~19.0k tokens** in context (−3.4k, −15%, for a 7% character cut — the moved section was token-dense); see the re-run below.

## Task 01 re-run after P6 (2026-09-24)

P6 adds one sentence to fast-path step 3: the orchestrator tells the plan-lite
`architect` to state content contracts, never cosmetic budgets. Validation is a
re-run of task 01, the run that failed on exactly that, under the identical
preamble and the same no-delegation environment. The rule is an orchestrator
instruction, so it is exercised whether or not delegation works.

Pass bar: GATE 3 auto-approves, no `.go` file changed, and the plan-lite states no
numeric size budget.

**Result: PASS.** Route `scoped` throughout; **GATE 3 auto-approved** (all fast-path
criteria held); `README.md` +20/−0 and **zero `.go` files** changed (checked by `git diff`
against the base, not taken from the report); `go test ./...` green; the plan-lite
stated six content contracts (C1–C6: doc-only, heading placement, correct API,
truthful output, snippet compiles and runs, nothing else regresses) and **no numeric
budget** (grep of the plan for line/word caps: 0). The snippet was compiled and run
against the real package and printed `6`. Channel A's one finding (confidence 30) was
dropped by consolidation — correctly, it was out of scope.

Caveat: n=1 on each side, and the failing run's cap was the model's own choice, so
one pass shows the fix is consistent with the outcome, not that it forces it. What
the run does show beyond doubt is that the plan-lite, told to state contracts, wrote
checkable ones — every criterion was verified mechanically.

**Cost, same run:**

| | Before P3/P6 (3 runs) | After (this run) |
|---|---|---|
| Command-file Read result | 56,619 chars | 52,672 chars (−7.0%) |
| Context added by the Read, minus the issuing response's own output | ~22.4k tok (22,388 / 22,419 / 22,632) | **~19.0k tok** (19,023) |
| Turns (responses) vs scoped band ≤ 30 | 16 | 17 — in band |

A file tokenizes the same way every time, so the before/after gap is a measurement
of the file, not run-to-run noise: the three before-runs agree within ~250 tokens.

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
