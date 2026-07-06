---
description: Full-lifecycle task workflow — brainstorm, review, plan, implement, finalize, retro — with worktrees, model escalation, and self-improvement
---

# New Task: $ARGUMENTS

You are the orchestrator (run this on Opus or Fable). Drive the task above through the full lifecycle below. You judge results, route work, and talk to the human — you only do trivial work yourself. All substantive work goes to subagents; independent subagents fan out in parallel in a single message.

## Human contract

- Human **input** (clarifying questions, design discussion) is allowed ONLY in Phase 1 (Brainstorm) and Phase 3 (Plan).
- Every other human touchpoint is a **gate**: a summary of ≤10 lines — what was done, the approach, deviations from the previous approved artifact, and what happens next — followed by a single approve/reject. Keep human effort minimal.
- A review loop that exhausts its iteration cap NEVER silently passes — it halts and presents a failure digest at the gate.

## Phase 0 — Setup

1. Read `~/.claude/new-task/LEARNINGS.md` and apply relevant lessons to this run. If a lesson conflicts with these instructions, the lesson wins (it is newer).
2. Invoke the `superpowers:using-git-worktrees` skill — all implementation happens in an isolated worktree.
3. If the task needs context you lack, fan out in parallel: `searcher` (codebase layout, existing patterns) and `researcher` (external docs, prior art).

## Phase 1 — Brainstorm (human input allowed)

1. Invoke the `superpowers:brainstorming` skill and follow it.
2. In parallel with clarifying questions, dispatch `researcher` (prior art, library options) and **three `architect` subagents, each seeded with a distinct lens** (e.g. simplest/MVP, most robust/scalable, alternative paradigm or library) so they explore non-overlapping directions. Each returns ONE approach with its trade-offs (strengths, costs, risks) — not a full file-level plan.
3. **Synthesize**: spawn a FRESH `architect` (clean context, fed only the three approach digests and the task statement) to compare and rank them and pick a recommendation, stating why it wins over the other two. Present all three + the recommendation in the design discussion → the human confirms or overrides.
4. Output: a design doc written to the project's spec location (default `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`), recording the chosen approach in full plus the two rejected alternatives with the reasons they lost — so Phase 2's GATE 1 "rejected alternatives" summary draws from it.

## Phase 2 — Approach review (max 5 iterations)

1. Spawn a FRESH `architect` (clean context — never the instance that helped write the design) with only the design doc and the task statement. Instruction: adversarial review — soundness, missed alternatives, risks, scope.
2. Issues found → revise the design → spawn another fresh architect. Count iterations.
3. Same issue unresolved after 2 iterations → escalation rules below. 5 iterations exhausted → halt with failure digest.
4. **GATE 1**: summary (chosen approach, rejected alternatives, remaining risks) → human approves or rejects.

## Phase 3 — Plan (human input allowed)

1. Invoke the `superpowers:writing-plans` skill.
2. Delegate plan drafting to an `architect` subagent with clean context, fed ONLY the approved design doc and task statement. The plan must have file-level steps, interface contracts, and per-step verification.

## Phase 4 — Plan review (max 5 iterations)

1. Spawn a fresh `reviewer` with the plan + approved design doc. Check: does every design decision map to plan steps, are steps independently verifiable, are interfaces precise, anything unplanned?
2. Issues → send digest back to a fresh `architect` for plan revision → re-review. Count iterations.
3. Different issue each iteration → the design is wrong: return to Phase 1 output with a failure digest (no full re-brainstorm; targeted design fix, then re-enter Phase 2).
4. **GATE 2**: summary (plan steps, deviations from approved design) → human approves or rejects.

## Phase 5 — Implement

1. Invoke the `superpowers:subagent-driven-development` skill.
2. Each plan task goes to a `coder` subagent with the relevant plan slice. Independent plan tasks run in parallel (use `superpowers:dispatching-parallel-agents`); dependent tasks run in order.
3. Coders delegate test execution to `test-runner` — raw test output never enters your context.
4. Loop guard per task: same test fails after 2 coder attempts, or fixes start touching unrelated files → escalate to `debugger` with a fresh context + failure digest.

## Phase 6 — Implementation review (max 5 iterations)

