# /new-task learnings — general

Workflow lessons that apply to every project. Repo-specific lessons live in `learnings/<repo-key>.md` (key = origin repo name minus `.git`; fallback: main working-tree dir basename).

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

- 2026-07-03 [test][scope-gate] When "why didn't the suite catch this?" needs an out-of-scope heavy run to settle, don't expand scope or force certainty — record the best hypothesis plus a follow-up note and ship. — src: retro 2026-07-03
- 2026-07-03 [git][pr] A checkbox task index can lie — merged work stays `[ ]`. Before picking, filter candidates through git (grep log/`origin/<default>` for the ID), and have the fix PR clear its own index entry in the same diff. — src: retro 2026-07-03
- 2026-07-03 [format-compat][port] At a byte/format-compat boundary, reject-vs-accept is settled by the reference decode path: a field read unbounded inside a checksum-protected block is valid data — accept (with fallback), don't reject with a typed error; rejection breaks interop. — src: retro 2026-07-03
- 2026-07-04 [git][pr] `git fetch origin` before any local-vs-trunk reconcile, and re-fetch right before commit/`gh pr create`. Stale local trunk gives flatly wrong "what's pending" answers, and a parallel merge can land the same fix mid-session — check `HEAD..origin/<default>` for the task ID before finalizing. — src: retro 2026-07-04
- 2026-07-04 [git][pr] After a branch's PR squash-merges, don't reuse or re-PR it — its old commits re-diff as merged content. Start the next task on a fresh branch off `origin/<default>` (or cherry-pick the new commit), and run `gh pr list --head <branch> --state all` before `gh pr create`. — src: retro 2026-07-04
- 2026-07-04 [dead-code][test][verify] For delete-dead-code/doc-only diffs, "no new test" is correct. Verification = build + vet + existing suite + a reviewer pass checking comment/claim accuracy against the code — replaces revert-discriminate, which is inert with no new test. — src: retro 2026-07-04
- 2026-07-04 [subagents][concurrency] Parallel coders must not share a mutable signature/type: give each `isolation: worktree` or serialize. Disjoint-package tasks can share one branch if coders run sequentially — the hazard is parallel git-index writes. Confirm with a real build; stale editor diagnostics lie. — src: retro 2026-07-04
- 2026-07-04 [verify][subagents] Settle doubts against git/build, not prose: garbled subagent reports, HTML-escaped code in report text (`&gt;` for `>`), and stale harness diagnostics have each contradicted a clean tree. `git status` + build + Read of the actual file adjudicate; never re-trust the report. — src: retro 2026-07-04
- 2026-07-04 [upstream-port][review] Treat audit/spec prescriptions and "upstream does X" claims as hypotheses. When agents disagree — especially on a design's load-bearing premise — one reference-binary run or upstream source read settles it, far cheaper than implementing the wrong direction and rewriting. — src: retro 2026-07-04
- 2026-07-04 [scope-gate] When "fix X" silently grows into an out-of-plan production change, stop at a gate and get explicit sign-off before committing — never let a test-greening task ship unannounced prod fixes. — src: retro 2026-07-04
- 2026-07-04 [pr][ci] `gh pr edit` can exit 1 on the Projects-classic GraphQL deprecation; update title/body via `gh api -X PATCH repos/O/R/pulls/N -f title=... -F body=@file`. — src: retro 2026-07-04
- 2026-07-04 [subagents] While blocked on a background agent, emit a plain text turn — don't speculatively load tools; the harness notifies on completion regardless. — src: retro 2026-07-04
- 2026-07-04 [scope-gate][test] A "document + accept the risk" pick is invalid if a test already asserts the invariant — before offering document-vs-fix at a scope gate, grep the suite (incl. adversarial configs) for an existing invariant/stress test; if one exists, accepting means shipping a red test. — src: retro 2026-07-04
- 2026-07-04 [upstream-port][port][verify] For a "faithful port of upstream behavior" fix, probe at design time: for every persisted/shared input the fix reads, confirm some code path in our impl writes a real value — else the port is green-but-inert and the task is really a write-path prerequisite. — src: retro 2026-07-04
