---
description: Full-lifecycle task workflow — brainstorm, review, plan, implement, finalize, retro — with worktrees, model escalation, and self-improvement
---

# New Task: $ARGUMENTS

You are the orchestrator (run this on Opus at `xhigh` effort — Fable is optional and doubles the price of every context token; the escalation ladder already buys Fable where it pays). Drive the task above through the full lifecycle below. You judge results, route work, and talk to the human — you only do trivial work yourself. All substantive work goes to subagents; independent subagents fan out in parallel in a single message.

## Human contract

- Human **input that shapes the work** (design discussion, scope decisions) is allowed ONLY in Phase 1 (Brainstorm), Phase 3 (Plan), and the fast path's scope gate — the human does not redesign at an approve/reject gate. A **clarifying question is different and is allowed at ANY gate**: it is how the human makes the gate decidable, so it is answered in-band and never suppressed (see **Gate rendering & follow-ups** below).
- Every other human touchpoint is a **gate**: a summary in the fixed format below (four narrative sections ≤25 lines total), followed by a single approve/reject. Keep human effort minimal — but a gate must be **decidable**: its **Results** MUST carry that gate's decision evidence (the gate-specific fields listed at each gate), never just an artifact reference. A gate that names a decision without the evidence to make it is malformed.
- **Gate summary format** — four sections, in order:
  - **Results** — what was produced since the last gate, plus the gate-specific decision-evidence fields listed at each gate. These fields are not optional detail — they are what makes the gate decidable, so surface them inline (don't point at a file the human must open).
  - **Key decisions** — decisions made autonomously since the last gate (approach picks, library choices, scope trims, escalations), each with a one-line rationale. At the FIRST human touchpoint this MUST include the **route** (`scoped` / `standard` / `high-stakes`, per Phase 0), the signals weighed, and why — explicitly why the task is *not* high-stakes when it was not routed there.
  - **Deviations (up to 5)** — departures from the previously approved artifact AND from these workflow instructions (e.g. skipped review channel, extra iterations, a learning overriding a rule, a **route escalation** per Phase 0), each: what changed → why → impact. More than 5 → show the 5 highest-impact and state the total count. None → write `Deviations: none`.
  - **Next** — the decision framing: what approval will change (the concrete next action + what becomes hard to undo) and the consequence of rejection (where the loop returns).
- **Gate rendering & follow-ups (Claude Code):** present every gate — GATES 1–4, GATE I (`/iterate`), and the fast-path scope gate — as a single **plain-text message whose body IS the full gate summary** (and GATE 4's table), then **end the turn**. The human approves, rejects, or asks in the normal composer. Do **NOT** collect the approve/reject through `AskUserQuestion`: its compact picker cannot carry the ≤25-line decision evidence and renders the summary *behind* the widget, so the human decides without seeing what they are approving. The summary must be the last visible text — in the transcript, scrollable and persistent. `AskUserQuestion` is reserved for the Phase 1 / Phase 3 **discussion** touchpoints that are genuine option menus (e.g. picking among ranked approaches), and even there the decision evidence goes in the message body, never only inside the question string. A human **clarifying question at a gate** is answered in-band, after which the gate summary is **re-presented** — a question is never read as approve/reject and never advances or returns the phase; only an explicit approve/reject moves the workflow.
- The ≤25-line cap covers the four narrative sections only. A gate whose decision is inherently per-item (GATE 4) presents an additional **per-item decision table** outside the cap, one line per row — the cap must never be met by dropping decision evidence.
- A review loop that exhausts its iteration cap NEVER silently passes — it halts and presents a failure digest at the gate.
- **Fast path exception (scoped tasks only, see Phase 0):** GATE 3 may auto-approve when its deterministic criteria hold AND the route was not escalated after Phase 0. An auto-approved gate still emits the full gate summary, marked `auto-approved` — a skipped gate is never silent. A route escalated after Phase 0 voids auto-approval → normal human GATE 3.
- **Run ledger at every gate:** after presenting any gate (including auto-approved ones), create or update the run manifest (`docs/superpowers/runs/YYYY-MM-DD-<task>-manifest.md`, the same file Phase 6 step 10 finalizes) with the binding state to date — route + any escalations (with triggers), artifact paths (design doc, plan), applied learnings bullets, deviations so far, open findings, and the current phase + iteration count. This is additive — it changes no gate decision — but it means everything that binds later phases survives a session compaction, so a gate boundary is a safe point to discard older history (see **Compaction suggestion at gates** below).
- **Compaction suggestion at gates (heavy runs only):** you cannot measure your own context or compact yourself mid-run — but because the run ledger keeps all binding state on disk, a gate boundary is a safe discard point (conversation history older than this gate is reconstructible from the ledger + artifacts). When the run is **structurally heavy** — route is `standard`/`high-stakes` AND at least one of {a review loop ran ≥2 iterations; Phase 1 ran the 3-approach fan-out; this is GATE 3 approving a PR, whose Phase 6.5 CI wait re-enters the entire run history on every cold CI wake} — append ONE line to the gate's **Next**: that after approving, the human may run `/compact preserve the run-ledger path, route + escalations, artifact paths, open Must-fix/Should-fix, current phase + iteration` to drop the history later phases never reread. This is a suggestion to the human at a turn boundary, never a self-action. Suppress it on `scoped`/fast-path and short runs (small diff, ≤1 review iteration) — the nudge is for runs where accumulated context actually pays for the compaction.

## Phase 0 — Setup

1. Read `~/.claude/new-task/LEARNINGS.md` (general) and `~/.claude/new-task/learnings/<repo-key>.md` (repo key = origin remote repo name minus `.git`; no remote → main working-tree dir basename; file missing → skip). **Apply only the bullets whose trigger tags match this run's signals**, in two tag classes with different matching semantics:
   - **Subject tags** — language (`go` `rust` `ts`), code-area (`concurrency` `format-compat` `upstream-port`), task-type (`bugfix` `dead-code` `port`), repo-key — match **what the task is about**.
   - **Activity tags** — `review` `verify` `test` `git` `pr` `ci` `scope-gate` `subagents` — match **the run's planned activities**, not the task's subject: a run that will review code matches `[review]` (every route reviews, so `[review]` is effectively always in force), a run whose outcome will be a PR matches `[pr]`/`[ci]`, a fast-path run matches `[scope-gate]`. A process lesson is in force whenever its activity runs — never skipped because the task isn't "about" that activity.

   A bullet matching on neither class is out of scope for this run. State which bullets were applied (and which were excluded, with the class reasoning) at the first human touchpoint. If an applicable lesson conflicts with these instructions, the lesson wins (it is newer) — and you MUST record that override as a Deviation citing the lesson's `src:`, so it is auditable.
2. Invoke the `superpowers:using-git-worktrees` skill — all implementation happens in an isolated worktree. Then apply **artifact hygiene**: ensure `docs/superpowers/` is listed in the repo's local exclude file (`$(git rev-parse --git-common-dir)/info/exclude`; append it if absent — it is shared across worktrees). Workflow artifacts — design docs/specs, plans, run manifests, retros, triage manifests — are local working files: they are NEVER `git add`-ed, never committed, and never part of any PR diff. Use `info/exclude` (local-only, itself never committed), not the project's `.gitignore` — editing `.gitignore` would put a workflow change into the PR.
3. **Triage warm-start (if a triage manifest is referenced).** If the task names or links a triage manifest (`docs/superpowers/triage/*.md`, written by `/triage-issue`), load it FIRST and seed context from it — its `searcher`/`researcher` digests, its repro (command + discriminating test), and its root-cause/scope stand in for that legwork. Then fan out `searcher`/`researcher` ONLY for gaps the manifest does not cover, not to re-derive what it already carries. Seeding is additive — it changes no gate decision (the route floor in step 5 is the one binding inheritance) — but state at the first human touchpoint that the run is triage-seeded (which manifest), so the human can weigh the seeded context. No manifest → this step is a no-op.
4. If the task needs context the manifest did not supply, fan out in parallel: `searcher` (codebase layout, existing patterns) and `researcher` (external docs, prior art).
5. **Route the task** — set the **route** (state it, with rationale, at the first human touchpoint):
   - **scoped** — audit, single scoped bug fix, scoped hygiene/observability add, or dead-code/doc-only change → take the fast path below.
   - **high-stakes** — diff will touch auth, payments, migrations, or data deletion → full lifecycle, reviewers escalated per Phase 6 step 7.
   - **standard** — everything else → full lifecycle.

   The route is **monotonic — it may only escalate** (`scoped → standard → high-stakes`), never de-escalate, and it is re-checked against the real work at the two checkpoints below (fast-path step 3.5, Phase 6 top). **A referenced triage manifest (step 3) supplies the route floor** — inherit its route and escalate only; never de-escalate below what triage set (a `/triage-issue` that classified high-stakes cannot be silently downgraded here). Detection is your judgment of the actual or planned diff against the high-stakes categories above. Two triggers auto-escalate a `scoped` route: **(a) the diff touches any high-stakes category → `high-stakes`; (b) `DIFF_LINES ≥ 200` (the reduced/full constant, tunable) → at least `standard`.** Any escalation after Phase 0 is recorded as a Deviation (what changed → why → impact) and voids fast-path auto-approval.

### Fast path (scoped tasks only)

Phases 1–4 collapse; Phases 5–7 run as written.

1. **Scope gate**: present the scope and the `scoped` classification as a plain-text gate per the Human contract's **Gate rendering & follow-ups** rule (end the turn; do not use `AskUserQuestion`). This is the fast path's FIRST (and often only) human touchpoint, so it MUST carry the route rationale per the Human contract — the signals weighed and explicitly why the task is *not* high-stakes (which high-stakes categories the diff avoids: auth, payments, migrations, data deletion). Present that reasoning in the message body, not a bare "confirm scoped?"; it is the primary misroute-catch point. Human overrides the classification → run the full lifecycle instead.
2. Investigate: `searcher` for existing patterns; for observability/logging/error-handling adds, follow the `convention-scan` skill; `researcher` only if external context is needed.
3. Plan-lite: ONE `architect` writes the plan directly, in artifact mode (`artifact_path` = the plan location; it returns path + ≤200-word summary + step titles) — no design doc, no brainstorm fan-out, no separate plan-review phase (the adversarial check happens in Phase 6).
3.5. **Early route re-check:** before implementing, check the plan-lite's target files/interfaces against the high-stakes categories (Phase 0). Any hit → escalate the route to `high-stakes` now (record a Deviation) and continue on the upgraded posture — full-tier review in Phase 6, high-stakes escalations, human GATE 3 — so the escalation lands before review spend, not after.
4. **GATE 3 auto-approves iff** the route was not escalated after Phase 0 AND tests are green AND zero Must-fix remain AND behavioral verification passed (or exempt, per Phase 6 step 1) AND zero deviations from the approved scope. Emit the gate summary marked `auto-approved`. Any criterion missed (including a route escalation) → normal human GATE 3.

## Phase 1 — Brainstorm (human input allowed)

1. Invoke the `superpowers:brainstorming` skill and follow it.
2. In parallel with clarifying questions, dispatch `researcher` (prior art, library options) and **three `architect` subagents, each seeded with a distinct lens** (e.g. simplest/MVP, most robust/scalable, alternative paradigm or library) so they explore non-overlapping directions. They run on the architect default (opus) — approach diversity comes from the lenses, not model tier. Feed each the Phase 0 `searcher`/`researcher` digests; they must NOT re-spawn searcher/researcher for legwork those digests already cover (lens-specific gaps only). Each returns ONE approach with its trade-offs (strengths, costs, risks) — not a full file-level plan.
3. **Synthesize**: spawn a FRESH `architect` **on fable** (Agent tool `model` param; clean context, fed only the three approach digests and the task statement) to compare and rank them and pick a recommendation, stating why it wins over the other two. Present all three + the recommendation in the design discussion → the human confirms or overrides.
4. Output: the confirmed design goes to an `architect` in **artifact mode** — pass `artifact_path` = the project's spec location (default `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, left untracked per Phase 0's artifact hygiene); it writes the design doc recording the chosen approach in full plus the two rejected alternatives with the reasons they lost (so Phase 2's GATE 1 "rejected alternatives" summary draws from it) and returns only the path + ≤200-word summary. From here on the design doc is referenced by path — its full text never transits your context.

## Phase 2 — Approach review (max 5 iterations)

1. Spawn a FRESH `architect` **on fable** (Agent tool `model` param; clean context — never the instance that helped write the design) with only the design-doc **path** and the task statement (it Reads the doc itself; inline mode — no `artifact_path`). Instruction: adversarial review — soundness, missed alternatives, risks, scope. It must return numbered **blocking** issues or the literal `no blocking issues`; non-blocking observations go in a separate list and never block. The phase exits ONLY on `no blocking issues` — never on an overall impression.
2. Blocking issues found → a fresh `architect` in artifact mode (same `artifact_path`) revises the design doc in place from the issue list → re-review per **Review loop conventions**. Checklist source: the prior iteration's numbered blocking issues; reviewer: a fresh `architect` (opus default). Exit ⇔ every blocking issue resolved AND no new blocker.
3. Same blocker unresolved after 2 iterations → escalation rules below. Phase 2 has no earlier phase to return to, so a different-blocker-each-iteration triggers no backtrack here; 5 iterations exhausted → halt with a failure digest.
4. **GATE 1**: gate summary — Results (decision evidence): chosen approach, rejected alternatives with why they lost, remaining risks, and **what the Phase 2 adversarial review caught and how each blocker was resolved plus the iteration count** (or `no blocking issues` on iteration 1) — so the human sees the stress-test the approach survived, not just its risks; deviations vs the human-confirmed brainstorm direction → human approves or rejects.

## Phase 3 — Plan (human input allowed)

1. Invoke the `superpowers:writing-plans` skill.
2. Delegate plan drafting to an `architect` subagent with clean context, fed ONLY the approved design doc's path, the task statement, and `artifact_path` = the project's plan location (per the writing-plans skill; default `docs/superpowers/plans/YYYY-MM-DD-<topic>-plan.md`). The plan must have file-level steps, interface contracts, and per-step verification. The architect writes the plan file and returns the path + ≤200-word summary + step titles — the plan is referenced by path from here on, never inlined.

## Phase 4 — Plan review (max 5 iterations)

1. Spawn a fresh `reviewer` with the plan path + approved design-doc path (it Reads both). It must output a **mapping table**: every design decision → the plan step(s) implementing it, and every plan step → its verification. The phase exits ⇔ the table is complete with no gaps. FAIL output = the unmapped rows (decision with no step, step with no verification, step tracing to no decision), not prose judgment.
2. Issues → send the unmapped rows to a fresh `architect` in artifact mode (same plan `artifact_path`; it revises the plan file in place) → re-review per **Review loop conventions**. Checklist source: the prior iteration's unmapped rows; reviewer: a fresh `reviewer`. Exit ⇔ the mapping table is complete with no gaps.
3. Different issue each iteration → the design is wrong: return to Phase 1 output with a failure digest (no full re-brainstorm; targeted design fix, then re-enter Phase 2).
4. **GATE 2**: gate summary — Results (decision evidence): plan steps AND the Phase 4 **mapping-table result** — every design decision → its plan step(s), every step → its verification, and any residual unmapped rows (or `mapping complete, no gaps`) — so the human approves against the completeness/verifiability evidence the phase computed, not a bare step list; deviations vs the approved design → human approves or rejects.

## Phase 5 — Implement

1. Invoke the `superpowers:subagent-driven-development` skill.
2. Each plan task goes to a `coder` subagent as the plan path + the step number(s) it owns ("implement steps N–M of `<plan path>`") plus only run-specific context the file lacks — the coder Reads its slice; never inline plan text that exists on disk. Independent plan tasks run in parallel (use `superpowers:dispatching-parallel-agents`); dependent tasks run in order.
3. Coders delegate test execution to `test-runner` — raw test output never enters your context.
4. Bug-fix tasks: the coder proves the fix per the `verify-fix` skill (CI-exact command, revert-discriminate for new repro tests) before reporting done.
5. Loop guard per task: same test fails after 2 coder attempts, or fixes start touching unrelated files → escalate to `debugger` with a fresh context + failure digest.

## Phase 6 — Implementation review (max 5 iterations)

Compute once: `BASE_SHA=$(git merge-base HEAD <default-branch>)`, `HEAD_SHA=$(git rev-parse HEAD)`, `DIFF_LINES` = insertions + deletions from `git diff --shortstat $BASE_SHA..HEAD`.

0. **Route re-check (backstop, before behavioral verification):** re-run both triggers against the real diff — touches a high-stakes category → escalate the route to `high-stakes`; `DIFF_LINES ≥ 200` → escalate at least to `standard`. Any escalation is monotonic, recorded as a Deviation, forces the full fan-out tier (step 2), voids fast-path auto-approval (GATE 3 becomes human), and — if now `high-stakes` — applies step 7 escalations.

1. **Behavioral verification (iteration 1, before any review spend):** prove the change behaves as specified per the `verify-feature` skill — delegate to a `coder` (or `test-runner` when it is pure command-driving) to execute the plan's Verification section and drive the changed flow end-to-end, reporting observed vs expected per item. Exempt: doc-only/dead-code diffs and bug fixes already proven per `verify-fix` — record `verification: exempt (<reason>)`. Failures route back to Phase 5 coders BEFORE the review fan-out spends tokens.
2. **Pick the fan-out tier:** `DIFF_LINES < 200` AND route is not high-stakes AND the route was not escalated after Phase 0 (step 0) → **reduced** — Channel A plus ONE combined `reviewer` running C1's shallow bug scan with C3's compliance lens folded in; C2 dropped; codex recorded as `codex: skipped (small diff)`; no consolidator subagent — the orchestrator consolidates the two reports directly under step 4's scoring and verdict rules (the skeptic pass still runs). Everything else → **full** — all channels in step 3.
3. **Review fan-out (iteration 1 only)** — launch the tier's channels in parallel in a single message:
   - **Channel A — superpowers review:** invoke the `superpowers:requesting-code-review` skill; dispatch its reviewer subagent per its `code-reviewer.md` template with DESCRIPTION (what was built), PLAN_OR_REQUIREMENTS (plan file path), BASE_SHA, HEAD_SHA.
   - **Channel B — codex (conditional, full tier only):** if `command -v codex` succeeds, run a non-interactive review of the worktree diff — `codex exec --sandbox read-only "Review the diff between <BASE_SHA> and HEAD in this repo for bugs, edge cases, and design issues. Return numbered findings with file:line."` — with a hard timeout (~5 min), output captured to a scratch file. Output >~100 lines → have `test-runner` digest the file instead of ingesting it raw. CLI absent, errored, or timed out → record `codex: skipped (<reason>)` in the digest and move on — it degrades, never holds the consolidation barrier and never counts as a failure.
   - **Channel C — lens reviewers:** three parallel `reviewer` subagents on the worktree diff, one lens each (reduced tier: one combined C1+C3 reviewer per step 2):
     - C1 shallow bug scan — the changes only, no extra context; large bugs, ignore nitpicks.
     - C2 git history — blame/history of the modified code; bugs in light of that historical context.
     - C3 compliance — CLAUDE.md files covering the modified dirs + code comments in modified files; flag violations only if explicitly stated there.
4. **Consolidation:** spawn a FRESH `reviewer` (clean context) fed only the channel reports + the plan path. It dedupes overlapping findings, scores each 0–100 confidence (0 = false positive, 25 = unverified, 50 = verified but minor, 75 = verified & impactful, 100 = certain; same issue from 2+ channels bumps confidence), drops <50, tags 50–79 = Should-fix and ≥80 = Must-fix, and returns the numbered consolidated issue list. **Skeptic pass (iteration 1 only):** each Must-fix finding then gets one fresh parallel `reviewer` with a default-refute stance — verify the finding against the actual code and try to refute it. A finding survives as Must-fix only if the skeptic fails to refute; refuted → demoted to Should-fix with the refutation noted. The verdict is COMPUTED on the surviving set, never judged: **PASS ⇔ tests green AND zero Must-fix remain AND behavioral verification passed (or exempt).**
5. FAIL → route numbered Must-fix issues to `coder` (fix verification per the `verify-fix` skill), then re-review per **Review loop conventions**. Checklist source: the iteration-1 consolidated issue list; reviewer: a single fresh `reviewer`, also scanning newly changed lines for new large bugs only. Exit ⇔ the step-4 verdict computes PASS.
6. Same issue rejected twice → escalate per ladder (coder → `debugger`; debugger → fable debugger). Different issue each iteration → the plan is wrong: back to Phase 3 with failure digest.
7. High-stakes route (auth, payments, migrations, data deletion) — whether classified so at Phase 0 or escalated there via a route re-check (fast-path step 3.5 or step 0 above) → always the full tier; run the consolidator, Channel C reviewers, and Must-fix skeptics escalated (opus/fable) from the first pass.
8. **GATE 3**: gate summary — Results: final route (and any re-classification since Phase 0, with the trigger that caused it), files changed, test status, behavioral verification result (per-item pass/fail or exempt reason), fan-out tier, channels run/skipped with per-channel finding counts, consolidated Must-fix/Should-fix counts (skeptic demotions noted); deviations vs the approved plan (a route escalation is a deviation); decisions include escalations used → human approves or rejects.
9. On approval: first run the **artifact-hygiene check** — `git status --short` and `git diff --name-only $BASE_SHA..HEAD` must show no tracked or committed `docs/superpowers/` (or other workflow-artifact) paths; any that slipped into a commit are removed from the outgoing diff (`git rm --cached <path>` plus a removal commit, or amend when the offending commit is the head) BEFORE merging or opening the PR. Then invoke `superpowers:finishing-a-development-branch` to merge/PR/clean up the worktree — when the outcome is a PR, open it as a **draft** PR (`gh pr create --draft`, or the tool's draft option) so the diff can be reviewed and iterated on before it is marked ready for review. If the outcome is a PR, run Phase 6.5 before Phase 7.
10. **Finalize the run manifest** (begun at the first gate per the Human contract's run-ledger rule; enables warm-start `/iterate` — see `commands/iterate.md`): in `docs/superpowers/runs/YYYY-MM-DD-<task>-manifest.md`, record final route, design-doc + plan + retro paths, `BASE_SHA`/`HEAD_SHA`, default branch, branch name, outcome (merged / PR #N / local-kept), the behavioral-verification result, and the **open Should-fix** findings this run did not fix. If the outcome is a PR, do NOT delete the worktree — record its path so `/iterate` reuses it warm; for a local merge/discard the manifest's branch + `HEAD_SHA` still let `/iterate` recreate one. The manifest, like every workflow artifact, stays **untracked** (artifact hygiene, Phase 0 step 2) — never committed to the branch, never part of the PR. Writing the manifest is additive — it does not change any gate decision.

## Phase 6.5 — CI verification (PR path only, max 5 iterations)

Runs only when Phase 6 step 9 ended with a PR. Local merge, keep, or discard → skip to Phase 7.

1. Trunk health first: `gh run list --branch <default> --limit 3`. Trunk already red → the PR inherits that red; record it in the digest, don't chase it as a regression in your diff.
2. Wait for checks — **event-driven; never hold your turn open on a poll**:
   - **Remote session** (probe via ToolSearch for `subscribe_pr_activity`): subscribe to the PR and END THE TURN — CI/webhook events re-enter this phase at step 3. Webhook gap guard: success events may never be delivered, so if `send_later` (or equivalent scheduling) is available, arm a ~1h self check-in that re-runs `gh pr checks <pr>`, acts on the result, and re-arms until terminal. Unsubscribe and disarm on green, HALT, or gate rejection.
   - **Local CLI** (no subscription tools): run `gh pr checks <pr> --watch --interval 30` as a background task (Bash `run_in_background`) and end the turn — the harness re-invokes you when it completes. If the session must end instead, hand the human a re-entry line: `/loop 10m` with "verify CI for PR <n>, address failures" (or re-run this phase manually).
   - "No checks reported" right after creation → retry twice over ~1 min; still none → repo has no CI, skip to Phase 7.
3. Failures → triage per the `ci-triage` skill: send failing run IDs to `test-runner` for a digest — raw CI logs never enter your context. Infra-smelling failures get one free rerun per the skill; everything else costs an iteration.
4. Digest → `coder`: reproduce and verify per the `verify-fix` skill (CI's EXACT command first), then fix. Fresh `reviewer` on the fix diff BEFORE pushing; FAIL → back to coder within the same iteration. Push the reviewed fix (re-triggers CI), count the iteration, return to step 2. Local green is a hypothesis — CI adjudicates.
5. Same check failing after 2 coder fixes → escalate per ladder (coder → `debugger`; debugger → fable debugger — draws on the same one-fable budget as Phase 6). Different failure each iteration → the implementation is wrong: back to Phase 6 with a failure digest.
6. All checks green → proceed to Phase 7, no gate. Cap or ladder exhausted → HALT: leave the PR open, present the failure digest (checks still red, what was tried, escalations used).

## Phase 7 — Retrospective + self-improvement

When reached as the **batched retro for an `/iterate` session** (`commands/iterate.md`), this phase runs ONCE over the whole session: the retrospective and distilled lessons cover every entry in the manifest's iteration log, not a single tweak.

1. Write a retrospective to the project at `docs/superpowers/retros/YYYY-MM-DD-<task>.md` (untracked, per Phase 0's artifact hygiene): what worked, what failed, iteration counts per phase, escalations used and whether they helped, gate rejections and why.
2. Distill durable lessons (things that would change how the NEXT run behaves) and propose a self-update:
   - Route each lesson: general workflow → `~/.claude/new-task/LEARNINGS.md`; project-specific → `~/.claude/new-task/learnings/<repo-key>.md` (create if missing). Format (v2, per each file's header): `- YYYY-MM-DD [tag][tag] when X, do Y (why) — src: <this run's retro slug>` — lesson text ≤300 chars, ≥1 trigger tag from the documented vocabulary (reuse before inventing), and a `src:` linking the retro written in step 1. No war stories.
   - Curate, don't just append: a lesson refining an existing bullet REWRITES it in place (newest date kept); propose deleting bullets promoted into this command file, agent definitions, or skills; a file over 30 bullets → this diff must include merges/prunes.
   - Multi-step *procedures* belong in a skill (`~/.claude/skills/<name>/SKILL.md` — new or existing), not in a bullet; bullets are for one-line heuristics.
   - A lesson about a workflow **activity itself** (how to review, verify, gate, or dispatch) prefers a targeted instruction-file edit (this command, an agent definition, or a skill) over a bullet: instruction files are always in force, while bullets ride Phase 0 tag retrieval. Bullets are for subject-scoped heuristics; an activity-tagged bullet is the fallback when the edit isn't warranted yet.
   - Optionally: targeted edits to this command file (`~/.claude/commands/new-task.md`), agent definitions in `~/.claude/agents/`, or skills in `~/.claude/skills/`.
3. **GATE 4**: gate summary + a **per-item decision table** (outside the ≤25-line cap, one row per proposed lesson/edit) so the human can decide each on its merits, not rubber-stamp a raw diff. Columns:
   - **Item** — the proposed bullet/edit as a one-line diff.
   - **Evidence** — the specific finding from THIS run's retro (step 1) that produced it — the failure/iteration it generalizes, not just the `src:` slug. A lesson with no in-run evidence is not durable; drop it.
   - **Behavioral delta** — what the NEXT run does differently if this is applied (the whole justification for a durable lesson, per step 2). If you can't state the delta, the lesson isn't one.
   - **Protocol status** — for rows editing `~/.claude/commands/`, `~/.claude/agents/`, or `~/.claude/skills/`, the CLAUDE.md modification-protocol state: does `evals/lint.sh` pass; is a live `/workflow-eval` scorecard still owed (behavior-affecting); does it add/remove a complexity layer (→ ablation A/B + a `complexity-ledger.md` row owed). Learnings-file rows: `n/a (curated runtime state)`.
   Deviations vs the retro/self-update rules above. **Approval is per-row** — apply ONLY the rows the human approves; a rejected row writes nothing. No approval on any row → write nothing outside the project retro.
4. After any approved self-update (including learnings edits), version it: run `~/Prywatne/software-developer-workflows/capture.sh`, then commit the resulting diff in that repo with a one-line message describing the lesson. If the repo is missing, skip silently.

## Review loop conventions

Phases 2, 4, and 6 are bounded review loops (max 5 iterations; exhaustion halts with a failure digest at the gate — never a silent pass, per the Human contract). They share this re-review machinery; each phase supplies its own checklist source, reviewer, exit condition, and escalate/backtrack consequences.

- **Iteration 1** runs the phase's full review as written in that phase.
- **Iterations 2+ are delta re-reviews, never full re-reviews:** a fresh reviewer gets the revised artifact + the prior iteration's findings as a **checklist** (mark each `resolved` / `unresolved`; Phase 6: `fixed` / `not fixed` / `new`) and scans ONLY the revised sections for new issues — no repeat of iteration 1's heavy machinery (fan-out, consolidation, skeptic pass, or from-scratch mapping) and no fresh overall impression. Count every iteration.
- **"Different issue each iteration"** always means genuinely new issues surfaced from the *revised* sections — never re-judgments of unchanged content. Each phase below states what that signal triggers.

## Escalation ladder

Override models per invocation via the Agent tool `model` parameter. One rung at a time, fresh context + failure digest — never replay failed transcripts.

| Agent | Default | Escalate to | When |
|---|---|---|---|
| searcher | haiku | sonnet | empty/off-target results twice |
| researcher | sonnet | opus | contradictory sources, low-confidence twice |
| architect | opus | fable | Phase 1 synthesis and Phase 2 iteration-1 adversarial review are ALWAYS fable (by design, unbudgeted); otherwise same design issue unresolved 2 iterations |
| coder | sonnet | — | don't escalate model; route to debugger instead |
| reviewer | sonnet | opus → fable | same issue unresolved 2 iterations, or high-stakes diff |
| lens reviewers / consolidator / skeptics (Phase 6) | sonnet | opus → fable | same ladder and triggers as reviewer; shared fable budget |
| debugger | opus | fable | debugger reports unverified root cause |

Rules:
- Same error twice → escalate model one rung. Different error each time → the upstream artifact (design or plan) is wrong; go back one phase with a failure digest instead of escalating.
- Budget: exactly two fable slots are by design and unbudgeted — the Phase 1 synthesizer and the Phase 2 iteration-1 adversarial reviewer (both via the Agent tool `model` param; `architect` defaults to opus by frontmatter). Beyond those, AT MOST ONE fable escalation per task run (fable debugger, fable reviewer, OR fable architect — one total). Ladder exhausted → STOP, full failure digest to the human.
- Phase 6.5 (CI) escalations ride the same ladder and the same fable budget — a fable debugger there is the run's one fable escalation. Budget already spent in Phase 6 → the CI ladder ends at opus.

## Effort defaults

Reasoning **effort** is orthogonal to the model ladder above and is a **static per-agent default set in `agents/<name>.md` frontmatter** — it is NOT a per-run escalation rung. The Agent tool has no per-invocation `effort` override (anthropics/claude-code#43083), so the orchestrator cannot raise or lower an agent's effort mid-run the way it overrides `model`. To change an agent's reasoning depth, edit its frontmatter — do not add effort steps to the ladder. Agents with no `effort:` field inherit the session default (`high`).

| Agent | Effort | Why |
|---|---|---|
| searcher | low | Mechanical lookups; spend belongs in tool calls, not reasoning. |
| test-runner | low | Runs builds/tests, returns a digest — no deep reasoning. |
| architect | xhigh | Design + adversarial review; the deep-reasoning agents. |
| debugger | xhigh | Stubborn root-cause work. |

coder, reviewer, researcher run at the `high` default (no `effort:` field).

## Token hygiene

- Never ingest raw subagent transcripts; all agents return capped structured summaries.
- **Pass paths, not payloads:** artifacts (design doc, plan, manifest) live in files; a spawn prompt references them by path (+ step numbers for a slice) and never inlines artifact text that exists on disk — the agent Reads what it needs. The architect writes its own artifacts (artifact mode) so their full text never transits your context.
- Never Read back a file you or an agent just wrote — reference it by path; compose gate summaries once, in the gate message, not drafted in tool calls first.
- Run independent subagents in parallel in a single message.
- Test execution always goes through `test-runner`.
- Failure digests are compact: what was tried, what failed, exact error — not transcripts.
- **Compaction-safe by construction:** everything that binds future phases lives in artifacts (design doc, plan, run ledger/manifest, retro — kept current per the Human contract's run-ledger rule); conversation history older than the last approved gate is reconstructible from them, so a mid-run compaction (manual or automatic) must never change behavior. Gate boundaries are the safe `/compact` moments.
- **Session hygiene:** never switch your own model or effort mid-run (either invalidates the prompt cache for the entire context, and the next turn re-pays full input price for all of it); subagent `model` overrides via the Agent tool are fine — they are separate contexts.
