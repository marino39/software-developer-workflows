# Workflow evals

The measure-and-iterate loop for this workflow. Because the repo defines
*instructions* (not code), the harness cannot unit-test functions — it **runs
`/new-task` against frozen tasks and scores the outputs**, plus a cheap
deterministic lint over the instruction files. Driven by the `/workflow-eval`
command; this directory holds its inputs and outputs.

## Layout

```
rubric.md        shared scoring rubric (5 dimensions) — the contract for scoring
fixtures/base/   one minimal Go module all tasks run against (seeded bug + auth
                 helper + doc file); builds green except the seeded calc bug
tasks/           frozen task specs: statement + expected behaviour + score overrides
variants/        ablation deltas (e.g. skeptic-off) prepended to a run for A/B
results/         dated scorecards: YYYY-MM-DD-<label>-scorecard.md
```

## Two layers

1. **Workflow lint** (deterministic, cheap, always runs): `evals/lint.sh` — a
   no-LLM, no-network script checking `commands/`, `agents/`, `skills/` for
   reference integrity, route/tier consistency, phase completeness, and
   gate-format consistency. Catches drift like a branch that lets an escalated
   `scoped` task auto-approve. It is enforced by the repo's **pre-commit hook**
   (installed by `install.sh`), so every commit touching workflow files must pass
   it; `/workflow-eval --lint-only` runs the same script. Run it directly with
   `sh evals/lint.sh`.
2. **Live outcome-eval** (scored, on demand): each task's `fixtures/base` copy is
   run through `/new-task` under an eval-harness instruction that auto-approves and
   logs every gate (so it runs headless — `/new-task` itself is never modified). A
   judge subagent scores the gate summaries + Phase 7 retro + fixture test result
   against `rubric.md`.

## Running

```
/workflow-eval --lint-only                     # fast, deterministic; run any time
/workflow-eval                                 # lint + all tasks → new scorecard
/workflow-eval --tasks 02,03                   # subset
/workflow-eval --tasks 02 --variant skeptic-off  # ablation A/B vs baseline
/workflow-eval --repeat 3 --tasks 02           # more samples (tame LLM variance)
```

Scorecards land in `results/` and diff against the newest prior scorecard (or
`--baseline <path>`). The live layer is **expensive and opt-in** — unlike
`/workflow-maintenance` it is never auto-scheduled.

## Caveats

- Single-run outcomes vary (LLM non-determinism); a small per-dimension delta is
  noise. Raise `--repeat` before trusting an ablation verdict.
- The first cut is 3 tasks / 1 fixture covering the routing, bug-fix, and
  auto-approve paths — representative, not exhaustive.
