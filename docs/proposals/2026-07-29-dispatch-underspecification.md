# Research: dispatch underspecification and the sonnet one-shot rate

Date: 2026-07-29. Status: **S1–S4 implemented** on this branch (coder ambiguity
policy; Dispatch brief; Phase 4 dispatch-readiness; `evals/dispatch-trace.sh` +
its wiring into the `/workflow-eval` Collect step and the scorecard), with the
evidence apparatus authored alongside them — eval task 23 (thin plan step) and
three ablation variants (`ambiguity-policy-off`, `dispatch-brief-off`,
`dispatch-readiness-off`), deliberately separable so the agent half, the caller
half, and the upstream check can be attributed independently. **S5 remains
unimplemented** (and unscoped).

**MEASURED at both tiers, 2026-07-29 — and the central claim did not survive.**
Four experiments — contract tier, lifecycle tier, the strand probe, and the task-24
readiness A/B — report **zero underspecification roundtrips across 26 runs, in
every arm**. Final disposition: **S1 kept** (re-sourced as a disclosure guard,
measured 3/3 vs 1/3); **S2 CUT 2026-08-10** (no support at any tier, the one
change that added tokens per dispatch — reverted per CLAUDE.md rule 3, keeping
only the reviewer dual-mode contract fix it surfaced); **S3 kept,
ablation-queued** (its A/B was confounded, not negative, and the strand probe's
contract-divergence failures are exactly its remit); **S4 kept** (corrected
twice, baseline established). The **Measurement** section below supersedes the
framing in the sections above it.

`dispatch-trace.sh` itself was found defective by its first lifecycle run and
corrected (bounce-gated `rtrip` vs by-design `iter`); the numbers here are post-fix.

Still owed: a route-controlled S3 test (nothing in the suite reliably reaches
Phase 4 — task 24 routes scoped half the time, and the readiness variant's own
delta primed routing; it needs a minimal-delta rewrite first), and the one check
no probe here can perform — **what a non-1-shot Sonnet call in the live dashboard
actually is**. 26 runs found no re-dispatch-after-bounce anywhere, so if the
dashboard's "1-shot" counts multi-turn tool use inside a single dispatch, or
API-level turns rather than work units, the 53.8% describes normal worker-agent
shape, not a defect — and that determines whether anything further is owed at
all. Stated ledger-style where a change owes protocol cost (per `CLAUDE.md`).

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

### S1 — coder assume-and-proceed + batched questions (implemented; MEASURED — see Measurement)

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

### S2 — dispatch brief, coder and reviewer only (CUT 2026-08-10 — measured at two tiers plus the strand probe, no support at any; reverted per CLAUDE.md rule 3. The reviewer dual-mode Input contract fix it surfaced is retained; the answer-batched-in-one-re-dispatch rule moved to Token hygiene as S1's caller half)

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

Implementing it surfaced a live instance of seam 1: **Phase 4 dispatches a
`reviewer` against a plan, with no diff in existence**, while `agents/reviewer.md`
declared `diff_range` Required. A required field that is unfillable by design at
one of its own call sites is exactly the asymmetry this section is about — the
contract was never checked from the caller's side, so the mismatch sat there
undetected. The Input contract is now mode-based (`diff_range` for diff review,
`artifact_paths` for artifact review), which makes Phase 4's dispatch legal and
the "fill every Required field" rule satisfiable everywhere it is asked for.

This is also the **only change in the set that adds tokens per dispatch**, so
`dispatch-brief-off` is the A/B that can falsify the whole approach: the brief
pays iff the orchestrator turns it avoids outweigh the prompt bytes it adds.

### S3 — Phase 4 dispatch-readiness column (implemented; first indirect support from the strand probe; lifecycle test owed via task 24)

