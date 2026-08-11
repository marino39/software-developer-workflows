# Variant — ambiguity-policy-off

Ablates the `agents/coder.md` ambiguity policy (the 2026-07-29 addition: the
`<ambiguity-policy>` two-class rule, the batched-questions bullet, and the
`assumptions` output field) to measure whether closing gaps in-agent actually
removes roundtrips. Applies to the thin-plan-step task (23), and to any task
whose plan leaves a coder-closable gap.

## Delta (prepended to the dispatched /new-task for task 23)

> VARIANT ambiguity-policy-off: Run `/new-task` as written, EXCEPT instruct every
> `coder` you dispatch to operate under the pre-2026-07-29 rule in place of the
> current one: "If the plan is wrong or blocked, STOP and report the conflict — do
> not improvise around it or expand scope. Report format: steps completed, files
> changed (paths), test status, deviations from plan, open questions." Treat the
> coder's `<ambiguity-policy>` block, the batched-questions bullet, and the
> `assumptions` output field as absent — where they would have told the coder to
> close a gap itself, record it, or batch its questions, it falls back to its own
> judgment about what to report back. Everything else — routing, phases, review
> machinery, gates — is unchanged.

This reproduces the pre-change agent file by subtraction (the policy was purely
additive apart from the one replaced sentence, restored verbatim above), so
baseline-vs-variant ≈ post-vs-pre on the same harness.

(The caller-side Dispatch brief this variant was originally paired against was
cut 2026-08-10 — this variant now ablates the only remaining half.)

## What to read from the A/B

The policy's claim is about WHETHER A DISPATCH COMES BACK, so read the
deterministic trace first — `evals/dispatch-trace.sh` over each driver
transcript (units / disp / fanout / iter / rtrip / bounce / rt-free), alongside
`evals/context-trace.sh`:

- **coder rt-free rate** — the headline, and the nearest in-harness analogue of
  the live dashboard's 1-shot. Baseline should hold 100% on task 23 (both gaps closable); the
  variant is expected to bounce at least one and show `rtrip ≥ 1`. `bounce`
  (returns whose `open_questions` is non-empty) is the agent-side view of the
  same event and should move with it.
- **Orchestrator turns and context** — the cost the roundtrip actually buys:
  a re-dispatch spends an orchestrator turn at the most expensive seat, so
  compare turns and context high-water, not only driver tokens. A variant that
  is *cheaper* while still one-shot would mean the policy is over-placed.
- **Outcome correctness / No escaped defects** — the guard: the policy must not
  change results. An assumption is only safe if review can still adjudicate it,
  so check the shipped resolutions are visible (GATE 3 Key decisions) and
  covered by `TestMode` in BOTH conditions. Silent assumptions in the baseline
  would be a real cost of the policy, not a win.
- **Gate discipline** — secondary: with no `assumptions` field, do the
  autonomous resolutions still reach the gate at all, or do they go silent?

Verdict shape: `ambiguity-policy-off: <Δ escaped defects>, <Δ coder rt-free /
rtrip>, <Δ orchestrator turns> → <the ambiguity policy is justified | not
justified> on this suite`. Single-run variance applies — a roundtrip is a
discrete event, so n=1 proves only direction; raise `--repeat` before trusting
a magnitude.
