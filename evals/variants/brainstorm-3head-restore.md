# Variant — brainstorm-3head-restore

**Reverse ablation.** The 2026-08-11 cost pass cut Phase 1 from three Claude
architects + a fable synthesizer down to one `architect` + one codex lens + an opus
synthesizer that also writes the design doc. That cut was directive-sourced, not
evidence-sourced — this variant **restores the pre-cut behavior** so the A/B can be
run in the only direction still available: does the wide fan-out buy anything the
2-head version misses?

Read this together with `brainstorm-single.md` (one architect, no codex): the three
files give a 1-head / 2-head / 3-head comparison on the same task set.

**Route-control this A/B.** The delta necessarily names Phase 1, which the fast path
skips — exactly the priming confound that invalidated the 2026-08-10
dispatch-readiness run. Pin the route (or use a reliably standard-routing task) so
both arms actually execute the phase under test.

## Delta (prepended to the dispatched /new-task)

> VARIANT brainstorm-3head-restore: In Phase 1, restore the pre-2026-08-11 fan-out.
> Dispatch **three** `architect` subagents (opus default), each seeded with a
> distinct lens (simplest/MVP, most robust/scalable, alternative paradigm or
> library); do **not** run the codex design lens. Then synthesize with a FRESH
> `architect` **on fable** (Agent tool `model` param, clean context, fed only the
> three approach digests + the task statement) that ranks them inline and returns a
> recommendation — it does **not** write the design doc. After the human confirms,
> a separate `architect` in artifact mode writes the design doc. Phases 2+ are
> unchanged (Phase 2's adversarial review still runs on codex).

## What to read from the A/B

- **Approach quality** — did the third lens (or the fable ranker) surface an approach
  the 2-head version never considered? Compare the *chosen* approach, not the count
  of alternatives generated: three digests always look richer at GATE 1 and that is
  not the question.
- **Escaped defects downstream** — a worse design shows up in Phase 6/CI, not at
  GATE 1. Score the whole run.
- **Cost** — 5 deep-reasoning dispatches (3 lenses + fable synth + writer) vs 2 Claude
  dispatches + 1 free codex pass, with one of the cut calls being fable. This is the
  largest single pre-implementation cost delta in the workflow.
- **Human override rate at the design discussion** — if the human overrides the
  recommendation more often on the 2-head version, the fan-out was doing real work.

Verdict shape: `brainstorm-3head-restore: <Δ chosen-approach quality>, <Δ escaped
defects>, <Δ cost> → the 2026-08-11 cut is <safe | a quality regression>`. Task-space
caveat from `brainstorm-single` still applies: narrow fixture tasks under-state what
a wide fan-out is for, so a null here is weak evidence for wide design spaces.
