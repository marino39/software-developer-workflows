# Task 10 — explain a mechanism (drives /explain, exercises classify + grounding + cost)

## Command

`/explain How does auth.ValidateToken work in the evalfixture module?` — this task
drives **`/explain`**. It must classify the question (→ **Mechanism**, case 2), sweep
with cheap parallel searchers, and synthesize a grounded walkthrough — read-only, no
implementation. See the driver note in `commands/workflow-eval.md` Layer 2.

## Fixture

`fixtures/base` — green. No `## Seed` bug; the `## Seed` only makes it a git repo so the
read-only assertion (`git status` clean) is meaningful. The target is `auth/auth.go`,
whose `ValidateToken` checks the `"Bearer "` scheme prefix and carries a documented
edge case (a `NOTE` comment: `"Bearer "` alone currently returns `true` — an empty token
is accepted).

## Seed

Applied to the fixture copy after copy, before dispatch:

```sh
git init -q
git add -A && git commit -q -m "base"
```

## Expected behaviour

- **Classification: Mechanism (case 2)** — "how does X work", stated in the answer header.
- **Output follows the Mechanism contract:** 1-line summary → numbered steps (each cited
  `file:line` in `auth/auth.go`) → inputs/outputs → **edge cases**.
- **Grounded:** every claim carries a `file:line`; the walkthrough correctly describes the
  `strings.HasPrefix(header, "Bearer ")` scheme check.
- **Surfaces the documented edge case:** the grounding contract means the answer must
  report the `NOTE`'d behavior — an empty token after `"Bearer "` is accepted (returns
  `true`) — because it is stated in the code, not invent behavior that isn't.
- **Cheap:** `searcher` tier only (haiku/low); NO `architect`/opus; synthesis done inline
  (no separate synthesis subagent); shallow (no `--deep`).
- **Read-only:** no files modified; no `--save`, so nothing written. `git status` clean.

## expect (scoring overrides)

- `Routing`: scores **classification** — resolved to **Mechanism (case 2)** with the
  header stated = 100; a wrong case = 0.
- `Outcome correctness`: the answer follows the Mechanism output contract (summary → cited
  steps → inputs/outputs → edge cases), is grounded in `auth/auth.go` with `file:line`,
  and surfaces the documented empty-token edge case. **Any hallucinated claim** (behavior
  not in the code, or a claim with no `file:line`) scores this dimension ≤ 40.
- `No escaped defects`: **n/a** (explain surfaces understanding, not a seeded defect) —
  renormalize onto the others.
- `Gate discipline`: **n/a** (no gates) — renormalize.
- `Efficiency`: **the cost check** — `searcher` (haiku/low) only, NO `architect`/opus
  escalation, synthesis **inline** (no synthesis subagent), shallow sweep. A run that
  escalates to `architect`/opus or spawns a synthesis subagent scores this dimension ≤ 40.
- Fail the run if any fixture file was modified (read-only), the question was misclassified,
  or a material claim is made with no `file:line` grounding.
