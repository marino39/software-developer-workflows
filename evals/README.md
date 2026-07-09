# Workflow evals

The measure-and-iterate loop for this workflow. Because the repo defines
*instructions* (not code), the harness cannot unit-test functions — it **runs
`/new-task` against frozen tasks and scores the outputs**, plus a cheap
deterministic lint over the instruction files. Driven by the `/workflow-eval`
command; this directory holds its inputs and outputs.

## Layout

```
rubric.md        shared scoring rubric (5 dimensions) — the contract for scoring
lint.sh          deterministic Layer-1 lint (no LLM); also runs from the pre-commit hook
complexity-ledger.md  the complexity budget: each accreted construct → the failure it
                 prevents → source → status; `intuition — unverified` rows are the backlog
fixtures/base/   one minimal Go module all tasks run against (calc + auth helper +
                 doc file); builds and tests fully green
tasks/           frozen task specs: statement + expected behaviour + score overrides;
                 a task/contract needing a failing baseline carries a `## Seed` step
                 (command/patch) applied to its fixture copy after copy, before dispatch
variants/        ablation deltas (skeptic-off, single-lens-review, fable-budget-flat,
                 brainstorm-single) prepended to a run for A/B
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
- The first cut is 4 tasks / 1 fixture covering the routing, bug-fix,
  auto-approve, and `/iterate` warm-start paths — representative, not exhaustive.
  Task 04 exercises `/iterate` (not `/new-task`): its `## Seed` stands in for a
  completed prior run (baseline diff + run manifest) so the delta has a reviewed
  baseline. A live scorecard + an ablation variant for the `/iterate` layer are
  owed per `CLAUDE.md` before it merges (see the ledger row, status `candidate`).
