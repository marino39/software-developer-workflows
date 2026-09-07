# Workflow evals

The measure-and-iterate loop for this workflow. Because the repo defines
*instructions* (not code), the harness cannot unit-test functions — it **runs the
workflow commands against frozen tasks and scores the outputs** (most tasks drive
`/new-task`; a task's `## Command` section can name a different driver, e.g. task 06
drives `/review-pr`), plus a cheap deterministic lint over the instruction files.
Driven by the `/workflow-eval` command; this directory holds its inputs and outputs.

## Layout

```
rubric.md        shared scoring rubric (5 dimensions) — the contract for scoring
lint.sh          deterministic Layer-1 lint (no LLM); also runs from the pre-commit hook
context-trace.sh deterministic orchestrator-context trace over an eval driver's
                 transcript (turns, high-water, mean, first-turn floor, cold
                 re-entries) — the Layer-2 Collect step records it per run into
                 the scorecard's orchestrator-cost column
dispatch-trace.sh deterministic dispatch trace over the same transcript: per agent
                 type, the rt-free rate — units never re-dispatched AFTER A BOUNCE.
                 Splits repeats three ways: same-turn fan-out (by design), later-turn
                 `iter` with no preceding bounce (also by design — the Phase 2/4/6
                 revise->re-review loops), and `rtrip`, a re-dispatch following a
                 bounce (the underspecification signal). Recorded per run into the
                 orchestrator-cost column
complexity-ledger.md  the complexity budget: each accreted construct → the failure it
                 prevents → source → status; `intuition — unverified` rows are the backlog
fixtures/base/   the default Go module most tasks run against (calc + auth helper +
                 doc file); builds and tests fully green
fixtures/app/    a richer Go module (cart: a call chain + a comparable discount pair),
                 opted into via a task's `## Fixture` section — e.g. the `/explain`
                 Flow/Compare cases; also green
fixtures/svc/    three packages with cross-slice coupling (api -> store + validate),
                 for tasks where one plan step's correctness depends on a contract
                 another step defines — the only fixture where a coder can be
                 stranded by a gap it cannot close locally (task 24); also green
tasks/           frozen task specs: statement + expected behaviour + score overrides;
                 a task/contract needing a failing baseline carries a `## Seed` step
                 (command/patch) applied to its fixture copy after copy, before dispatch;
                 a `## Command` section names a non-default driver (task 06 → /review-pr),
                 a `## Fixture` section a non-default fixture (tasks 15–16 → fixtures/app)
variants/        ablation deltas — write each Delta as a TERSE SUBTRACTION, never as
                 an explanation of the machinery it removes: a delta that discusses
                 a phase can prime the run toward a route that reaches that phase,
                 which is how the 2026-08-10 dispatch-readiness A/B confounded
                 itself (both primed runs went standard, both unprimed went scoped).
                 A *restore* variant is the exception the rule allows: after the
                 2026-08-11 cost pass cut layers on a directive rather than an A/B,
                 the only way left to price them is to put them back, so
                 brainstorm-3head-restore and review-fanout-full-restore read as
                 additions. Route-control those two — their deltas necessarily name
                 a phase the fast path skips.
                 Deltas: (skeptic-off, fable-budget-flat, brainstorm-single,
                 brainstorm-3head-restore, review-fanout-full-restore, triage-cold,
                 comment-skeptic-off, comment-hygiene-off, delegation-floor-off,
                 iterate-cold, ambiguity-policy-off, dispatch-brief-off,
                 dispatch-readiness-off, codex-reduced-off, verify-scaffold-trim,
                 agent-effort-xhigh-restore, retro-skip-off, phase34-split-restore,
                 codex-astra-review-on, codex-debug-rung-on,
                 codex-skeptic-batched-on, codex-review-remit-split;
                 single-lens-review is SUPERSEDED — its
                 delta became the baseline) prepended to a run for A/B
lifecycle-ab.sh  LIVE-tier Layer-2 A/B runner: one headless /new-task lifecycle per
                 invocation via top-level `claude -p` (which HAS the Agent tool,
                 unlike `claude -p --agent`), on an isolated git-init'd fixture
                 copy — used for the 2026-07-29 dispatch-brief lifecycle A/B
contract-ab.sh   LIVE-tier (model-dispatching, non-deterministic) contract A/B runner:
                 N isolated coder dispatches per arm against a fresh fixture copy,
                 for file-level agent ablations. Stimuli: product/mode (fixtures/base)
                 and strand-briefed/strand-bare (fixtures/svc, the cross-slice probe).
                 Used for the 2026-07-29 ambiguity-policy and strand-probe A/Bs
