# Variant — codex-debug-rung-on

Tests R4/R5 of `docs/proposals/2026-09-07-codex-astra-model-allocation.md`: an
out-of-model `gpt-6-astra` root-cause pass inserted **before** the run's one fable
escalation, on the two seats with the Terminal-Bench profile — `debugger` escalation
and Phase 6.5 CI triage — plus the parallel root-cause lens in `/triage-issue` T2.

Applies to tasks that reach a stuck loop or a triage root-cause: 02 (bugfix), 07
(triage-issue), 08 (triage-feature), 21 (review-gap loop). Runs that never escalate
are inert here — report them as inert rather than as ties.

**Route-control this A/B.** The delta names an escalation rung and Phase 6.5, neither
of which a clean run reaches at all — exactly the priming confound that invalidated
the 2026-08-10 dispatch-readiness run. Use tasks seeded to fail (02, 21) and pin the
route, or the variant arm will read as a tie made of runs that never escalated.

## Delta (prepended to the dispatched command)

> VARIANT codex-debug-rung-on: the escalation ladder gains one out-of-model rung.
> `coder → debugger (opus) → codex root-cause pass → fable debugger`. The codex pass
> runs per the `codex-exec` skill with `--model gpt-6-astra -c
> model_reasoning_effort=xhigh`, `--sandbox read-only`, and returns a root-cause
> digest ONLY — never a fix; a Claude agent applies it. The same rung applies to
> Phase 6.5 CI triage. In `/triage-issue` T2, additionally run one codex root-cause
> pass IN PARALLEL with the `coder` repro and feed both digests to the scoping step.
> The one-fable-per-run budget is unchanged — the point is to reach the fix without
> spending it.

## What to read from the A/B

- **Fable escalations avoided** — the headline: runs that reached a verified root
  cause on the codex rung and never spent the fable escalation. This is the cost
  case; zero at n≥3 and the rung is pure added latency.
- **Root-cause quality** — did the digest name a cause the opus `debugger` had
  missed, and did the fix built on it hold? A digest that merely restates the failure
  is a skip in disguise. Count digests that were *wrong* separately: a confidently
  wrong out-of-model root cause is worse than none, because a Claude agent then
  implements it.
- **Read-only invariant held** — the codex pass must never write. Any file mutation
  in the variant arm is a failed run, not a data point.
- **Δ time-to-green** — wall-clock from first failure to green, both arms. The rung
  adds ≥10 min before the fable rung; it pays only if it removes more than it adds.
- **Triage lens value (T2)** — findings the parallel codex lens surfaced that the
  `coder` repro did not, and whether they changed the scoped plan.

Verdict shape: `codex-debug-rung-on: <fable escalations avoided /n>, <root causes
correct/wrong>, <Δ time-to-green>, <read-only held y/n>`.
