# Research: dispatch underspecification and the sonnet one-shot rate

Date: 2026-07-29. Status: **S1 + S4 implemented** on this branch (coder
ambiguity policy; `evals/dispatch-trace.sh` + its wiring into the
`/workflow-eval` Collect step and the scorecard), with the evidence apparatus
authored alongside them — eval task 23 (thin plan step) and the
`ambiguity-policy-off` ablation variant. S2, S3, S5 are specified here and
**not yet implemented**. Owed per the modification protocol: a live
`/workflow-eval` scorecard for the behavior-affecting coder edit,
`--contracts --agent coder` for the changed Output contract, and the task-23
A/B at `--repeat ≥ 3`. The live eval cannot run in the authoring environment,
so it rides the PR review. Stated ledger-style where a change owes protocol
cost (per `CLAUDE.md`).

## Problem

Dispatches to the sonnet tier are underspecified. The agent cannot finish from
what it was given, so it returns a question, a blocker, or off-target work; the
orchestrator absorbs that return, re-decides, and re-dispatches. Each such
**roundtrip** costs an orchestrator turn on the most expensive seat in the
system — and the orchestrator turn is what the user is paying for, not the
sonnet call it re-issues.

This was reported from live use and is confirmed by the user's cost telemetry
(2026-07-29, six-month window). The numbers below are that dashboard.

### By model

| Model | Cost | Cache | Calls | 1-shot |
|---|---|---|---|---|
| Opus 5 | $264.26 | 95.4% | 2022 | 73.5% |
| Opus 4.8 | ~$238.73 | 96.1% | 1816 | 92.8% |
| **Sonnet 5** | **$146.01** | 96.2% | **5009** | **53.8%** |
| Haiku 4.5 | $25.49 | 90.0% | 3185 | — |
| Fable 5 | $23.98 | 86.8% | 91 | — |
| GPT-5.5 | $13.86 | 92.3% | 115 | — |
| Cursor (auto) | ~$3.98 | 0.0% | 81 | — |

Sonnet has the **lowest one-shot rate of any measured tier** — 53.8% against
Opus 4.8's 92.8% — on the **highest call volume** of any paid tier (5009). That
is ~2300 dispatches that did not resolve in one shot.

Opus 5's lower 73.5% is largely an artifact and should not be read as the same
failure: the orchestrator is multi-turn **by design** (every gate ends a turn;
Phase 6.5 ends a turn waiting on CI), so non-1-shot is its expected shape. A
*subagent*, by contrast, has one job — one dispatch, one return. For the sonnet
tier, non-1-shot is a defect rate.

### By activity

| Activity | Cost | Turns | 1-shot |
|---|---|---|---|
| **Delegation** | **$397.94** | 291 | **57%** |
| Testing | $79.31 | 284 | — |
| Exploration | $73.36 | 327 | — |
| Coding | $59.67 | 88 | 100% |
| Feature Dev | $34.80 | 58 | 90% |
| Debugging | $33.62 | 54 | 82% |
| Git Ops | $17.58 | 30 | — |
| Conversation | $7.80 | 58 | — |
| Refactoring | $5.22 | 9 | 71% |
| Brainstorming | $2.86 | 12 | — |
| General | $2.60 | 11 | — |
| Build/Deploy | $1.56 | 3 | — |

Delegation is **55.6% of total spend** ($397.94 of $716.32) and has the **worst
one-shot rate of any activity that reports one** — 57%, against Coding's 100%,
Feature Dev's 90%, Debugging's 82%. It is simultaneously the biggest bucket and
the least reliable one: the worst quadrant.

The activity column and the model column each partition the same $716.32 total.
The agent-type column below sums to $395.21 — within $2.73 of the Delegation
bucket — so **Delegation ≈ the entire subagent fleet**, and its 57% is the same
failure the 53.8% is, seen from the caller's side.

### By agent type

