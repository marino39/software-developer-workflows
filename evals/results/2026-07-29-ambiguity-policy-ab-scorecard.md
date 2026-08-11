# Scorecard — ambiguity-policy A/B, contract tier (2026-07-29)

Ablation of the 2026-07-29 `agents/coder.md` ambiguity policy (two-class hard-stop
rule + assume-and-record + batched questions + the `assumptions` output field).
Variant: `evals/variants/ambiguity-policy-off.md`, applied here as a **true
file-level swap** — the pre-change `agents/coder.md` (`git show bbc0557`) installed
over the live copy for the variant arm, restored after — not a prompt-level
instruction to ignore the rule.

- Tier: **Layer 3 (agent contract), not Layer 2.** This measures a *single* coder
  dispatch, not a `/new-task` lifecycle. See Limits — it is the strongest
  measurement this harness supports, and it is strictly weaker than the claim.
- Harness: `evals/contract-ab.sh`, n=3 per arm per stimulus, 12 runs total.
  Dispatch via headless `claude -p --agent coder` (this session's subagents have no
  Agent tool — the same dispatch-hostile remote harness as the 2026-07-22
  delegation-floor A/B). Isolated `fixtures/base` copy per run; sequential.
- Two stimuli: **Product** (the previous `evals/contracts/coder.md` stimulus —
  empty-slice result unpinned) and **Mode** (task 23's shape — tie-break *and*
  empty-slice unpinned).

## Result — 0 roundtrips in every arm; the difference is disclosure

| Stimulus | Arm | Implemented, green | **Bounced** | `assumptions` field | Decision flagged as *unpinned* | Empty-slice named |
|---|---|---|---|---|---|---|
| Product | baseline | 3/3 | **0/3** | 3/3 (all say `none`) | 0/3 | 0/3 |
| Product | policy-off | 3/3 | **0/3** | 0/3 (no such field) | 0/3 | 0/3 |
| Mode | baseline | 3/3 | **0/3** | 3/3 | **3/3** | **2/3** |
| Mode | policy-off | 3/3 | **0/3** | 0/3 (no such field) | **1/3** | **0/3** |

"Bounced" = the return hands the unit back (non-empty `open_questions`, blocked, or
stopped). **Zero across all 12 runs, both arms, both stimuli.**

Behavior was identical everywhere: every implementation returns `0` for an empty
slice (via `best := 0` / `product := 1` initialization) and breaks ties by
first-to-reach-max. All 12 suites green. 0 escaped defects. 0 files touched outside
`calc/`.

## What separates the arms

**Product is a null.** Neither arm disclosed anything: `assumptions: none` 3/3 in
the baseline, and the reports state the plan "fully specified" the work. The
empty-slice case never registers as a decision because `product := 1` resolves it
*incidentally* — idiomatic accumulator initialization, not a deliberate choice.
The stimulus cannot discriminate, and the `evals/contracts/coder.md` expectation
written for it ("`assumptions` names the empty-slice choice — not `none`") **fails
3/3 in the baseline**. That expectation was authored from intuition and is wrong.

**Mode discriminates, on disclosure only.** Both arms pick a tie rule and both
document it in the doc comment (3/3 each). The difference is *how the decision is
surfaced*:

- baseline 3/3 name it in a dedicated `assumptions` field and explicitly mark it
  as unpinned — "Plan didn't specify tie-breaking behavior…";
- policy-off 1/3 flags it as unspecified (in `deviations`), 2/3 state the rule as
  a bare fact inside `steps_done` ("ties broken by first occurrence") — true, but
  indistinguishable from a plan requirement being reported back.

On the second, subtler axis the gap is cleaner: the empty-slice choice is named by
the baseline 2/3 (and reaches the durable doc comment 2/3, one citing `Sum`'s
zero-value convention by name) and by policy-off **0/3** — no report mention, no
doc comment, in any run.

## Ablation verdict

`ambiguity-policy-off: 0 Δ escaped defects, 0 Δ bounces (0 vs 0), +2/3 unpinned
decisions surfaced and +2/3 empty-slice disclosures under the policy → the
ambiguity policy is JUSTIFIED ON DISCLOSURE, NOT SHOWN TO REDUCE ROUNDTRIPS.`

**Read honestly — the headline claim is not supported by this run.** S1 was sold
on removing roundtrips, and the roundtrip count is 0 in both arms. The pre-change
rule ("If the plan is wrong or blocked, STOP and report the conflict") does not
fire on a merely *thin* slice: an unpinned detail is neither wrong nor blocked. At
single-dispatch scope there was no bounce to remove.

What the policy demonstrably buys is that an autonomously-made decision arrives
**labeled as a decision** rather than buried in prose or invisible. That matters
for the safety argument, not the cost one: assume-and-proceed is only defensible
if review can adjudicate the assumption, and 0/3 disclosure of the empty-slice
choice in the ablated arm is exactly the silent-resolution failure mode.

## Limits (what this does NOT measure)

1. **Single dispatch, no orchestrator.** The 53.8% Sonnet one-shot rate in the
   source telemetry is over real multi-dispatch sessions where a coder holds a
   plan slice, a review loop, and an orchestrator to bounce to. A hand-written
   one-shot stimulus cannot reproduce that coupling. This result **bounds S1's
   effect at single-dispatch scope; it does not refute the telemetry.**
2. **No `/new-task` lifecycle run.** Subagents in this harness cannot dispatch, so
   a driver cannot fan out; Layer 2 and `evals/dispatch-trace.sh`'s end-to-end
   1-shot column remain unmeasured. Owed on a local CLI with a real Agent tool.
3. **S2 (Dispatch brief) and S3 (Phase 4 dispatch-readiness) are untouched here.**
   Both are orchestrator-side; neither is exercisable by a single agent dispatch.
4. **No cost column.** `claude -p` returned no usage trailer, so token/wall-clock
   deltas were not captured. The arms are behaviorally near-identical, so the
   expected cost delta is ~0, but that is inference, not measurement.
5. **n=3.** Directional only. The 2/3 splits are one run from being 3/3 or 1/3.

## Harness defect found and fixed mid-run

The first baseline attempt was **discarded**: the stimulus said "in the
`evalfixture` module" with no path, so 2 of 3 coders located the *repo's own*
`evals/fixtures/base` and edited it instead of their sandbox copy — mutating the
source fixture and cross-contaminating the other runs (one reported the work
"already present"). The repo fixture was reverted (`git checkout`) and verified
green. `contract-ab.sh` now pins each run to its working directory, asserts
`git status -- evals/fixtures` is clean after every dispatch, and runs
sequentially so an escape is attributable. All 12 runs above report
`CONTAMINATION: 0`.

Worth recording as an eval-harness lesson: Layer 3 isolates the *fixture copy* but
not the agent's *reach* — an agent pointed at an ambiguous module name will find
the real one.

## Actions taken from this result

- `evals/contracts/coder.md` — stimulus switched Product → Mode (Product elicits
  nothing from either arm), and the expected-fields calibrated to what is actually
  reproducible: the tie-break disclosure (3/3) is the required check; the
  empty-slice disclosure (2/3) is recorded as the stretch check, not a pass bar.
- `evals/tasks/23-thin-plan-step.md` — primary and secondary controls **swapped**.
  The roundtrip control (`redisp 0`) is satisfied by both arms, so it is demoted to
  a guard; the disclosure controls become primary.
- `evals/complexity-ledger.md` — the coder-ambiguity-policy row re-sourced from
  "prevents roundtrips" to "prevents silent resolutions", with the roundtrip claim
  marked unmeasured at this tier.
