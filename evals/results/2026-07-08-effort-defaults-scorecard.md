# Workflow eval scorecard — 2026-07-08 (effort-defaults)

**Label:** effort-defaults · **Suite:** tasks 01, 02, 03 · **Variant:** none (frontmatter-swap A/B)
**Change under test:** static per-agent `effort:` frontmatter — `searcher`/`test-runner` → `low`,
`architect`/`debugger` → `xhigh`; `coder`/`reviewer`/`researcher` unchanged (`high` default).
Committed with the change; see `evals/complexity-ledger.md`.

## Layer 1 — lint

`sh evals/lint.sh` → all 8 checks PASS (standalone and via the pre-commit hook).

## Outcome-neutrality — regression check vs `2026-07-08-baseline-scorecard.md`

Frontmatter-swap A/B (baseline = effort stripped from the live agents; treatment = effort set),
each task on an isolated git-init copy of `evals/fixtures/base` (task 02 seed applied), scored by
a fresh `reviewer`-as-judge against `evals/rubric.md`.

| Task | Route (expected → actual) | Routing | Outcome | No-escaped | Gate | Efficiency | Escaped | Score |
|---|---|---|---|---|---|---|---|---|
| 01 doc-only | scoped → **scoped** ✓ | 98 | 100 | n/a¹ | 95 | 95 | none | **97.3** |
| 02 bugfix | scoped → **scoped** ✓ | 97 | 100 | 100 | 92 | 95 | none | **97.3** |
| 03 route-correct | → **high-stakes** ✓² | 100 | 100 | 100 | 95 | 90 | none | **97.75** |

¹ Task 01 `expect` marks *No-escaped* n/a and reweights. ² Reached high-stakes via Phase 0-direct; full tier + human GATE 3 held (Prop #4 intact).

**Suite = 97.45** (baseline 93.7) · **0 escaped defects.** No dimension regressed. The one >10pt
swing (task 03 Efficiency 65→90) is a coder-tooling variance improvement, **not** attributable to
effort. Conclusion: the effort defaults are **behaviorally safe** — same routing/outcomes/gates as
baseline.

## Cost measurement — is the effort lever doing anything?

**Run-level A/B (whole `/new-task` runs):** inconclusive. Suite totals were a wash within noise
(baseline 178,165 tok / 15m22s vs effort 171,988 tok / 15m03s; −3.5% tok, −2.1% time), with
per-task deltas swinging ±20% driven by iteration-count non-determinism, not effort. (An attempt
to mine per-agent tokens from run transcripts failed — the recorded `output_tokens` is a partial
artifact, e.g. architect files log 4–60 tokens for multi-thousand-word outputs — which is why the
isolated microbenchmark below was built.)

**Isolated microbenchmark (the decisive test), n=6 per cell.** Dispatch a single agent *directly*
(no orchestration), toggling only its frontmatter `effort`, and read that dispatch's own
`subagent_tokens` + `duration_ms`. Architect prompt: a self-contained design task (0 tool calls,
pure reasoning — where `xhigh` should bite hardest). test-runner: `go build`+`go test` on a fixed
module.

| Agent | Condition | Tokens mean (range) | Duration mean (range) |
|---|---|---|---|
| architect | high (baseline) | 7,424 (7,424) | 38.7s (27.8–46.4) |
| architect | **xhigh** | 7,428 (7,427–7,431) | 38.3s (31.5–46.1) |
| test-runner | high (baseline) | 9,067 (9,015–9,103) | 9.1s (6.7–12.1) |
| test-runner | **low** | 9,076 (9,040–9,117) | 7.5s (6.8–8.0) |

**No measurable effort effect, in either direction.** Tokens are essentially constant per
(agent, prompt) regardless of effort — `subagent_tokens` tracks context size, not reasoning depth.
Durations don't separate either: architect high vs xhigh is 38.7s vs 38.3s; test-runner's −17% sits
inside fully overlapping ranges. (A one-shot pilot that looked like +44% was noise that vanished at
n=6 — hence the pilot-first-then-N discipline.)

## Verdict

The effort lever is **inert in this SDK eval harness**, within measurement resolution — the harness
does not apply frontmatter `effort` in a way that changes observable token or wall-clock cost. This
is **not** "effort does nothing": the workflow's real deployment target is the production Claude
Code CLI, where frontmatter `effort` is a supported, honored field (per Anthropic's effort docs),
and the change is outcome-neutral + near-zero cost (4 frontmatter lines, no workflow logic). So the
defaults are **retained as documented-best-practice config that bites on the production CLI**; this
repo's sandbox simply can't demonstrate the cost delta. A definitive cost number needs a harness/CLI
that surfaces real per-call generation+thinking tokens.

## Method / caveats

- Isolated microbenchmark: n=6, single fixed prompt per agent, batch-parallel per condition
  (symmetric self-contention → the between-condition delta is fair; absolute durations inflated).
- `subagent_tokens` is the only reliable token figure and is constant per (agent, prompt); the
  per-message transcript `output_tokens` is a partial artifact and was not used.
- searcher (`low`) and debugger (`xhigh`) were not benchmarked — architect (strongest `xhigh` case)
  and test-runner (clean `low` case) bracket the question, and both are null.
- Eval runs dispatched under the eval-harness preamble (auto-approver at every gate; GATE 4
  propose-only — nothing written to `~/.claude`, no `capture.sh`); only structured artifacts
  collected, no raw transcripts.