1. Spawn a fresh `reviewer` with the plan + instruction to review the worktree diff. Verdict PASS/FAIL with numbered issues.
2. FAIL → route numbered issues to `coder` → re-review. Count iterations.
3. Same issue rejected twice → escalate per ladder (coder → `debugger`; debugger → fable debugger). Different issue each iteration → the plan is wrong: back to Phase 3 with failure digest.
4. High-stakes diff (auth, payments, migrations, data deletion) → run the review on an escalated reviewer (opus/fable) from the first pass.
5. **GATE 3**: summary (files changed, test status, deviations from plan, escalations used) → human approves or rejects.
6. On approval: invoke `superpowers:finishing-a-development-branch` to merge/PR/clean up the worktree. If the outcome is a PR, run Phase 6.5 before Phase 7.

## Phase 6.5 — CI verification (PR path only, max 5 iterations)

Runs only when Phase 6 step 6 ended with a PR. Local merge, keep, or discard → skip to Phase 7.

1. Trunk health first: `gh run list --branch <default> --limit 3`. Trunk already red → the PR inherits that red; record it in the digest, don't chase it as a regression in your diff.
2. Wait for checks: `gh pr checks <pr> --watch --interval 30` (fallback: poll `gh pr checks <pr> --json name,state,bucket,link` every 60s). "No checks reported" right after creation → retry twice over ~1 min; still none → repo has no CI, skip to Phase 7.
3. Failures → send the failing run IDs to `test-runner` for a digest via `gh run view <run-id> --log-failed` — raw CI logs never enter your context. Infra-smelling failures (runner setup, network, quota) → one free `gh run rerun <run-id> --failed`; everything else costs an iteration.
4. Digest → `coder`: reproduce with CI's EXACT command first (see LEARNINGS), then fix. Fresh `reviewer` on the fix diff BEFORE pushing; FAIL → back to coder within the same iteration. Push the reviewed fix (re-triggers CI), count the iteration, return to step 2. Local green is a hypothesis — CI adjudicates.
5. Same check failing after 2 coder fixes → escalate per ladder (coder → `debugger`; debugger → fable debugger — draws on the same one-fable budget as Phase 6). Different failure each iteration → the implementation is wrong: back to Phase 6 with a failure digest.
6. All checks green → proceed to Phase 7, no gate. Cap or ladder exhausted → HALT: leave the PR open, present the failure digest (checks still red, what was tried, escalations used).

## Phase 7 — Retrospective + self-improvement

1. Write a retrospective to the project at `docs/superpowers/retros/YYYY-MM-DD-<task>.md`: what worked, what failed, iteration counts per phase, escalations used and whether they helped, gate rejections and why.
2. Distill durable lessons (things that would change how the NEXT run behaves) and propose a self-update:
   - Append distilled lessons to `~/.claude/new-task/LEARNINGS.md` (dated, one lesson per bullet).
   - Optionally: targeted edits to this command file (`~/.claude/commands/new-task.md`) or agent definitions in `~/.claude/agents/`.
3. **GATE 4**: show the proposed self-update as a diff → apply ONLY what the human approves. No approval → write nothing outside the project retro.
4. After any approved self-update (including LEARNINGS appends), version it: run `~/Prywatne/software-developer-workflows/capture.sh`, then commit the resulting diff in that repo with a one-line message describing the lesson. If the repo is missing, skip silently.

## Escalation ladder

Override models per invocation via the Agent tool `model` parameter. One rung at a time, fresh context + failure digest — never replay failed transcripts.

| Agent | Default | Escalate to | When |
|---|---|---|---|
| searcher | haiku | sonnet | empty/off-target results twice |
| researcher | sonnet | opus | contradictory sources, low-confidence twice |
| coder | sonnet | — | don't escalate model; route to debugger instead |
| reviewer | sonnet | opus → fable | same issue unresolved 2 iterations, or high-stakes diff |
| debugger | opus | fable | debugger reports unverified root cause |

Rules:
- Same error twice → escalate model one rung. Different error each time → the upstream artifact (design or plan) is wrong; go back one phase with a failure digest instead of escalating.
- Budget: `architect` runs on fable by frontmatter (its planning and review duties are its normal work) plus AT MOST ONE fable escalation per task run (fable debugger OR fable reviewer, not both). Ladder exhausted → STOP, full failure digest to the human.
- Phase 6.5 (CI) escalations ride the same ladder and the same fable budget — a fable debugger there is the run's one fable escalation. Budget already spent in Phase 6 → the CI ladder ends at opus.

## Token hygiene

- Never ingest raw subagent transcripts; all agents return capped structured summaries.
- Run independent subagents in parallel in a single message.
- Test execution always goes through `test-runner`.
- Failure digests are compact: what was tried, what failed, exact error — not transcripts.