| Agent | Calls | Cost | $/call |
|---|---|---|---|
| **coder** | **4486** | **$178.35** | $0.040 |
| architect | 519 | $77.45 | $0.149 |
| reviewer | 1620 | $76.25 | $0.047 |
| general-purpose | 326 | $18.68 | $0.057 |
| searcher | 2185 | $18.64 | $0.009 |
| debugger | 235 | $12.73 | $0.054 |
| test-runner | 890 | $7.81 | $0.009 |
| Explore | 261 | $3.77 | $0.014 |
| researcher | 80 | $1.53 | $0.019 |

`coder` alone is **25% of all spend** — more than architect and reviewer
combined. It is also the agent with the thinnest Input contract and the only one
instructed to bounce on ambiguity. The highest-volume, lowest-specified,
STOP-on-doubt agent is exactly where the money is.

Two secondary readings:

- **This is not a cache problem.** Sonnet's cache hit rate is 96.2%. The
  re-dispatches are real new work, not cold re-reads. "Prompt caching will
  absorb it" is not an answer here.
- **~587 calls escape the defined agent set.** `general-purpose` (326) and
  `Explore` (261) are not among this repo's seven agents, so they have no
  Input/Output contract at all — and `general-purpose` costs more per call than
  `coder`. Whether that is the workflow falling back when no defined agent fits,
  or use outside `/new-task`, is unresolved (see S5).

## Where the underspecification comes from

Four seams, all in this repo's own files.

**1. The agent-tool interface (ACI) is one-sided.** Every agent declares an
`## Input contract`; lint Check 5 enforces that it *exists*; Layer 3
(`--contracts`) tests that the agent honors its **Output** contract. Nothing —
lint, eval, or instruction — checks that a *dispatch* supplied the callee's
required Input fields. Input contracts are documentation the caller is never
obliged to read.

**2. `coder`'s required input is one field.** `plan_slice` (`agents/coder.md`) —
a plan path plus step numbers. No acceptance criterion, no exact verification
command, no scope boundary, no "context already established, don't re-derive."
`new-task.md` Phase 5 step 2 says to pass "only run-specific context the file
lacks", which leaves what is *lacking* to fresh orchestrator judgment on every
one of those 4486 dispatches.

**3. The STOP-vs-assume asymmetry is backwards on cost.** `architect` — the
*expensive* agent — carries the don't-stall clause: "If requirements are
ambiguous, list the ambiguity and your assumption; don't stall." The cheap
agents have the opposite or nothing: `coder` says "If the plan is wrong or
blocked, STOP and report the conflict"; `reviewer` and `researcher` have no
ambiguity rule at all. So the tier whose returns are cheapest to produce is the
tier instructed to bounce, and each bounce is charged at orchestrator rates.

**4. Phase 4 checks coverage, not sufficiency.** The mapping table proves *every
design decision → a plan step* and *every step → a verification*. It never asks
whether a step is **implementable by a sonnet coder without asking**. A thin step
passes GATE 2 and is then rediscovered once per coder, through the orchestrator,
every time.

Note what is **not** the lever: escalating `coder`'s model. The ladder already
forbids it ("don't escalate model; route to debugger instead") and it is the
wrong diagnosis — this is input quality, not capability.

## Proposed changes

Ordered by leverage against the telemetry above.

### S1 — coder assume-and-proceed + batched questions (implemented)

Replace `coder`'s blanket STOP with a two-class rule:

- **Hard stop** (report, do not improvise): the plan contradicts what the code
  actually is; satisfying it needs an out-of-scope edit; or the action is
  destructive/irreversible.
- **Everything else**: proceed under an explicit stated assumption, recorded in
  the return, and let review adjudicate. A wrong assumption caught in review
  costs one reviewer pass; a bounce costs an orchestrator turn.

And when a question genuinely must come back, **batch it**: return *all* open
questions at once, each with the default the coder would proceed on, so the
orchestrator answers with a single "defaults confirmed" instead of N sequential
turns. This turns an N-roundtrip loop into 0 or 1.

Targets the 4486-call agent directly. Costs nothing per dispatch.

### S2 — dispatch brief, coder and reviewer only (not implemented)

