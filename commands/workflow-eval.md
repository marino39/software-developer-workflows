---
description: Evaluate the workflow — deterministic lint over the instruction files plus an optional scored live run of /new-task against frozen fixture tasks, with ablation A/B. Expensive; opt-in, not auto-scheduled.
---

# Workflow Eval: $ARGUMENTS

Measure the workflow so complexity decisions are evidence-based (the "measure &
iterate" discipline). Two layers: a cheap deterministic **lint**, and an
expensive **live outcome-eval**. `$ARGUMENTS` flags:

- `--lint-only` — run only Layer 1 and stop.
- `--tasks NN,NN` — run only these task ids (default: all in `evals/tasks/`).
- `--variant <name>` — apply `evals/variants/<name>.md` as an ablation delta and
  emit an A/B comparison vs the baseline.
- `--baseline <path>` — scorecard to diff against (default: newest in `evals/results/`).
- `--repeat N` — samples per task per condition (default 1). Averages, and reports spread.

Locate the workflow repo the way `/workflow-maintenance` does — the directory
containing this repo's `capture.sh` (default `~/Prywatne/software-developer-workflows`).
Read `evals/` from there and write scorecards back there. Repo not found → report
`eval: repo not found` and stop. Everything runs against subagents; never ingest a
raw run transcript — collect only the structured artifacts named below.

## Layer 1 — Workflow lint (always, unless a live-only future flag says otherwise)

Deterministic checks over `commands/`, `agents/`, `skills/` in the located repo.
Delegate the mechanical scanning to a `searcher`; you adjudicate pass/fail. Report
each check `pass` or `fail` with offending `file:line` refs — no prose padding.

1. **Reference integrity** — every skill invoked (`superpowers:*` excluded; those
   are external) and every agent named in a command/agent file exists under
   `skills/<name>/SKILL.md` or `agents/<name>.md`. A dangling reference → fail.
2. **Route/tier consistency** (`commands/new-task.md`) — the `scoped` /
   `standard` / `high-stakes` route, the `DIFF_LINES` triggers, `auto-approve`,
   and the `reduced` / `full tier` pick must be mutually consistent: no path lets a
   route escalated after Phase 0 auto-approve GATE 3 or take the reduced tier, and
   the route is stated as monotonic (upgrade-only). Any contradiction → fail.
3. **Phase completeness** — every review phase (2, 4, 6, 6.5) names an exit
   criterion AND an iteration cap; the escalation-ladder table has a default +
   escalate-to rule for every agent that appears in a phase. Missing → fail.
4. **Gate-format consistency** — the four-section gate summary contract (Results /
   Key decisions / Deviations / Next) is the format referenced at every gate that
   emits a summary. Divergence → fail.

Lint failures are deterministic regressions — surface them plainly. `--lint-only`
→ emit the lint block of the summary and stop here.

## Layer 2 — Live outcome-eval (skipped under `--lint-only`)

For each selected task, `--repeat` times:

1. **Isolate**: copy `evals/fixtures/base` into a fresh temp worktree/dir (never
   mutate the fixture in place).
2. **Dispatch** `/new-task "<task statement>"` (from the task file) as a subagent,
   prepending the **eval-harness preamble**:
   > You are running under the eval harness. You are the approver: at every human
   > gate, AUTO-APPROVE and log the gate summary verbatim; NEVER call
   > AskUserQuestion or ask the human anything. Operate on the copied fixture at
   > `<path>`. When finished, return: final route, per-gate summaries, the Phase 7
   > retro, the final `git diff`, and the `go test ./...` result.

   Under `--variant <name>`, also prepend the variant's Delta block from
   `evals/variants/<name>.md`.
3. **Collect** only those structured artifacts (capped) — no raw transcript.
4. **Score**: spawn a FRESH `reviewer` as judge, fed only the collected artifacts +
   the task's `expect` block + `evals/rubric.md`. It returns the five per-dimension
   scores (0–100, honoring `expect` overrides and `n/a` reweights), the list of any
   escaped defects, and a one-line justification per dimension. Multiple repeats →
   average the dimensions and note the min–max spread.

## Scorecard

Write `evals/results/YYYY-MM-DD-<label>-scorecard.md` (`<label>` = `baseline` or
the variant name; date via `date +%F`). Include:

- Per-task table: the five dimension scores, task score, escaped-defect count,
  repeat spread.
- Suite score (mean of task scores).
- **Regression section** vs the baseline scorecard: every dimension that dropped
  > 10 points, and every new escaped defect — listed explicitly, never averaged
  away. First run ever → `baseline established, no prior scorecard`.
- **Ablation section** (only under `--variant`): per-dimension delta vs the
  baseline non-variant scorecard + the verdict line from the variant file
  (`<variant>: <Δ escaped defects>, <Δ cost> → justified | not justified on this suite`).

## Summary

Compact, ≤ 4 lines per section: lint (pass/fail counts + first failure), suite
score + any regressions, ablation verdict if run. No transcripts, no raw logs.
This command is expensive — it does not schedule itself and does not push.