Extend the Phase 4 mapping table with a fourth column: each step names its files,
its interface contract, and its exact verification command. An unready row fails
the phase exactly as an unmapped row does. Zero new machinery — same reviewer,
same pass — and it is where the fix compounds: one architect revision beats N
coder roundtrips. A decision the plan *deliberately* leaves to the coder is ready
iff it says so; delegating a decision is fine, leaving it silently open is not.

**Confound to watch in its A/B:** with S1 in force a thin step no longer bounces
— the coder assumes and proceeds. So S3's value may show up as reduced
*assumption volume* (decisions made by an architect holding the design doc rather
than a coder holding one slice) rather than as fewer roundtrips. If escaped
defects come out equal across arms, S3 is buying predictability, not correctness,
and its ledger row must be re-sourced to say so.

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

## Measurement (2026-07-29)

### Contract tier (Layer 3)

S1 has been measured; S2–S4 have not. Full result:
`evals/results/2026-07-29-ambiguity-policy-ab-scorecard.md`. Summary:

**The roundtrip claim did not reproduce.** n=3/arm × 2 stimuli, file-level
ablation of `agents/coder.md`: **0 bounces in every arm**. The pre-change rule
("STOP if the plan is wrong or blocked") does not fire on a merely *thin* slice —
an unpinned detail is neither wrong nor blocked — so at single-dispatch scope
there was no bounce for S1 to remove.

**Disclosure is what moved.** With the policy, the tie-break is flagged as
unpinned 3/3 vs 1/3 without (the other 2 state the rule as bare fact, indis-
tinguishable from a plan requirement being reported back); the empty-slice choice
is named 2/3 vs 0/3, in both the report and the durable doc comment. Outcomes
identical across all 12 runs — green, 0 escaped defects, no behavior delta.

So S1 is justified as a **silent-resolution guard**, not a cost lever. That is the
safety half of the argument rather than the one it was sold on: assume-and-proceed
is only defensible if review can still adjudicate the assumption, and 0/3
disclosure of the empty-slice choice in the ablated arm is precisely the failure
mode this proposal warned about in S3's confound note.

### Lifecycle tier (Layer 2) — measured the same day

The lifecycle layer turned out to be runnable here after all: a **top-level**
`claude -p` session has the Agent tool (only `claude -p --agent` does not), so the
driver really fans out. Task 23, baseline vs `dispatch-brief-off`, n=2/arm —
scorecard `2026-07-29-dispatch-brief-lifecycle-ab-scorecard.md`.

**`rtrip 0` in all four runs.** The roundtrip did not occur at lifecycle scope
either, briefed or unbriefed. Both S1's and S2's cost claims are now unsupported
at the tier each was supposed to act on. Bounces did happen (baseline 0/2 runs,
variant 2/2) but none caused a re-dispatch — the orchestrator absorbed the
question and carried on, which is far cheaper than this proposal assumed.

**No verdict on S2:** one variant run took the standard route (179 turns, 138k
context) against fast path for the other three — the known cold-routing
bimodality — so at n=2 arm and route are inseparable. The one non-cost signal is
that the same run alone shipped the empty-slice case untested (0 vs 2/4/4).

**And the metric itself was wrong.** The first pass reported 4 roundtrips on that
run; all were false — the Phase 1 lens fan-out issued serially, plus two Phase 2
revise→re-review cycles. `dispatch-trace.sh` counted any later-turn repeat as a
roundtrip, but every review loop in this workflow is a later-turn repeat, so on a
standard-route run it was structurally guaranteed to indict the loops. Now gated
on a preceding bounce (`rtrip` vs `iter`). **Re-dispatch alone does not mean
underspecified** — that is the sharpest thing this exercise produced.

### Stranding probe (Layer 3, purpose-built)

That probe was built and run: `evals/fixtures/svc` (api → store + validate) and a
thin 3-step plan whose middle step must match on error values the *other two steps
define*, with those slices stated to be in flight. The gap is provably non-local —
nothing on disk settles it. n=3/arm, briefed vs bare
(`2026-07-29-strand-probe-scorecard.md`).

