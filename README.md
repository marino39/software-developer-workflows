# software-developer-workflows

Source of truth for the multi-agent Claude Code workflow: 7 subagents, 4 skills, the full-lifecycle `/new-task` command with its learnings memory, the `/iterate` warm-start follow-up command, the `/triage-issue` front door that turns an issue into a scoped plan, the `/review-pr` command that aims the review engine at a PR you didn't author, the `/address-review` command that acts on the review comments humans leave on a PR you authored, the cheap read-only `/explain` command, the schedulable `/workflow-maintenance` command, and the `/workflow-eval` measure-and-iterate harness.

Iterating on a change `/new-task` just finished takes the warm lane: `/new-task` leaves a **run manifest** (design/plan/retro paths, base/head SHAs, worktree, open Should-fix findings), and `/iterate` starts from it — no cold Phase 0, no brainstorm, no plan-review, a **delta** review instead of a fresh fan-out, and the retrospective **deferred and batched** so a burst of tweaks produces one Phase 7, not one per tweak. A delta that grows high-stakes or ≥200 lines escalates (monotonic route) or bounces back to `/new-task`.

The live copies run from `~/.claude/`; this repo versions them so improvements — hand edits here, or self-improvement edits made live by `/new-task` Phase 7 — are reviewed and tracked in git.

## Guide

A rendered reference guide lives under [`docs/guide/`](docs/guide/index.html) and is published at **https://marino39.github.io/software-developer-workflows/guide/**. Start on the [Overview](https://marino39.github.io/software-developer-workflows/guide/index.html), then dive into a command: [`/new-task`](https://marino39.github.io/software-developer-workflows/guide/new-task.html), [`/iterate`](https://marino39.github.io/software-developer-workflows/guide/iterate.html), [`/triage-issue`](https://marino39.github.io/software-developer-workflows/guide/triage-issue.html), [`/review-pr`](https://marino39.github.io/software-developer-workflows/guide/review-pr.html), and [`/address-review`](https://marino39.github.io/software-developer-workflows/guide/address-review.html).

## Layout

