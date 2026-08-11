# Variant — dispatch-brief-off (HISTORICAL — the construct was cut 2026-08-10)

**The Dispatch brief no longer exists in `commands/new-task.md`**: after this
variant's lifecycle A/B (no verdict, route-confounded) and the strand probe
(briefed ≡ bare on every axis), the construct was reverted per CLAUDE.md rule 3.
This file is retained because the 2026-07-29/08-10 scorecards reference it; do
not run it against the current command text — there is nothing to ablate.


Ablates the `commands/new-task.md` **Dispatch brief** (the 2026-07-29 addition:
the section itself, plus its invocations at Phase 5 step 2, Phase 6 steps 3 and
5, and Phase 6.5 step 4) to measure whether briefing `coder`/`reviewer` spawns
actually removes roundtrips — or just adds tokens to every dispatch. Applies to
the thin-plan-step task (23) and to any implement-and-review task (02, 17, 20).

## Delta (prepended to the dispatched /new-task)

> VARIANT dispatch-brief-off: Run `/new-task` as written, EXCEPT treat the
> **Dispatch brief** section and every reference to it as absent. Do not fill
> `done_when`, `scope_bounds`, `context_pointers`, or `on_ambiguity` on any
> spawn, and do not check a callee's Input contract before dispatching. Compose
> `coder` and `reviewer` spawn prompts by your own judgment of what each agent
> needs — for a coder that is the plan path plus the step numbers it owns "plus
> only run-specific context the file lacks", as Phase 5 step 2 said before the
> change. Everything else — routing, phases, the coder's own ambiguity policy,
> review machinery, gates — is unchanged.

Note this variant leaves `agents/coder.md`'s ambiguity policy **in force**; it
ablates only the caller's half. Run it against `ambiguity-policy-off` to tell
the two halves apart: if briefing is what closes the gaps, this variant moves
the rate and the other does not. Ablating both at once cannot distinguish them.

## What to read from the A/B

Read the deterministic traces first — `evals/dispatch-trace.sh` (units / disp /
fanout / iter / rtrip / bounce / rt-free) and `evals/context-trace.sh`:

- **coder + reviewer rt-free rate** — the headline (`rtrip` is bounce-gated, so by-design Phase 2/4/6 iteration does not count against it). The brief's claim is that a
  dispatch carrying `done_when` and bounds does not come back; without it,
  expect `rtrip`/`bounce` to rise on the tasks whose plans leave a gap.
- **Cost, both directions** — the brief is the one change here that *adds*
  tokens per dispatch, so this A/B is the one that can falsify it. Compare
  driver tokens and orchestrator turns: the brief pays iff the turns it avoids
  outweigh the prompt bytes it adds. Live telemetry sized that trade at ~$0.029
  per sonnet call against ~$1.37 per delegation turn, but that is the user's
  workload, not this suite — measure it here.
- **Outcome correctness / No escaped defects** — the guard: briefing must not
  change results. A `scope_bounds` tight enough to prevent a needed edit would
  show up as a coder flagging out-of-scope work it should simply have done.
- **Gate discipline** — secondary: unchanged, the brief touches no gate.

Verdict shape: `dispatch-brief-off: <Δ escaped defects>, <Δ rt-free / rtrip>,
<Δ driver tokens and orchestrator turns> → <the Dispatch brief is justified |
not justified> on this suite`. Single-run variance applies — a roundtrip is a
discrete event, so raise `--repeat` before trusting a magnitude.
