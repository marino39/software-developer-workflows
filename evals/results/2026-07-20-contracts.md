# Agent contract report — 2026-07-20 (`--contracts --agent architect`)

**Trigger:** the context-compaction change gave `architect` the `Write` tool and a
dual-mode Output contract (inline vs artifact mode) — the owed
`/workflow-eval --contracts --agent architect` for that contract edit.
**Scope:** architect only (the other six agents' contracts are unchanged by the
diff; coder/reviewer gained an input-form *preference* only, no output change).
**Setup:** two fresh git-initialized copies of `evals/fixtures/base` (no seed);
both contract stimuli from `evals/contracts/architect.md` dispatched live
(architect on opus per frontmatter); judge = fresh reviewer fed only the returns,
the contract spec, and the agent's Output contract section.

## Per-stimulus table

| Stimulus | conform | missing fields | violations |
|---|---|---|---|
| A (inline mode — no `artifact_path`) | **pass** | none — `goal`, `approach`, `steps`, `interfaces`, `risks` (labeled "risks / edge cases"), `verification` all present | none — fixture git-clean after the run (no file created or modified despite the agent now holding `Write`); no subagents spawned; ≈400 words, at the ~400 cap but not over |
| B (artifact mode — `artifact_path` given) | **pass** | none — `artifact_path` echoed, `summary` present (≈170 words, ≤200 cap), `steps` present (titles only) | none — the ONLY fixture change was the untracked file at the given artifact path (no tracked/source file touched); the written plan carries all six sections (417 words); no subagents spawned; inline return ≈250 words, at the ~250 cap |

**Result: 2/2 pass — the live agent honors the new dual-mode contract.**

## Deterministic adjudication (git, not judge)

- Stimulus A fixture: `git status --porcelain` empty — byte-clean. The key risk
  of the change (a `Write`-holding architect writing when not asked) did not
  manifest.
- Stimulus B fixture: only `?? docs/` (the artifact path); plan file structure
  verified by grep — `Goal / Approach / Steps / Interfaces / Risks & edge cases /
  Verification` all present.

## Observations

- Both returns land at their word caps rather than comfortably under — compliant
  under the "~" tolerance, but a margin to watch on future runs.
- A's "risks / edge cases" label is a cosmetic variant of the `risks` field
  (content matches the spec) — not drift.
- B's step titles carried no bodies; the full plan text lived only in the file,
  which is exactly the token-hygiene property the artifact mode exists to buy.

## Notes

- Environment: eval harness in a remote session; agents emulated via the Agent
  tool from their `agents/*.md` bodies with frontmatter models, per the standard
  harness adaptation (same as prior scorecards).
- Remaining owed evidence for the change rides the outcome-eval scorecard
  (same date, `context-compaction` label).
