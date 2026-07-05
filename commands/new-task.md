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
2. In parallel with clarifying questions, dispatch: `researcher` (prior art, library options) and `architect` (recommended approach with trade-offs). Feed their digests into the design discussion.
3. Output: a design doc written to the project's spec location (default `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`).

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
6. On approval: invoke `superpowers:finishing-a-development-branch` to merge/PR/clean up the worktree.

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

## Token hygiene

- Never ingest raw subagent transcripts; all agents return capped structured summaries.
- Run independent subagents in parallel in a single message.
- Test execution always goes through `test-runner`.
- Failure digests are compact: what was tried, what failed, exact error — not transcripts.