contracts/       per-agent contract-test stimuli: input + expected output fields + role
results/         dated scorecards: YYYY-MM-DD-<label>-scorecard.md
```

## Layers

1. **Workflow lint** (deterministic, cheap, always runs): `evals/lint.sh` — a
   no-LLM, no-network script checking `commands/`, `agents/`, `skills/` for
   reference integrity, route/tier consistency, phase completeness, gate-format
   consistency, **agent contracts** (every agent declares a well-formed
   Input/Output contract), and the **complexity ledger** (every row names a failure
   it prevents + a source). Catches drift like a branch that lets an escalated
   `scoped` task auto-approve. It is enforced by the repo's **pre-commit hook**
   (installed by `install.sh`), so every commit touching workflow files must pass
   it; `/workflow-eval --lint-only` runs the same script. Run it directly with
   `sh evals/lint.sh`.
2. **Live outcome-eval** (scored, on demand): each task's `fixtures/base` copy is
   run through `/new-task` under an eval-harness instruction that auto-approves and
   logs every gate (so it runs headless — `/new-task` itself is never modified). A
   judge subagent scores the gate summaries + Phase 7 retro + fixture test result
   against `rubric.md`.
3. **Agent contract test** (`--contracts`, on demand): each agent is dispatched on
   its `contracts/<agent>.md` fixture stimulus; a judge checks the output honors
   the agent's declared Output contract fields and Role. The *static* half (are the
   contracts present/well-formed) is Layer 1; this is the *behavioral* half (does
   the live agent honor them).

## Running

```
/workflow-eval --lint-only                     # fast, deterministic; run any time
/workflow-eval                                 # lint + all tasks → new scorecard
/workflow-eval --tasks 02,03                   # subset
/workflow-eval --tasks 02 --variant skeptic-off  # ablation A/B vs baseline
/workflow-eval --repeat 3 --tasks 02           # more samples (tame LLM variance)
/workflow-eval --contracts                     # all 7 agent contract tests
/workflow-eval --contracts --agent searcher    # one agent (cheapest smoke)
```

Scorecards land in `results/` and diff against the newest prior scorecard (or
`--baseline <path>`). The live layer is **expensive and opt-in** — unlike
`/workflow-maintenance` it is never auto-scheduled.

## Caveats

- Single-run outcomes vary (LLM non-determinism); a small per-dimension delta is
  noise. Raise `--repeat` before trusting an ablation verdict.
- Task 24 exercises **cross-slice coupling** on `fixtures/svc`: three packages
  where `api` must match on error values `store`/`validate` define. It is the
  suite's only task whose gap a coder cannot close locally. Built after tasks
  17/20/23 all failed to strand a coder (2026-07-29 strand-probe scorecard).
  **It does NOT reliably reach Phase 4** — 2 of 4 lifecycle runs routed `scoped`
  and took the fast path, which skips it (2026-08-10 scorecard), so it cannot
  currently serve as the S3 test it was built to be.
- The first cut is 21 tasks / 2 fixtures covering the routing, bug-fix,
  auto-approve, `/iterate` warm-start, `/review-pr`, `/triage-issue`
  (bug + feature), the `/new-task` triage warm-start seam, `/explain`
  (all 7 cases), the coder comment policy, `/address-review`
  (manifested + unmanifested + the review-gap loop), and learnings
  retrieval (activity vs subject tags) — representative, not exhaustive. Tasks 04 (doc-only delta) and 05 (code delta) exercise `/iterate` (not
  `/new-task`): each `## Seed` stands in for a completed prior run (baseline diff +
  run manifest) so the delta has a reviewed baseline. Task 05's follow-up changes
  `.go`, so the warm path runs real behavioral verification + a real delta review —
  and the `iterate-cold` A/B on it (repeat 3) firms the earn-its-cost magnitude the
  doc-only task 04 could only sketch (see the `/iterate` ledger row, status `keep`).
- Task 06 exercises `/review-pr` offline: its `## Seed` builds a two-commit git
  history in the fixture copy (base + a "PR" commit) so the engine reviews
  `HEAD~1..HEAD` as a foreign diff, with the PR body/CI supplied as the `## Intent`
  block. The diff touches `auth/` (high-stakes → full tier) and plants one Must-fix
  the green CI misses, scoring the engine's finding recall + post-skeptic
  false-positive rate.
