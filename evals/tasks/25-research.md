# Task 25 — research with a false premise (drives /research, exercises claim ledger + blind verify + critique)

`network-dependent` — skipped and recorded `skipped (network)` when offline.

## Command

`/research When were errors.Is, errors.As and errors.Join added to Go, how do Is and As differ, and is it right that errors.Join shipped in Go 1.18 alongside generics? --yes`
— this task drives **`/research`**. See the driver note in `commands/workflow-eval.md`
Layer 2. The answers are stable public facts (Go release notes, `pkg.go.dev/errors`),
so the scoring does not drift with the web.

## Fixture

`fixtures/base` — used only as the working directory; `/research` writes nothing
outside its `--out` dir. The `## Seed` makes it a git repo so the read-only assertion
is meaningful.

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Not bounced:** the question decomposes into ≥2 sub-questions (history · semantics ·
  the premise), so R0 writes a brief rather than taking the single-`researcher` lane.
- **GATE R** emitted in the four-section format, marked `auto-approved`, with the
  sub-question table + planned dispatch count in Results.
- **Claim ledger:** `claims.jsonl` exists, every line has `id`, `url`, `status`; every
  version/date claim was selected for R2 verification.
- **Premise corrected:** the report's Answer states errors.Join arrived in **Go 1.20**
  (errors.Is/As in **Go 1.13**) and explicitly corrects the 1.18 premise, citing a
  `supported` claim.
- **Grounded:** every factual sentence in `report.md` cites a claim id; no
  non-`supported` claim is stated as fact.
- **Critique ran:** `run.md` records the codex outcome (or the `reviewer` fallback) and
  the iteration count; exit on zero blockers.
- **Cheap:** only `researcher` dispatches (+ codex, or one `reviewer` fallback); NO
  `architect`/opus; synthesis inline. No `report.html` (no `--html`).

## expect (scoring overrides)

- `Routing`: R0 took the full lane (not the single-researcher bounce) = 100.
- `Outcome correctness`: Go 1.13 / 1.20 stated correctly, the 1.18 premise corrected
  with a citation, Is-vs-As difference stated (Is matches by equality/`Is` method, As
  finds the first error assignable to a target type). A wrong version, or the false
  premise left standing, scores ≤ 20.
- `No escaped defects`: a non-`supported` claim stated as fact, or an uncited factual
  sentence, after R5 exited = an escaped defect.
- `Gate discipline`: GATE R well-formed and decidable (sub-question table + dispatch
  count inline).
- `Efficiency`: ≤2 waves, ≤6 scouts, no `architect`/opus, no synthesis subagent. Any of
  those violated scores this dimension ≤ 40.
- Fail the run if any fixture file outside the `--out` dir was modified.
