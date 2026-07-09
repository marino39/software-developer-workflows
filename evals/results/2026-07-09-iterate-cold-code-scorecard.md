# Workflow eval scorecard — 2026-07-09 (iterate-cold, code delta, repeat 3)

**Label:** iterate-cold-code · **Task:** 05 (code delta) · **Repeat:** 3 · **Variant:** iterate-cold
**Compared against:** the warm `/iterate` path on the same task 05, same 3 repeats.
**Trigger:** firm the earn-its-cost magnitude the doc-only A/B
(`2026-07-09-iterate-cold-scorecard.md`, n=1) could only sketch. This one runs a
**code** delta (adds `calc.Max` to a reviewed `calc.Product` baseline) three times
each side. **It materially corrects the doc-only conclusion — read the verdict.**

## Layer 2 — A/B (identical task, 3 samples each side)

All six runs produced a **correct** `calc.Max` — `(max, true)` for non-empty,
`(0, false)` for empty/nil (guard-first, seeds `m := xs[0]` so all-negative slices
are correct), with a test covering normal + empty (+ negatives). `go build/vet/test`
green everywhere. **Zero escaped defects on both sides.** So this is again purely a
cost/predictability comparison at equal quality.

| Run | Path | Route | Subagents | Decision gates | Subagent tokens |
|---|---|---|---|---|---|
| warm rep1 | `/iterate` | standard (inherited) | 4 | GATE I + GATE 4 | 66.3k |
| warm rep2 | `/iterate` | standard (inherited) | 4 | GATE I + GATE 4 | 61.0k |
| warm rep3 | `/iterate` | standard (inherited) | 4 | GATE I + GATE 4 | 76.9k |
| **warm mean** | | **standard, every time** | **4** | **2** | **68.1k** (range 61–77) |
| cold rep1 | `/new-task` | **scoped** (fast path) | ~4–5 | 2 | 55.0k |
| cold rep2 | `/new-task` | **scoped** (fast path) | 4 | 3 | 53.0k |
| cold rep3 | `/new-task` | **standard** (full lifecycle) | 11 | 4 | 116.0k |
| **cold mean** | | **non-deterministic** | **4–11** | **3** | **74.7k** (range 53–116) |

Warm subagents each run: architect (delta plan-lite), coder (implement), coder
(verify-feature behavioral drive), reviewer (delta). Cold rep3's 11: 3 brainstorm
lenses + synthesizer + Phase-2 adversarial + Phase-3 plan + Phase-4 mapping reviewer
+ coder + 2 Phase-6 reviewers (+ a wasted fable synthesizer that errored on credits).

## Verdict — corrects the doc-only run

`iterate-cold (code delta, n=3): Δ escaped defects = 0; cost is NOT a flat saving.`

The doc-only n=1 A/B reported `/iterate` ~1.9× **cheaper**. On a **code** delta that
does **not** generalize, for two reasons the doc-only case hid:

1. **Cold re-routes the small feature to its own lean fast-path** (2 of 3 cold reps),
   so there is little heavy machinery for the warm path to skip — and the warm path
   then **pays for a full `verify-feature` behavioral drive** (a dedicated coder,
   ~18–35k tokens) that cold's fast-path verification did lightly. On those two reps
   warm was ~**26% heavier** (68k vs ~54k).
2. **But cold's routing is non-deterministic on this boundary task** — rep3 judged
   "new public feature ⇒ standard" and ran the **full lifecycle at ~116k / 11
   subagents** for a 29-line function. Warm, inheriting the manifest's route floor,
   ran the identical lean delta (~68k / 4 subagents) every time.

So the real, measured advantages of `/iterate` here are **not** a lower per-iteration
token count — they are:

- **Cost predictability.** Warm 61–77k (CV ~12%) vs cold 53–116k (CV ~48%). Warm
  never blows up; cold's cost is a coin-flip on where the router lands.
- **Route determinism = review-depth consistency + safety.** Cold reviewed the
  *same task* at two different depths (scoped fast-path vs standard full lifecycle).
  Warm inherits the baseline's already-decided route floor and cannot de-escalate.
  The safety corollary is the strongest single argument for the command: **a small
  follow-up to a high-stakes baseline would be re-judged and could be cold-scoped
  and under-reviewed** — exactly the Proposition-#4 failure the workflow exists to
  prevent — whereas `/iterate` pins it at the inherited high-stakes floor. (Observed
  indirectly here via cold's scoped/standard split; a high-stakes-baseline iterate
  task would measure it directly — owed, see below.)
- **Batched retro** across a multi-tweak session (N tweaks → 1 Phase 7 + 1 GATE 4
  instead of N). **Unmeasured here** — all six runs were single-iteration, so this
  benefit remains by-design, not evidenced.

**Net:** `/iterate` earns its place on **cost stability + route-floor determinism/
safety** (measured) and **batched retro** (by-design, unmeasured) — NOT on a flat
per-iteration token reduction, which is task-dependent and was neutral-to-negative
on the small scoped code delta. The doc-only scorecard's "1.9× cheaper → justified"
framing is hereby narrowed.

## Honesty / caveats

- **n=3, one code task, one fixture.** The cold scoped-vs-standard split (2:1) is
  itself a small sample of a non-deterministic router — the true cold cost
  distribution is wider than three points can pin. Direction (warm tighter, cold
  volatile, quality equal) is solid; exact means are soft.
- **`verify-feature` asymmetry.** Warm consistently spawned a dedicated behavioral-
  drive agent; cold's fast-path reps verified more cheaply (orchestrator-driven).
  Part of warm's higher floor-cost is warm verifying *more thoroughly*, not pure
  overhead — a quality-adjacent cost, not waste.
- **Two follow-up evals now clearly owed** to close the argument the token A/B
  can't: (a) a **multi-tweak `/iterate` session** task (3+ sequential deltas, one
  batched Phase 7) to measure the retro-amortization win; (b) a **high-stakes-
  baseline iterate** task to measure the route-floor safety win directly (warm
  inherits high-stakes; cold re-judges and may under-review).
- Environment limits (fable out of credits — it wasted one cold rep3 spawn; codex
  absent; `superpowers:*` unregistered) applied to both sides and largely cancel.