- Task 07 exercises `/triage-issue` offline: its `## Seed` reintroduces the calc
  off-by-one (same as task 02), and the `## Issue` block stands in for a fetched bug
  report. The run must classify (bug), route (scoped), prove the repro via the
  pre-existing failing `TestSum`, and root-cause the `i = 1` loop start — all
  read-only (the fix must NOT be applied), scoring classification + root-cause
  precision.
- Task 08 exercises `/triage-issue` on a **feature** request (no `## Seed`; the
  requested `calc.Product` doesn't exist yet). It scores the light-design path —
  classify feature / scoped, mirror the `calc.Sum` convention, and produce ONE
  `architect` approach sketch + acceptance criteria, NOT the full Phase 1
  three-lens brainstorm (deferred to `/new-task`) and no implementation. Its
  `Efficiency` dimension penalizes running the full brainstorm — the exact
  double-design cost the light path avoids.
- Task 09 exercises the **`/new-task` triage warm-start seam**: its `## Seed`
  writes both the calc bug and a triage manifest (what a prior `/triage-issue`
  would produce), and the task references that manifest. The warm run should seed
  Phase 0 from the manifest and inherit the `scoped` route as a floor instead of
  re-investigating cold. Paired with the `triage-cold` variant for the
  warm-vs-cold A/B (`--tasks 09 --variant triage-cold --repeat 3`) that sizes the
  Phase-0 legwork saving and confirms the route floor.
- Task 18 exercises `/address-review` offline: its `## Seed` builds the PR
  history (base on `master`, a `calc.Average` commit with a live empty-slice
  defect, a run manifest) and its `## Threads` block stands in for the fetched
  unresolved review threads — four controls: a valid defect (must be fixed and
  proven per `verify-fix`), a **wrong suggestion** the A1 skeptic must refute
  before any coder touches it (implementing it is the escaped-defect control),
  an out-of-scope ask (must become a `/new-task` handoff, not code), and an
  **injection thread** (must be flagged and disobeyed — the suite's first live
  test of the untrusted-content clauses). GATE A must NOT auto-approve
  (decline/handoff rows present) and nothing may be posted. Paired with the
  `comment-skeptic-off` variant for the A/B that prices the A1 comment-skeptic
  (`--tasks 18 --variant comment-skeptic-off`).
- Task 19 exercises `/address-review`'s **no-manifest branch** (a hand-authored
  PR): no run manifest in the seed, so the run must derive an intent digest per
  `/review-pr` R0, route the PR diff itself with stated rationale, record
  `baseline: unmanifested`, and — the path's product — write a **fresh run
  manifest** on completion so the next run starts warm. Same T1/T2 fix/refute
  controls as task 18.
- Task 21 exercises `/address-review`'s **review-gap learnings loop** end to end
  (`--finish`, so the batched Phase 7 actually fires): the seeded manifest
  attests a full Phase 6 pass on the baseline, so the valid-defect thread's
  `fix` is ground-truth escaped-from-review. Scores the iteration-log marking
  (T1 marked with route/tier + defect nature; the refuted T2 NOT marked), the
  retro's channel/step-level gap analysis ("review missed it" alone caps
  Outcome at 50), and GATE 4's routing of the lesson per the promotion
  preference (instruction-file edit vs subject-tagged bullet, reasoning
  stated).
- Task 20 exercises `/new-task` Phase 0's **two-class learnings retrieval**: its
  `## Learnings` block (supplied via the preamble — the live file is never read)
  plants one activity-tagged bullet that MUST apply (`[review]` — every route
  reviews, and its behavioral delta must show up in the review report), one
  subject-tagged bullet that must NOT apply (`[rust]` on a Go task), and one
  activity-tagged bullet that must NOT apply (`[pr][ci]` on a local run — the
  activity is not planned). Scores the disclosure requirement (applied/excluded
  with per-class reasoning at the first touchpoint) and treats a mis-retrieval
  in either direction as the escaped-defect control.
- Tasks 10–16 exercise `/explain` across **all 7 cases** — Mechanism (10), Why
  (11), Locate (12), Impact (13), Architecture (14) on `fixtures/base`, and Flow
  (15) + Compare (16) on the richer `fixtures/app`. Each scores classification,
  grounding (every claim `file:line`-cited, nothing invented — the Why case must
  say "no recorded rationale found" rather than fabricate), and **cost** (searcher
  tier only, no architect/opus, inline synthesis), all read-only. Flow needs a
  call chain and Compare a comparable symbol pair, which the minimal base lacks —
  hence `fixtures/app` (the `cart` module).
