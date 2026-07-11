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
complexity-ledger.md  the complexity budget: each accreted construct → the failure it
                 prevents → source → status; `intuition — unverified` rows are the backlog
fixtures/base/   the default Go module most tasks run against (calc + auth helper +
                 doc file); builds and tests fully green
fixtures/app/    a richer Go module (cart: a call chain + a comparable discount pair),
                 opted into via a task's `## Fixture` section — e.g. the `/explain`
                 Flow/Compare cases; also green
tasks/           frozen task specs: statement + expected behaviour + score overrides;
                 a task/contract needing a failing baseline carries a `## Seed` step
                 (command/patch) applied to its fixture copy after copy, before dispatch;
                 a `## Command` section names a non-default driver (task 06 → /review-pr),
                 a `## Fixture` section a non-default fixture (tasks 15–16 → fixtures/app)
variants/        ablation deltas (skeptic-off, single-lens-review, fable-budget-flat,
                 brainstorm-single, triage-cold, comment-skeptic-off) prepended to a
                 run for A/B
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
