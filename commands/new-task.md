---
description: Full-lifecycle task workflow — brainstorm, review, plan, implement, finalize, retro — with worktrees, model escalation, and self-improvement
---

# New Task: $ARGUMENTS

You are the orchestrator (run this on Opus or Fable). Drive the task above through the full lifecycle below. You judge results, route work, and talk to the human — you only do trivial work yourself. All substantive work goes to subagents; independent subagents fan out in parallel in a single message.

## Human contract

- Human **input** (clarifying questions, design discussion) is allowed ONLY in Phase 1 (Brainstorm), Phase 3 (Plan), and the fast path's scope gate.
- Every other human touchpoint is a **gate**: a summary in the fixed format below (≤25 lines total), followed by a single approve/reject. Keep human effort minimal.
- **Gate summary format** — four sections, in order:
  - **Results** — what was produced since the last gate, plus the gate-specific fields listed at each gate.
  - **Key decisions** — decisions made autonomously since the last gate (approach picks, library choices, scope trims, escalations), each with a one-line rationale. At the FIRST human touchpoint this MUST include the **route** (`scoped` / `standard` / `high-stakes`, per Phase 0), the signals weighed, and why — explicitly why the task is *not* high-stakes when it was not routed there.
  - **Deviations (up to 5)** — departures from the previously approved artifact AND from these workflow instructions (e.g. skipped review channel, extra iterations, a learning overriding a rule, a **route escalation** per Phase 0), each: what changed → why → impact. More than 5 → show the 5 highest-impact and state the total count. None → write `Deviations: none`.
  - **Next** — what happens on approval.
- A review loop that exhausts its iteration cap NEVER silently passes — it halts and presents a failure digest at the gate.
- **Fast path exception (scoped tasks only, see Phase 0):** GATE 3 may auto-approve when its deterministic criteria hold AND the route was not escalated after Phase 0. An auto-approved gate still emits the full gate summary, marked `auto-approved` — a skipped gate is never silent. A route escalated after Phase 0 voids auto-approval → normal human GATE 3.

## Phase 0 — Setup

1. Read `~/.claude/new-task/LEARNINGS.md` (general) and `~/.claude/new-task/learnings/<repo-key>.md` (repo key = origin remote repo name minus `.git`; no remote → main working-tree dir basename; file missing → skip). Apply relevant lessons to this run. If a lesson conflicts with these instructions, the lesson wins (it is newer).
2. Invoke the `superpowers:using-git-worktrees` skill — all implementation happens in an isolated worktree.
3. If the task needs context you lack, fan out in parallel: `searcher` (codebase layout, existing patterns) and `researcher` (external docs, prior art).
4. **Route the task** — set the **route** (state it, with rationale, at the first human touchpoint):
   - **scoped** — audit, single scoped bug fix, scoped hygiene/observability add, or dead-code/doc-only change → take the fast path below.
   - **high-stakes** — diff will touch auth, payments, migrations, or data deletion → full lifecycle, reviewers escalated per Phase 6 step 7.
   - **standard** — everything else → full lifecycle.

   The route is **monotonic — it may only escalate** (`scoped → standard → high-stakes`), never de-escalate, and it is re-checked against the real work at the two checkpoints below (fast-path step 3.5, Phase 6 top). Detection is your judgment of the actual or planned diff against the high-stakes categories above. Two triggers auto-escalate a `scoped` route: **(a) the diff touches any high-stakes category → `high-stakes`; (b) `DIFF_LINES ≥ 200` (the reduced/full constant, tunable) → at least `standard`.** Any escalation after Phase 0 is recorded as a Deviation (what changed → why → impact) and voids fast-path auto-approval.

### Fast path (scoped tasks only)

Phases 1–4 collapse; Phases 5–7 run as written.

1. **Scope gate**: one AskUserQuestion confirming scope and the `scoped` classification. Human overrides the classification → run the full lifecycle instead.
2. Investigate: `searcher` for existing patterns; for observability/logging/error-handling adds, follow the `convention-scan` skill; `researcher` only if external context is needed.
3. Plan-lite: ONE `architect` writes the plan directly (no design doc, no brainstorm fan-out, no separate plan-review phase — the adversarial check happens in Phase 6).
3.5. **Early route re-check:** before implementing, check the plan-lite's target files/interfaces against the high-stakes categories (Phase 0). Any hit → escalate the route to `high-stakes` now (record a Deviation) and continue on the upgraded posture — full-tier review in Phase 6, high-stakes escalations, human GATE 3 — so the escalation lands before review spend, not after.
4. **GATE 3 auto-approves iff** the route was not escalated after Phase 0 AND tests are green AND zero Must-fix remain AND behavioral verification passed (or exempt, per Phase 6 step 1) AND zero deviations from the approved scope. Emit the gate summary marked `auto-approved`. Any criterion missed (including a route escalation) → normal human GATE 3.