```
agents/              7 subagent definitions (architect, coder, debugger,
                     researcher, reviewer, searcher, test-runner)
commands/            /new-task (full lifecycle; scoped tasks take a fast path)
                     /iterate (warm-start follow-up on a reviewed baseline:
                     delta implement + delta review, retro deferred/batched)
                     /triage-issue (front door: classify, reproduce, root-cause
                     and scope an issue into a ready-to-run plan + triage manifest;
                     read-only, no implementation)
                     /explain (cheap, fast, read-only codebase Q&A: classify the
                     question into 7 cases, sweep with parallel haiku searchers,
                     synthesize a grounded cited answer inline)
                     /review-pr (read-only review of a PR you didn't author:
                     the Phase 6 engine decoupled — fan-out + consolidation +
                     skeptic; local report by default, opt-in --comment)
                     /address-review (act on inbound review comments on a PR
                     you authored: ingest unresolved threads, skeptic-check
                     each ask before coder spend, fix via the /iterate delta
                     lane, gate every reply behind a per-thread disposition
                     table)
                     /workflow-maintenance (capture sync, learnings curation,
                     trunk health — idempotent, safe to schedule)
                     /workflow-eval (lint + scored live run of /new-task against
                     frozen tasks, with ablation A/B — expensive, opt-in)
skills/              procedural skills promoted from learnings:
                     verify-fix, verify-feature, convention-scan, ci-triage
evals/               /workflow-eval inputs & outputs: rubric, one Go fixture,
                     frozen tasks, ablation variants, dated result scorecards
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
- **Measure before adding/cutting complexity:** run `/workflow-eval` to score the workflow. `--lint-only` runs the deterministic `evals/lint.sh` consistency check over the instruction files (run any time); a full run scores `/new-task` against the `evals/` fixture tasks and writes a dated scorecard, `--variant <name>` ablates a layer (e.g. the skeptic pass) for an A/B verdict on whether it earns its cost, and `--contracts` tests that each agent honors its declared Input/Output contract (agents are treated as tools with contracts; see `agents/*.md` and `evals/contracts/`). The live layers are expensive and opt-in — never auto-scheduled. See `evals/README.md`.
- **Enforced on every change:** `install.sh` installs a **pre-commit hook** that runs `evals/lint.sh` whenever a commit touches `commands/`, `agents/`, `skills/`, or `new-task/` (the learnings files), blocking on failure. The full modification protocol — lint always, live scorecard for behavior-affecting changes, ablation for adding/cutting a layer — is in `CLAUDE.md`.

`install.sh` never overwrites the live learnings files — they are curated runtime state owned by `/new-task` runs (general lessons in `LEARNINGS.md`, per-repo lessons in `learnings/<repo-key>.md`; each a dated bullet in the v2 format `- YYYY-MM-DD [tag][tag] lesson — src: <retro>` with lesson text ≤300 chars, rewritten in place at GATE 4, soft cap 30 per file). Phase 0 applies only the bullets whose **trigger tags** match the task (tag-scoped retrieval), and a lesson that overrides an instruction must cite its `src:` — lint Check 7 enforces the tag + `src:` on every bullet. `capture.sh` is how they get versioned. Consequence: bullets pruned here (e.g. after promotion into a skill) do NOT propagate to `~/.claude` — that drift is expected, and `/workflow-maintenance` check 2 flags live bullets duplicating a skill so the next GATE 4 can delete them.

Skills, agents, and commands are source-of-truth files: `install.sh` always overwrites the live copies.

## Design notes

Model assignment, escalation ladder, fable budget, and nested-delegation rationale are documented in the command file itself (`commands/new-task.md`). Originally designed in Cowork (2026-07); handoff decisions: one generic coder (language conventions live in CLAUDE.md), debugger is escalation-only, agents return capped structured summaries, orchestrator never ingests raw transcripts.

**Complexity budget:** `evals/complexity-ledger.md` records why each accreted construct exists (the concrete failure it prevents + its source). Constructs sourced to unverified intuition are the standing simplification backlog — each gets an ablation variant in `evals/variants/` and is cut if `/workflow-eval --variant` shows it doesn't earn its cost. The delta-review machinery shared by Phases 2/4/6 lives in one **Review loop conventions** section rather than being restated per phase. Adding new complexity requires a ledger row (enforced by lint Check 6); see `CLAUDE.md`.

Loop-placement revision (2026-07, after the Claude Code "Getting started with loops" article): Phase 6.5 waits on CI via events/background tasks instead of holding the orchestrator turn open; Phases 2/4/6 exit on deterministic criteria (numbered blocking issues, mapping-table completeness, tests-green + zero Must-fix) instead of reviewer gut verdicts; scoped tasks take a fast path where GATE 3 auto-approves on fully green criteria; multi-step procedures live in skills rather than learnings bullets.

Gate-decidability revision (2026-07): every gate must carry its decision evidence, not just an artifact reference — the scope gate states the route rationale, GATE 1 the adversarial-review outcome, GATE 2 the Phase 4 mapping table, and GATE 4 presents a per-item decision table (each proposed lesson/edit with its in-run evidence, behavioral delta, and modification-protocol status, approved per-row). The rubric's Gate-discipline dimension and `lint.sh` Check 4 score/enforce decidability, not just well-formedness.

Cost/quality revision (2026-07): architect defaults to opus with exactly two by-design fable slots (Phase 1 synthesizer, Phase 2 iteration-1 adversarial reviewer); Phases 2/4 iterations 2+ are delta reviews (prior issues as a checklist, scan only revised sections) matching Phase 6's light re-review; Phase 6 fan-out is risk-scaled (small non-high-stakes diffs get a reduced tier, codex timeout cut to ~5 min); Must-fix findings survive a default-refute skeptic pass before reaching coders (promoted from a 2026-07-03 learning); features get end-to-end behavioral verification via the new `verify-feature` skill before review, and PASS/auto-approve criteria include it.

Context-compaction revision (2026-07, from `docs/proposals/2026-07-20-orchestrator-context-compaction.md` — orchestrator contexts were hitting 200–400k on the most expensive model): the orchestrator defaults to **Opus** (Fable optional at 2× per context token); artifacts pass **by path, never inlined** — the architect gained `Write` and an artifact mode (writes the design doc/plan itself, returns path + ≤200-word summary), coders get plan path + step numbers, reviewers Read the plan themselves; the run manifest is now a **live run ledger updated at every gate**, so everything binding later phases survives compaction and gate boundaries are safe `/compact` moments. Session-level hygiene the workflow can't set for you: on API-key billing export `ENABLE_PROMPT_CACHING_1H=1` (human-gate waits under an hour re-enter cache-warm instead of re-paying full input price for the whole context), never switch the orchestrator's model or effort mid-run, and consider a `## Compact Instructions` section in `~/.claude/CLAUDE.md` ("preserve the run ledger path, route + escalations, artifact paths, open findings, current phase") so even *automatic* compaction keeps the workflow's binding state. Owed per the modification protocol: a live scorecard for the path-passing/artifact-mode changes and `--contracts --agent architect`; the proposal's measurement section (per-gate `/context`, cold-re-entry counts) gates the remaining structural items (post-GATE-3 tail hand-off, review-lead sub-orchestrator).
