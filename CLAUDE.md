# CLAUDE.md — working in this repo

This repo is the source of truth for the multi-agent Claude Code workflow
(`commands/`, `agents/`, `skills/`). The live copies run from `~/.claude/`;
`./install.sh` syncs repo → live (and installs the pre-commit hook), `./capture.sh`
pulls live self-improvements back. See `README.md` for the full model.

## Modification protocol (read before editing the workflow)

Changes to the workflow must be evaluated, not just written. Two tiers:

1. **Every change to `commands/`, `agents/`, or `skills/` must pass the lint.**
   `evals/lint.sh` is deterministic (no LLM, no network) and checks reference
   integrity, route/tier consistency, phase completeness, gate-format, and agent
   contracts. The pre-commit hook runs it automatically and **blocks the commit on
   failure**; run it yourself any time with `sh evals/lint.sh` or
   `/workflow-eval --lint-only`. Do not bypass with `--no-verify` unless the lint
   itself is wrong (then fix the lint in the same change).

   **Agents are tools with contracts.** Each `agents/*.md` declares an
   `## Input contract` and `## Output contract` (backticked fields + a `Role:`
   line); the lint enforces their presence. When you change an agent's Output
   contract, update its `evals/contracts/<agent>.md` expected-fields spec in the
   same change, and re-run `/workflow-eval --contracts --agent <name>` to confirm
   the live agent still honors it.

2. **Behavior-affecting changes require a live eval + scorecard diff before merge.**
   If the change alters how a run behaves — edits to `commands/new-task.md`, an
   agent definition, or a skill's procedure — run `/workflow-eval` on the affected
   tasks and attach the scorecard (with its regression diff vs the latest
   `evals/results/` baseline) to the PR. Pure doc/comment/typo changes are exempt;
   say so in the PR.

3. **Adding or removing a complexity layer is gated on ablation.** Do not add a new
   review pass, tier, or escalation — or cut an existing one — without an
   `/workflow-eval --variant` A/B showing the layer earns (or fails to earn) its
   cost on the suite. Evidence over intuition; single-run deltas are noise, so
   raise `--repeat` before trusting a small result.

The live eval is expensive and non-deterministic, so it is **not** run per commit —
only the lint is. The scorecard is a pre-PR / on-demand step.

## After editing

Run `./install.sh` to sync the live copies and (re)install the pre-commit hook,
then `git diff` and commit. The hook re-runs the lint on the commit itself.
