# software-developer-workflows

Source of truth for the multi-agent Claude Code workflow: 7 subagents, 4 skills, the full-lifecycle `/new-task` command with its learnings memory, the schedulable `/workflow-maintenance` command, and the `/workflow-eval` measure-and-iterate harness.

The live copies run from `~/.claude/`; this repo versions them so improvements — hand edits here, or self-improvement edits made live by `/new-task` Phase 7 — are reviewed and tracked in git.

## Layout

```
agents/              7 subagent definitions (architect, coder, debugger,
                     researcher, reviewer, searcher, test-runner)
commands/            /new-task (full lifecycle; scoped tasks take a fast path)
                     /workflow-maintenance (capture sync, learnings curation,
                     trunk health — idempotent, safe to schedule)
                     /workflow-eval (lint + scored live run of /new-task against
                     frozen tasks, with ablation A/B — expensive, opt-in)
skills/              procedural skills promoted from learnings:
                     verify-fix, verify-feature, convention-scan, ci-triage
evals/               /workflow-eval inputs & outputs: rubric, one Go fixture,
                     frozen tasks, ablation variants, dated result scorecards
new-task/LEARNINGS.md  general lessons memory (live file is runtime state)
new-task/learnings/<repo>.md  per-repo lessons (live files are runtime state)
install.sh           repo -> ~/.claude  (learnings seeded only if missing)
capture.sh           ~/.claude -> repo  (pull live self-improvements, then
                     review `git diff` and commit)
```

## Flow

- **Improve in repo:** edit files here → `./install.sh` → use.
- **Improve via runs:** `/new-task` GATE 4 edits live files → `./capture.sh` → `git diff` → commit what you keep.
- **Maintain on a schedule:** run `/workflow-maintenance` periodically — local cron (`claude -p "/workflow-maintenance"`) or a remote routine. It commits faithful capture diffs, proposes (never applies) learnings prunes, and reports red trunks.
- **Measure before adding/cutting complexity:** run `/workflow-eval` to score the workflow. `--lint-only` is a cheap deterministic consistency check over the instruction files (run any time); a full run scores `/new-task` against the `evals/` fixture tasks and writes a dated scorecard, and `--variant <name>` ablates a layer (e.g. the skeptic pass) for an A/B verdict on whether it earns its cost. The live layer is expensive and opt-in — never auto-scheduled. See `evals/README.md`.

`install.sh` never overwrites the live learnings files — they are curated runtime state owned by `/new-task` runs (general lessons in `LEARNINGS.md`, per-repo lessons in `learnings/<repo-key>.md`; one dated bullet ≤300 chars, rewritten in place at GATE 4, soft cap 30 per file); `capture.sh` is how they get versioned. Consequence: bullets pruned here (e.g. after promotion into a skill) do NOT propagate to `~/.claude` — that drift is expected, and `/workflow-maintenance` check 2 flags live bullets duplicating a skill so the next GATE 4 can delete them.

Skills, agents, and commands are source-of-truth files: `install.sh` always overwrites the live copies.

## Design notes

Model assignment, escalation ladder, fable budget, and nested-delegation rationale are documented in the command file itself (`commands/new-task.md`). Originally designed in Cowork (2026-07); handoff decisions: one generic coder (language conventions live in CLAUDE.md), debugger is escalation-only, agents return capped structured summaries, orchestrator never ingests raw transcripts.

Loop-placement revision (2026-07, after the Claude Code "Getting started with loops" article): Phase 6.5 waits on CI via events/background tasks instead of holding the orchestrator turn open; Phases 2/4/6 exit on deterministic criteria (numbered blocking issues, mapping-table completeness, tests-green + zero Must-fix) instead of reviewer gut verdicts; scoped tasks take a fast path where GATE 3 auto-approves on fully green criteria; multi-step procedures live in skills rather than learnings bullets.

Cost/quality revision (2026-07): architect defaults to opus with exactly two by-design fable slots (Phase 1 synthesizer, Phase 2 iteration-1 adversarial reviewer); Phases 2/4 iterations 2+ are delta reviews (prior issues as a checklist, scan only revised sections) matching Phase 6's light re-review; Phase 6 fan-out is risk-scaled (small non-high-stakes diffs get a reduced tier, codex timeout cut to ~5 min); Must-fix findings survive a default-refute skeptic pass before reaching coders (promoted from a 2026-07-03 learning); features get end-to-end behavioral verification via the new `verify-feature` skill before review, and PASS/auto-approve criteria include it.