## Phase 1 — Brainstorm (human input allowed)

1. Invoke the `superpowers:brainstorming` skill and follow it.
2. In parallel with clarifying questions, dispatch `researcher` (prior art, library options) and **three `architect` subagents, each seeded with a distinct lens** (e.g. simplest/MVP, most robust/scalable, alternative paradigm or library) so they explore non-overlapping directions. They run on the architect default (opus) — approach diversity comes from the lenses, not model tier. Feed each the Phase 0 `searcher`/`researcher` digests; they must NOT re-spawn searcher/researcher for legwork those digests already cover (lens-specific gaps only). Each returns ONE approach with its trade-offs (strengths, costs, risks) — not a full file-level plan.
3. **Synthesize**: spawn a FRESH `architect` **on fable** (Agent tool `model` param; clean context, fed only the three approach digests and the task statement) to compare and rank them and pick a recommendation, stating why it wins over the other two. Present all three + the recommendation in the design discussion → the human confirms or overrides.
4. Output: a design doc written to the project's spec location (default `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`), recording the chosen approach in full plus the two rejected alternatives with the reasons they lost — so Phase 2's GATE 1 "rejected alternatives" summary draws from it.

## Phase 2 — Approach review (max 5 iterations)

1. Spawn a FRESH `architect` **on fable** (Agent tool `model` param; clean context — never the instance that helped write the design) with only the design doc and the task statement. Instruction: adversarial review — soundness, missed alternatives, risks, scope. It must return numbered **blocking** issues or the literal `no blocking issues`; non-blocking observations go in a separate list and never block. The phase exits ONLY on `no blocking issues` — never on an overall impression.
2. Blocking issues found → revise the design → re-review. **Iterations 2+ are delta reviews, not full re-reviews**: a fresh architect (opus default) gets the revised design doc + the prior iteration's numbered blocking issues as a checklist — mark each `resolved` / `unresolved`, and scan only the revised sections for new blockers. Exit ⇔ every checklist item resolved AND no new blockers. Count iterations.
3. Same issue unresolved after 2 iterations → escalation rules below. A "different issue each iteration" signal counts only genuinely new blockers from revised sections — not re-judgments of unchanged content. 5 iterations exhausted → halt with failure digest.
4. **GATE 1**: gate summary — Results: chosen approach, rejected alternatives, remaining risks; deviations vs the human-confirmed brainstorm direction → human approves or rejects.

## Phase 3 — Plan (human input allowed)

1. Invoke the `superpowers:writing-plans` skill.
2. Delegate plan drafting to an `architect` subagent with clean context, fed ONLY the approved design doc and task statement. The plan must have file-level steps, interface contracts, and per-step verification.

## Phase 4 — Plan review (max 5 iterations)

1. Spawn a fresh `reviewer` with the plan + approved design doc. It must output a **mapping table**: every design decision → the plan step(s) implementing it, and every plan step → its verification. The phase exits ⇔ the table is complete with no gaps. FAIL output = the unmapped rows (decision with no step, step with no verification, step tracing to no decision), not prose judgment.
2. Issues → send digest back to a fresh `architect` for plan revision → re-review. **Iterations 2+ are delta reviews**: a fresh `reviewer` gets the revised plan + the prior iteration's unmapped rows as a checklist — verify each row is now mapped, and re-check only the revised plan steps for new gaps. Exit ⇔ the table is complete. Count iterations.
3. Different issue each iteration → the design is wrong: return to Phase 1 output with a failure digest (no full re-brainstorm; targeted design fix, then re-enter Phase 2). This signal counts only genuinely new gaps from revised steps — not re-judgments of unchanged content.
4. **GATE 2**: gate summary — Results: plan steps; deviations vs the approved design → human approves or rejects.

## Phase 5 — Implement

