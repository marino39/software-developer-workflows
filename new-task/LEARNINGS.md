# /new-task learnings — general

Workflow lessons that apply to every project. Repo-specific lessons live in `learnings/<repo-key>.md` (key = origin repo name minus `.git`; fallback: main working-tree dir basename).

Rules — enforced at Phase 7 / GATE 4:

- One dated bullet per lesson, ≤300 chars: "when X, do Y (why)". No war stories.
- Curated, not append-only: a refining lesson rewrites the old bullet (newest date kept); a lesson promoted into the command/agent/skill files is deleted here. Skills (`~/.claude/skills/`) are the preferred home for multi-step procedures; bullets stay for one-line heuristics.
- Soft cap 30 bullets: over cap, the GATE 4 diff must include merges/prunes.
- Read at Phase 0; newest bullet wins over older ones and the command file.

- 2026-07-03: For correctness reviews, run a separate adversarial skeptic pass (fresh agent, default-refute) on every high-severity finding, distinct from the finder. Auditor confidence alone rates benign divergences as breaks and misses reproducible crashes.
- 2026-07-03: When "why didn't the suite catch this?" needs an out-of-scope heavy run to settle, don't expand scope or force certainty — record the best hypothesis plus a follow-up note and ship.
- 2026-07-03: A checkbox task index can lie — merged work stays `[ ]`. Before picking, filter candidates through git (grep log/`origin/<default>` for the ID), and have the fix PR clear its own index entry in the same diff.
- 2026-07-03: At a byte/format-compat boundary, reject-vs-accept is settled by the reference decode path: a field read unbounded inside a checksum-protected block is valid data — accept (with fallback), don't reject with a typed error; rejection breaks interop.
- 2026-07-04: `git fetch origin` before any local-vs-trunk reconcile, and re-fetch right before commit/`gh pr create`. Stale local trunk gives flatly wrong "what's pending" answers, and a parallel merge can land the same fix mid-session — check `HEAD..origin/<default>` for the task ID before finalizing.
- 2026-07-04: After a branch's PR squash-merges, don't reuse or re-PR it — its old commits re-diff as merged content. Start the next task on a fresh branch off `origin/<default>` (or cherry-pick the new commit), and run `gh pr list --head <branch> --state all` before `gh pr create`.
- 2026-07-04: For delete-dead-code/doc-only diffs, "no new test" is correct. Verification = build + vet + existing suite + a reviewer pass checking comment/claim accuracy against the code — replaces revert-discriminate, which is inert with no new test.
- 2026-07-04: Parallel coders must not share a mutable signature/type: give each `isolation: worktree` or serialize. Disjoint-package tasks can share one branch if coders run sequentially — the hazard is parallel git-index writes. Confirm with a real build; stale editor diagnostics lie.
- 2026-07-04: Settle doubts against git/build, not prose: garbled subagent reports, HTML-escaped code in report text (`&gt;` for `>`), and stale harness diagnostics have each contradicted a clean tree. `git status` + build + Read of the actual file adjudicate; never re-trust the report.
- 2026-07-04: Treat audit/spec prescriptions and "upstream does X" claims as hypotheses. When agents disagree — especially on a design's load-bearing premise — one reference-binary run or upstream source read settles it, far cheaper than implementing the wrong direction and rewriting.
- 2026-07-04: When "fix X" silently grows into an out-of-plan production change, stop at a gate and get explicit sign-off before committing — never let a test-greening task ship unannounced prod fixes.
- 2026-07-04: `gh pr edit` can exit 1 on the Projects-classic GraphQL deprecation; update title/body via `gh api -X PATCH repos/O/R/pulls/N -f title=... -F body=@file`.
- 2026-07-04: While blocked on a background agent, emit a plain text turn — don't speculatively load tools; the harness notifies on completion regardless.
- 2026-07-04: A "document + accept the risk" pick is invalid if a test already asserts the invariant — before offering document-vs-fix at a scope gate, grep the suite (incl. adversarial configs) for an existing invariant/stress test; if one exists, accepting means shipping a red test.
- 2026-07-04: For a "faithful port of upstream behavior" fix, probe at design time: for every persisted/shared input the fix reads, confirm some code path in our impl writes a real value — else the port is green-but-inert and the task is really a write-path prerequisite.