# /new-task learnings — general

Workflow lessons that apply to every project. Repo-specific lessons live in `learnings/<repo-key>.md` (key = origin repo name minus `.git`; fallback: main working-tree dir basename).

**This repo ships an empty seed.** Learnings are local runtime state, not versioned: `install.sh` seeds this file into `~/.claude/new-task/` only if missing, and nothing pushes the accumulated lessons back. Everyone starts from a clean slate; the bullets below the Rules grow only in the live `~/.claude` copy and stay on that machine.

## Format (v2)

Each lesson bullet: `- YYYY-MM-DD [tag][tag] <lesson> — src: <retro slug or date>`

- **Trigger tags** scope the lesson so Phase 0 applies only matching bullets. Two classes with different matching semantics (reuse before inventing a new tag):
  - **Subject tags** — match what the task is *about*:
    - language: `go` `rust` `ts`
    - code-area: `concurrency` `format-compat` `upstream-port`
    - task-type: `bugfix` `dead-code` `port`
  - **Activity tags** — match the run's *planned activities*, not the task's subject: `git` `pr` `ci` `test` `review` `scope-gate` `subagents` `verify`. A `[review]` lesson is in force on every run that reviews (all of them); `[pr]`/`[ci]` on runs whose outcome is a PR; `[scope-gate]` on fast-path runs. Activity lessons are never skipped because the task isn't "about" that activity.
- **src** links the retro that produced the lesson — provenance so an override of these instructions is auditable.
- **Prefer promotion for process lessons:** a lesson about a workflow activity itself (how to review/verify/gate) belongs as a targeted instruction-file edit (command/agent/skill) at GATE 4 — instruction files are always in force, bullets ride retrieval. An activity-tagged bullet is the interim home until the edit is warranted.

Rules — enforced at Phase 7 / GATE 4 (and lint Check 7):

- One dated bullet per lesson; lesson text ≤300 chars (date/tags/src metadata excluded): "when X, do Y (why)". No war stories.
- Every bullet carries ≥1 trigger tag and a `src:` ref.
- Curated, not append-only: a refining lesson rewrites the old bullet (newest date kept); a lesson promoted into the command/agent/skill files is deleted here. Skills (`~/.claude/skills/`) are the preferred home for multi-step procedures; bullets stay for one-line heuristics.
- Soft cap 30 bullets: over cap, the GATE 4 diff must include merges/prunes.
- Read at Phase 0; Phase 0 applies only the tag-matching bullets. Newest bullet wins over older ones and the command file — an override of these instructions is recorded as a Deviation citing the bullet's `src:`.