**The probe works and the coders are genuinely stranded** — they say so
themselves ("if step 1's author names it differently, `api/api.go` line 21 is the
one-line fix"). Three findings:

1. **Still zero bounces (0/6).** Cumulative: **22 runs, three tiers, no
   underspecification roundtrip** — now including conditions engineered to force
   one. The proposal's central mechanism does not reproduce.
2. **The real failure mode is contract divergence, not orchestrator turns.** All
   6 shipped code unverifiable until siblings land: 4/6 guessed a sentinel that
   may not exist, 2/6 declined to guess and *silently dropped the plan's 500
   requirement*. The cost lands at integration, not in a turn.
3. **The brief changes nothing, and structurally cannot.** Briefed and bare are
   identical on every axis (2/3 vs 2/3, 1/3 vs 1/3, 0 vs 0). The brief transmits
   what the orchestrator knows; a missing cross-slice contract is not known to the
   orchestrator either unless the plan pinned it.

**Where that leaves the proposal.** The diagnosis in *Where the underspecification
comes from* is partly vindicated and partly wrong. Seam 4 (Phase 4 checks coverage,
not sufficiency) is real and is where the only fixable version of this failure
lives — S3's territory. Seams 2 and 3, and the S1/S2 remedies built on them, aimed
at a roundtrip that does not occur at this workload. S1 survives on disclosure;
**S2 has no supporting measurement at any tier and is the one change that adds
tokens to every dispatch.**

The telemetry remains unexplained rather than refuted. What these 22 runs rule out
is the mechanism as stated — a coder handing work back for want of a detail. What
they cannot rule out is a different mechanism behind the same 53.8%: review-loop
iteration, multi-turn refinement, or work far larger than any fixture here. The
next honest step is to look at what a non-1-shot sonnet call in the real telemetry
actually *is*, rather than to keep engineering probes for a mechanism that has
declined to appear three times.

Two corrections the measurement forced, both applied:

- The `Product` contract stimulus elicited nothing from either arm (its empty-slice
  case is resolved incidentally by `product := 1`, so no coder perceives a
  decision). The expected-fields spec written for it — "`assumptions` names the
  empty-slice choice, not `none`" — **failed 3/3 in the baseline**. It was authored
  from intuition and was wrong. Stimulus switched to `Mode`.
- Task 23's primary control (`redisp 0` / 1-shot 100%) is satisfied by **both**
  arms, so it cannot justify S1. Primary and secondary controls were swapped:
  disclosure leads, the roundtrip becomes a regression guard.

A harness defect is recorded in the scorecard: Layer 3 isolates the fixture *copy*
but not the agent's *reach*, and an ambiguous module name ("the `evalfixture`
module", no path) sent 2 of 3 coders into the repo's own fixture to edit it. That
attempt was discarded, the fixture reverted, and `evals/contract-ab.sh` now pins
each run to its directory and asserts repo cleanliness after every dispatch.

## Measure-first / owed evidence

Per `CLAUDE.md`, in tiers:

- **Lint** — runs on every commit; S1 and S4 pass it.
- **Live scorecard** — owed for S1 (behavior-affecting: it changes how a coder
  responds to an underspecified slice) and for S2/S3 when they land.
- **Contract test** — `--contracts --agent coder` is owed for S1: the Output
  contract gained `assumptions` and redefined `open_questions`, and
  `evals/contracts/coder.md` was updated in the same change per the protocol.
- **Ablation** — three variants are authored, none yet run: `ambiguity-policy-off`
  (S1, restores the pre-change coder rule by subtraction), `dispatch-brief-off`
  (S2), `dispatch-readiness-off` (S3). They are deliberately **separable** — the
  agent half, the caller half, and the upstream check each ablate alone, because
  ablating them together would move the rate without attributing the movement.
  All must be measured with
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
