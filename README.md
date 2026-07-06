# software-developer-workflows

Source of truth for the multi-agent Claude Code workflow: 7 subagents and the full-lifecycle `/new-task` command with its learnings memory.

The live copies run from `~/.claude/`; this repo versions them so improvements — hand edits here, or self-improvement edits made live by `/new-task` Phase 7 — are reviewed and tracked in git.

## Layout

```
agents/              7 subagent definitions (architect, coder, debugger,
                     researcher, reviewer, searcher, test-runner)
commands/            /new-task (full lifecycle)
new-task/LEARNINGS.md  general lessons memory (live file is runtime state)
new-task/learnings/<repo>.md  per-repo lessons (live files are runtime state)
install.sh           repo -> ~/.claude  (learnings seeded only if missing)
capture.sh           ~/.claude -> repo  (pull live self-improvements, then
                     review `git diff` and commit)
```

## Flow

- **Improve in repo:** edit files here → `./install.sh` → use.
- **Improve via runs:** `/new-task` GATE 4 edits live files → `./capture.sh` → `git diff` → commit what you keep.

`install.sh` never overwrites the live learnings files — they are curated runtime state owned by `/new-task` runs (general lessons in `LEARNINGS.md`, per-repo lessons in `learnings/<repo>.md`; one dated bullet ≤300 chars, rewritten in place at GATE 4, soft cap 30 per file); `capture.sh` is how they get versioned.

## Design notes

Model assignment, escalation ladder, fable budget, and nested-delegation rationale are documented in the command file itself (`commands/new-task.md`). Originally designed in Cowork (2026-07); handoff decisions: one generic coder (language conventions live in CLAUDE.md), debugger is escalation-only, agents return capped structured summaries, orchestrator never ingests raw transcripts.