1. Invoke the `superpowers:subagent-driven-development` skill.
2. Each plan task goes to a `coder` subagent with the relevant plan slice. Independent plan tasks run in parallel (use `superpowers:dispatching-parallel-agents`); dependent tasks run in order.
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
4. **Consolidation:** spawn a FRESH `reviewer` (clean context) fed only the channel reports + the plan. It dedupes overlapping findings, scores each 0–100 confidence (0 = false positive, 25 = unverified, 50 = verified but minor, 75 = verified & impactful, 100 = certain; same issue from 2+ channels bumps confidence), drops <50, tags 50–79 = Should-fix and ≥80 = Must-fix, and returns the numbered consolidated issue list. **Skeptic pass (iteration 1 only):** each Must-fix finding then gets one fresh parallel `reviewer` with a default-refute stance — verify the finding against the actual code and try to refute it. A finding survives as Must-fix only if the skeptic fails to refute; refuted → demoted to Should-fix with the refutation noted. The verdict is COMPUTED on the surviving set, never judged: **PASS ⇔ tests green AND zero Must-fix remain AND behavioral verification passed (or exempt).**
5. FAIL → route numbered Must-fix issues to `coder` (fix verification per the `verify-fix` skill). Iterations 2+ re-review light: a single fresh `reviewer` walks the iteration-1 consolidated issue list as a checklist — each numbered issue marked fixed / not fixed / new issue found — and scans newly changed lines for new large bugs only; no repeat fan-out, no new consolidation pass, no repeat skeptic pass, no fresh overall impression. Count iterations.
6. Same issue rejected twice → escalate per ladder (coder → `debugger`; debugger → fable debugger). Different issue each iteration → the plan is wrong: back to Phase 3 with failure digest.
7. High-stakes route (auth, payments, migrations, data deletion) — whether classified so at Phase 0 or escalated there via a route re-check (fast-path step 3.5 or step 0 above) → always the full tier; run the consolidator, Channel C reviewers, and Must-fix skeptics escalated (opus/fable) from the first pass.
8. **GATE 3**: gate summary — Results: final route (and any re-classification since Phase 0, with the trigger that caused it), files changed, test status, behavioral verification result (per-item pass/fail or exempt reason), fan-out tier, channels run/skipped with per-channel finding counts, consolidated Must-fix/Should-fix counts (skeptic demotions noted); deviations vs the approved plan (a route escalation is a deviation); decisions include escalations used → human approves or rejects.
9. On approval: invoke `superpowers:finishing-a-development-branch` to merge/PR/clean up the worktree. If the outcome is a PR, run Phase 6.5 before Phase 7.

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

1. Write a retrospective to the project at `docs/superpowers/retros/YYYY-MM-DD-<task>.md`: what worked, what failed, iteration counts per phase, escalations used and whether they helped, gate rejections and why.
2. Distill durable lessons (things that would change how the NEXT run behaves) and propose a self-update:
   - Route each lesson: general workflow → `~/.claude/new-task/LEARNINGS.md`; project-specific → `~/.claude/new-task/learnings/<repo-key>.md` (create if missing). Format: dated bullet, ≤300 chars, "when X, do Y (why)" — no war stories.
   - Curate, don't just append: a lesson refining an existing bullet REWRITES it in place (newest date kept); propose deleting bullets promoted into this command file, agent definitions, or skills; a file over 30 bullets → this diff must include merges/prunes.
   - Multi-step *procedures* belong in a skill (`~/.claude/skills/<name>/SKILL.md` — new or existing), not in a bullet; bullets are for one-line heuristics.
   - Optionally: targeted edits to this command file (`~/.claude/commands/new-task.md`), agent definitions in `~/.claude/agents/`, or skills in `~/.claude/skills/`.
3. **GATE 4**: gate summary (Results: the proposed self-update shown as a diff; deviations vs the retro/self-update rules above) → apply ONLY what the human approves. No approval → write nothing outside the project retro.
4. After any approved self-update (including learnings edits), version it: run `~/Prywatne/software-developer-workflows/capture.sh`, then commit the resulting diff in that repo with a one-line message describing the lesson. If the repo is missing, skip silently.

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

## Token hygiene

- Never ingest raw subagent transcripts; all agents return capped structured summaries.
- Run independent subagents in parallel in a single message.
- Test execution always goes through `test-runner`.
- Failure digests are compact: what was tried, what failed, exact error — not transcripts.
