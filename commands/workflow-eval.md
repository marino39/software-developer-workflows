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
- `--contracts` — run the agent contract test (Layer 3 below) instead of the
  outcome-eval. `--agent <name>` restricts it to one agent (default: all 7).

Locate the workflow repo the way `/workflow-maintenance` does — the directory
containing this repo's `capture.sh` (default `~/Prywatne/software-developer-workflows`).
Read `evals/` from there and write scorecards back there. Repo not found → report
`eval: repo not found` and stop. Everything runs against subagents; never ingest a
raw run transcript — collect only the structured artifacts named below.

## Layer 1 — Workflow lint (always)

Run the deterministic lint script and report its result — do NOT re-implement the
checks with an LLM:

```
sh <repo>/evals/lint.sh
```

`evals/lint.sh` is no-LLM, no-network, and exits non-zero on any failure. It
checks the instruction files (`commands/`, `agents/`, `skills/`) for: reference
integrity (every non-`superpowers:*` skill/agent referenced exists); route/tier
consistency (`commands/new-task.md` — no path lets a route escalated after Phase 0
auto-approve GATE 3 or take the reduced tier; route declared monotonic); phase
completeness (iteration caps + escalation ladder present); gate-format
consistency (the four-section summary contract); and agent contracts (every
`agents/*.md` declares a well-formed Input + Output contract with fields and a
Role — the static half of Layer 3). This is the same script the pre-commit hook
runs, so the command and the hook can never disagree.

Surface the script's pass/fail lines verbatim. Non-zero exit is a deterministic
regression. `--lint-only` → emit the lint block of the summary and stop here.

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

## Layer 3 — Agent contract test (`--contracts`)

Behavioral ACI test: does each agent honor its declared Input/Output contract?
Static presence/format is already covered by `evals/lint.sh` Check 5 (and the
pre-commit hook); this layer exercises the live agent. For each selected agent
(all of `evals/contracts/*.md`, or the one named by `--agent`):

1. **Setup**: copy `evals/fixtures/base` into a fresh temp dir; perform any setup
   the contract's Stimulus section names (e.g. reviewer/coder need a committed diff).
   A contract tagged `network-dependent` (researcher) is **skipped when offline** —
   record `skipped (network)`.
2. **Dispatch** the agent (via the Agent tool, its own `agentType`) with the
   Stimulus as its prompt, pointed at the fixture copy. Collect only its returned
   report — no raw transcript.
3. **Judge**: spawn a FRESH `reviewer` as judge, fed only the agent's output, the
   contract's **Expected output fields** + **Role constraints**, and the agent's
   `## Output contract` from `agents/<name>.md`. It returns, per agent:
   - `conform` — `pass` iff every declared output field is present AND no role
     constraint was violated (read-only agents changed no fixture files, spawn
     limits respected).
   - `missing` — declared fields absent from the output.
   - `violations` — role breaches (out-of-scope edits, forbidden spawns).
4. Determine file-edit role adherence deterministically where possible: `git
   status` in the fixture copy after a read-only agent must be clean.

Output a **contract report** (not the 5-dimension scorecard): a per-agent table of
`conform` / missing fields / violations, written to
`evals/results/YYYY-MM-DD-contracts.md`. Any `fail` is a regression — the agent
drifted from its contract, or the contract is stale and needs updating alongside
the agent.

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