The caller-side mirror of the Input contract: a short block on every spawn
carrying `done_when` (the exact command or observable that ends the task),
`scope_bounds` (files in play + explicitly out of bounds), `context_pointers`
(paths and digests already established — do not re-derive), and `on_ambiguity`
(assume-and-record vs stop). Lives once in `commands/new-task.md` and is
referenced by the sibling commands, the way **Review loop conventions** already
is.

The cost asymmetry justifies building this at full width rather than minimizing
it: a sonnet call averages $0.029, a delegation turn $1.37. Scoped to `coder`
(4486 calls) and `reviewer` (1620); `researcher` at 80 calls and $1.53 is noise
and stays out.

### S3 — Phase 4 dispatch-readiness column (not implemented)

Extend the Phase 4 mapping table with a third column: each step names its files,
its interface contract, and its exact verification command. An unready row fails
the phase exactly as an unmapped row does. Zero new machinery — same reviewer,
same pass — and it is where the fix compounds: one architect revision beats N
coder roundtrips.

### S4 — measure it: `evals/dispatch-trace.sh` (implemented)

The problem is currently unfalsifiable in-repo: `context-trace.sh` measures
context size, `delegation-trace.sh` measures inline-vs-dispatched, and nothing
counts roundtrips. The new script computes, per agent type, the **one-shot
rate** — a dispatch that returns without a re-dispatch of the same work unit —
plus the re-dispatch and repeat-unit counts behind it.

It deliberately computes the same quantity the user's dashboard reports, so a
scorecard delta is directly comparable to the next screenshot. Same
deterministic Layer-1 tier as the other two traces: no LLM, no network.

**Target:** Sonnet from 53.8% toward Opus 4.8's 92.8%. Even 75% removes ~1000
re-dispatches at current volume.

### S5 — the contract-less 587 (not implemented, unscoped)

Establish whether the `general-purpose` (326) and `Explore` (261) calls are the
workflow falling back when no defined agent fits. If so, that is a missing agent
— and it is invisible to lint, which only checks the seven that exist.

## Measure-first / owed evidence

Per `CLAUDE.md`, in tiers:

- **Lint** — runs on every commit; S1 and S4 pass it.
- **Live scorecard** — owed for S1 (behavior-affecting: it changes how a coder
  responds to an underspecified slice) and for S2/S3 when they land.
- **Contract test** — `--contracts --agent coder` is owed for S1: the Output
  contract gained `assumptions` and redefined `open_questions`, and
  `evals/contracts/coder.md` was updated in the same change per the protocol.
- **Ablation** — S1's variant is `ambiguity-policy-off` (authored; A/B not yet
  run), which restores the pre-change coder rule by subtraction. S2 will owe a
  `dispatch-brief-off` variant of its own. Both must be measured with
  `dispatch-trace.sh` on the one-shot rate, not only on the five rubric
  dimensions, because the rubric has no dimension that sees a roundtrip
  (Efficiency sees cost, but a roundtrip inside a passing run does not move a
  dimension). A roundtrip is a discrete event, so n=1 proves direction only —
  run at `--repeat ≥ 3`.
- **Eval task** — task 23 (`evals/tasks/23-thin-plan-step.md`) is the case where
  the rate can actually move: `calc.Mode` with the empty-slice result and the
  tie-break deliberately unpinned, both closable from the package's own
  conventions and both below plan granularity, so the thinness survives Phase 3
  planning and reaches the coder. Its control is the roundtrip, not the
  resolution chosen — grading a particular answer would test taste; grading the
  bounce tests the policy.

  The task also guards the policy's **own** failure mode: an assumption that
  ships silently is not a win. Both resolutions must reach `assumptions` and
  GATE 3's Key decisions, and be covered by `TestMode` — review cannot
  adjudicate what it cannot see, and the whole safety argument for
  assume-and-proceed is that review still adjudicates.

The single sharpest number to re-check after these land is the one at the top:
**Sonnet 5's one-shot rate.** If it has not moved, S1–S3 did not work.
