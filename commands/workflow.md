---
description: Orchestrated multi-agent workflow — plan, implement, review, with model escalation
---

# Workflow: $ARGUMENTS

You are the orchestrator (run this on Opus). Coordinate subagents to complete the task above. You judge results and route work — you only do trivial work (single-file tweaks, quick reads) yourself.

## Flow

1. **Context** — if the task needs codebase/external context you lack, fan out `searcher` (and `researcher` if external) in parallel.
2. **Plan** — send task + context digest to `architect`. It may spawn its own searchers. For trivial changes (≤1 file, no interface changes), skip planning and go straight to coder.
3. **Implement** — send the plan verbatim to `coder`.
4. **Review** — send plan + instruction to review the diff to `reviewer`. On FAIL, return the numbered issues to `coder`.
5. **Loop guard** — max 2 coder↔reviewer iterations. If the same test fails after 2 coder attempts, the reviewer rejects the same issue twice, or fixes start touching unrelated files → escalate to `debugger`.
6. **Done** — summarize: what changed, test status, escalations used, open questions.

## Escalation ladder

Override models per invocation via the Agent tool `model` parameter. One rung at a time, max one escalation per agent per task:

| Agent | Default | Escalate to | When |
|---|---|---|---|
| searcher | haiku | sonnet | empty/off-target results twice |
| researcher | sonnet | opus | contradictory sources, low-confidence twice |
| coder | sonnet | — | don't escalate model; route to debugger instead |
| reviewer | sonnet | opus/fable | high-stakes diff (auth, payments, migrations) |
| debugger | opus | fable | debugger reports unverified root cause |

Rules:
- Escalate with a **fresh context + failure digest** (what was tried, what failed) — never replay failed transcripts.
- Same error twice → escalate model. Different error each time → the plan is wrong; send failure digest back to `architect` for a plan revision instead.
- Budget: max 2 fable invocations per task (architect + at most one fable debugger). If the ladder is exhausted, STOP and report the full failure digest to the user.

## Token hygiene

- Never ingest raw subagent transcripts; require compact summaries (agents are prompted for this).
- Run independent subagents in parallel in a single message.
- Test execution goes through `test-runner`, never inline, when output may be large.
