# software-developer-workflows

Source of truth for the multi-agent Claude Code workflow: 7 subagents, 3 skills, the full-lifecycle `/new-task` command with its learnings memory, and the schedulable `/workflow-maintenance` command.

The live copies run from `~/.claude/`; this repo versions them so improvements — hand edits here, or self-improvement edits made live by `/new-task` Phase 7 — are reviewed and tracked in git.

## Layout

```
agents/              7 subagent definitions (architect, coder, debugger,
                     researcher, reviewer, searcher, test-runner)
commands/            /new-task (full lifecycle; scoped tasks take a fast path)
                     /workflow-maintenance (capture sync, learnings curation,
                     trunk health — idempotent, safe to schedule)
skills/              procedural skills promoted from learnings:
                     verify-fix, convention-scan, ci-triage
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

`install.sh` never overwrites the live learnings files — they are curated runtime state owned by `/new-task` runs (general lessons in `LEARNINGS.md`, per-repo lessons in `learnings/<repo-key>.md`; one dated bullet ≤300 chars, rewritten in place at GATE 4, soft cap 30 per file); `capture.sh` is how they get versioned. Consequence: bullets pruned here (e.g. after promotion into a skill) do NOT propagate to `~/.claude` — that drift is expected, and `/workflow-maintenance` check 2 flags live bullets duplicating a skill so the next GATE 4 can delete them.

Skills, agents, and commands are source-of-truth files: `install.sh` always overwrites the live copies.

## Design notes

Model assignment, escalation ladder, fable budget, and nested-delegation rationale are documented in the command file itself (`commands/new-task.md`). Originally designed in Cowork (2026-07); handoff decisions: one generic coder (language conventions live in CLAUDE.md), debugger is escalation-only, agents return capped structured summaries, orchestrator never ingests raw transcripts.

Loop-placement revision (2026-07, after the Claude Code "Getting started with loops" article): Phase 6.5 waits on CI via events/background tasks instead of holding the orchestrator turn open; Phases 2/4/6 exit on deterministic criteria (numbered blocking issues, mapping-table completeness, tests-green + zero Must-fix) instead of reviewer gut verdicts; scoped tasks take a fast path where GATE 3 auto-approves on fully green criteria; multi-step procedures live in skills rather than learnings bullets.
