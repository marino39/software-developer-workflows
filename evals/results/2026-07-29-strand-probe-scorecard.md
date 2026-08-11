# Scorecard — cross-slice stranding probe (2026-07-29)

The probe built after tasks 17/20/23 all failed to strand a coder and the first
two A/Bs measured zero roundtrips. Diagnosis then: those gaps were *locally
closable*, so neither the ambiguity policy nor the Dispatch brief had anything to
act on. This probe supplies a gap that provably **cannot** be closed locally.

- Fixture: `evals/fixtures/svc` (new) — `api` → `store` + `validate`, a real call
  chain across three packages.
- Stimulus: step 2 of a thin 3-step plan (`evals/contract-ab.sh strand-*`). `api`
  must map store-missing → 404 and validation-failure → 400, but **no step names
  the error identity**, and steps 1 and 3 are stated to be in flight on parallel
  coders with their code not yet on disk. Nothing the coder can read settles it.
- Arms: `strand-briefed` (full Dispatch brief) vs `strand-bare` (slice pointer
  only) — isolating S2's caller half; `agents/coder.md`'s ambiguity policy is in
  force in **both**.
- n=3 per arm, isolated fixture copy per run, 0 tracked contamination.

## Result

| Arm | Run | Bounced | Disclosed assumption | Guessed `store.ErrNotFound` | Dropped the 500 branch | Out-of-scope edits |
|---|---|---|---|---|---|---|
| briefed | 1 | no | yes | yes | no | none |
| briefed | 2 | no | yes | no | **yes** | none |
| briefed | 3 | no | yes | yes | no | none |
| bare | 1 | no | yes | no | **yes** | none |
| bare | 2 | no | yes | yes | no | none |
| bare | 3 | no | yes | yes | no | none |

**The probe works.** The gap is genuinely non-local, and the coders say so
themselves — e.g. *"if step 1's author names it differently, `api/api.go` line 21
is the one-line fix needed"*. This is the stranding condition the earlier stimuli
never produced.

## Finding 1 — stranded coders still do not bounce

**0 bounces in 6 runs**, both arms. Cumulative across this investigation:
**22 runs at three tiers (12 contract, 4 lifecycle, 6 strand) — zero
underspecification roundtrips.** The mechanism the proposal is premised on has now
failed to reproduce under conditions engineered specifically to force it.

What a stranded coder does instead is assume, disclose, and flag the reconcile
point. All 6 disclosed; 2 explicitly reasoned about the compile-break risk before
choosing.

## Finding 2 — the real failure mode is contract divergence, not orchestrator turns

Every one of the 6 runs shipped `api` code that **cannot be verified until the
sibling slices land**, and split two ways on how to be wrong:

- **4/6 guessed a symbol that does not exist yet** — `errors.Is(err,
  store.ErrNotFound)`, idiomatic and reasonable, but a compile break if step 1's
  coder picks any other name or a typed error.
- **2/6 declined to guess and silently dropped a plan requirement** — mapping
  *any* store error to 404 and removing the 500 branch the plan explicitly
  specifies. This is arguably the worse outcome: it compiles against more
  possible step-1 implementations while quietly losing a stated requirement.

The cost of a non-local gap is not an orchestrator turn. It is a latent
cross-package mismatch that surfaces at integration, or a requirement that
evaporates.

## Finding 3 — the Dispatch brief does not fix this, and structurally cannot

Briefed and bare are **identical on every axis measured**: 2/3 vs 2/3 guessed the
sentinel, 1/3 vs 1/3 dropped the 500 branch, 0/3 vs 0/3 bounced, 3/3 vs 3/3
disclosed, 0 out-of-scope edits either side (the bare arm respected package
boundaries without being told to).

There is a principled reason, not just a small sample. The brief carries
`done_when`, `scope_bounds`, `context_pointers`, `on_ambiguity` — **it transmits
what the orchestrator knows.** The missing error contract is not something the
orchestrator knows either, unless the plan pinned it. A brief cannot manufacture a
decision nobody has made.

`dispatch-brief-off: 0 Δ bounces, 0 Δ contract divergence (2/3 vs 2/3), 0 Δ
out-of-scope edits, 0 Δ disclosure → the Dispatch brief is NOT JUSTIFIED by this
probe.` Combined with the lifecycle A/B (no verdict, route-confounded) and the
fact that it is the one change here that adds tokens to every dispatch, S2 now has
no measurement supporting it at any tier.

## Finding 4 — this is the first evidence pointing at S3

The only place a cross-slice contract can be fixed is **before dispatch**, in the
plan. That is exactly what the Phase 4 **dispatch-readiness** column requires: a
step is ready only if it names "the interface contract the coder must honor". On
this probe's plan, step 2 would be marked **unready** — it names its file and its
verification command but no matching mechanism — and the phase would fail until an
architect pinned the sentinel.

The evidence is indirect: the probe dispatches a coder against a fixed plan and
never runs Phase 4. Task 24 (`evals/tasks/24-cross-slice-contract.md`) is the
lifecycle version that does, and it is the suite's first task that routes
**standard** and therefore actually reaches Phase 4 — three of four runs in the
lifecycle A/B took the fast path, which skips it entirely.

## Limits

- n=3/arm; the 2/3-vs-2/3 split is one run from 3/3 or 1/3. The *direction* (no
  difference) is what n=3 supports, not a precise effect size.
- Single dispatch: no orchestrator, so a bounce here would have had nowhere to go.
  The lifecycle tier is where a roundtrip is actually payable, and it also
  measured zero.
- The ambiguity policy is in force in both arms by design (this isolates S2).
  Whether a *pre-policy* coder would bounce on a non-local gap is untested — that
  is `ambiguity-policy-off` × `strand-*`, and it is the one remaining experiment
  that could still rescue S1's roundtrip claim.

## Actions

- `evals/fixtures/svc` + `evals/tasks/24-cross-slice-contract.md` added — the
  suite's first cross-slice task and first reliably-standard-routing task.
- S2's ledger row re-sourced: no supporting measurement at any tier, and a
  structural argument for why this probe cannot support it.
- S3's ledger row gains its first (indirect) supporting evidence.
