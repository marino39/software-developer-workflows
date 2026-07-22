---
description: Warm-start follow-up on a reviewed baseline — delta implement + delta review, retro deferred and batched. The fast lane for iterating after /new-task finished.
---

# Iterate: $ARGUMENTS

You are the orchestrator (run this on Opus at `xhigh` effort — Fable optional, at double the price per context token). `/iterate`
is the follow-up entry point for a change a prior `/new-task` already carried
through review: a **delta on a reviewed baseline**, not a cold task. It exists so
that tweaking, extending, or correcting just-finished work does not re-pay the full
lifecycle — no brainstorm, no plan-review, no from-scratch review fan-out, and no
per-tweak retrospective.

It reuses `commands/new-task.md` machinery verbatim — the **Review loop
conventions**, the **Escalation ladder**, the **effort defaults**, and the route
model. Read that file for those sections; this command only defines the warm-start
seam and the deferred retro. All substantive work goes to subagents; independent
subagents fan out in parallel in a single message.

**Delegation floor — a small delta is not an exemption.** You judge results,
route work, and talk to the human; you do only trivial work yourself, and
*trivial* means orchestration mechanics: manifest/worktree/git bookkeeping,
spawn prompts, gate summaries, the computed verdict. Everything else is
delegated **even when the delta is one line** — source edits to `coder`,
build/test execution to `test-runner`, code investigation to `searcher`,
external docs to `researcher`, review judgment to `reviewer`, plan writing to
`architect`. `/iterate` deltas are small by construction, so "small enough to
do inline" would waive delegation on exactly the runs this command exists for.
What the warm path trims is the **number** of subagents (one plan-lite
architect, sliced coders, one delta reviewer — no brainstorm, no plan-review,
no fan-out), never whether the work is delegated: inline substantive work
accretes in the most expensive context in the workflow and serializes what
subagents run in parallel, so it is slower AND costlier than dispatching.

## Human contract

Same four-section decidable gate format as `/new-task` (Results / Key decisions /
Deviations / Next — read there), **including its Gate rendering & follow-ups rule**:
GATE I is presented as a plain-text message whose body is the full summary and then
ends the turn — never collected via `AskUserQuestion` — and a human clarifying
question is answered in-band with the gate re-presented, never read as approve/reject.
`/iterate` has **one gate (GATE I)**, which may
auto-approve on fully-green criteria exactly like the fast path's GATE 3. An
auto-approved gate still emits the full summary, marked `auto-approved` — never
silent. A review loop that exhausts its cap halts with a failure digest, never a
silent pass.

**When `/iterate` is the wrong tool — bounce to `/new-task`:** if there is no
readable prior-run manifest, or the request is not a delta on that baseline (a new
subsystem, an unrelated area, or a greenfield feature), STOP and tell the human to
run `/new-task` instead. `/iterate` assumes an already-reviewed baseline; without
one there is nothing to delta against.

## Phase I0 — Warm setup

1. **Load the baseline.** Locate the prior run's manifest (default
   `docs/superpowers/runs/*-manifest.md`, newest matching the branch/topic; the
   human may name one). It records: final route, design-doc + plan + retro paths,
   `BASE_SHA`/`HEAD_SHA`, default branch, worktree path + branch, outcome
   (merged / PR #N / local-kept), behavioral-verification result, and the carried
   **open Should-fix** findings the prior run did not fix. Missing/unreadable, or
   the request is not a delta on this baseline → bounce to `/new-task` per the
   Human contract.
2. **Reuse the worktree warm.** If the manifest names a worktree and it still
   exists (`git worktree list`), reuse it. A **local-kept** baseline records no
   worktree path — its branch is the current checkout, so "reuse warm" means work
   in place on that branch. Otherwise invoke the `superpowers:using-git-worktrees`
   skill to recreate one from the manifest's branch (or `HEAD_SHA`). A merged
   baseline follows the merged-PR rule: branch off the current default, do not
   restack on merged history. Either way, apply the **artifact-hygiene** rule
   from `new-task.md` Phase 0 step 2: `docs/superpowers/` registered in the
   local `info/exclude`; manifests, design docs, and plans stay untracked and
   never enter a commit or the PR diff.
3. **Seed context — don't rediscover it.** The manifest's design doc, plan, and
   layout ARE your context — referenced by path (agents Read what they need),
   not bulk-Read into your own. Apply only the tag-matching learnings per Phase 0's
   rule (an applicable lesson that overrides these instructions is recorded as a
   Deviation citing its `src:`). Do **not** re-spawn `searcher`/`researcher` for
   anything the manifest already covers — dispatch them only for a genuine gap the
   delta opens. A genuine gap is still **dispatched**, in parallel when more than
   one agent is needed — this rule deletes covered legwork; it never relocates
   uncovered legwork into your own context as inline Grep/Read exploration.
4. **Inherit + re-check the route (monotonic).** The manifest's final route is the
   **floor** — `/iterate` may only escalate, never de-escalate. Re-check the
   planned delta against the high-stakes categories (auth, payments, migrations,
   data deletion) and the `DIFF_LINES ≥ 200` trigger from Phase 0. Any hit →
   escalate (high-stakes or at least standard), recorded as a Deviation, which
   voids GATE I auto-approval and forces the full review tier in Phase I2. A delta
   that is itself a full feature (≥200 lines *of new surface* or a high-stakes
   greenfield add) → bounce to `/new-task`. A delta that merely **documents or
   relies on a symbol absent from the baseline tree** (e.g. a doc-only diff naming
   an unimplemented API) is NOT a bounce — it lands as a carried Should-fix under
   the constraint (Phase I2 step 3), and the gate still decides on its merits.

## Phase I1 — Delta implement

1. **Plan-lite.** ONE `architect` writes the delta plan against the seeded baseline,
   in artifact mode (`artifact_path` = the plan location; it returns path +
   ≤200-word summary + step titles) — file-level steps, interface deltas, per-step
   verification. No design doc, no brainstorm fan-out, no separate plan-review
   phase (the adversarial check is Phase I2). Carried Should-fix findings relevant
   to this delta fold into the plan.
2. **Implement** per the `superpowers:subagent-driven-development` skill: each plan
   slice to a `coder`; independent slices in parallel
   (`superpowers:dispatching-parallel-agents`), dependent ones in order. Coders
   delegate test execution to `test-runner` — raw output never enters your context.
3. Bug-fix deltas: the coder proves the fix per the `verify-fix` skill before
   reporting done. Loop guard + `debugger` escalation exactly per the Escalation
   ladder in `new-task.md`.

## Phase I2 — Delta review (max 5 iterations)

Compute `BASE_SHA` = the manifest's `HEAD_SHA` (the baseline the prior run already
fan-out-reviewed), `HEAD_SHA = git rev-parse HEAD`, `DIFF_LINES` from
`git diff --shortstat`. You review **only what this iteration changed** — the
baseline is trusted because it already passed a full Phase 6.

1. **Route re-check backstop** (per Phase 6 step 0): re-run both triggers against
   the real delta diff; any escalation is monotonic, recorded as a Deviation, and
   forces the full tier below.
2. **Behavioral verification (before any review spend):** prove the delta behaves
   as specified — delegated to a `coder` (or `test-runner` when it is pure
   command-driving) exactly per `new-task.md` Phase 6 step 1, never driven by the
   orchestrator: `verify-feature` for feature deltas, `verify-fix` for bug fixes;
   exempt doc-only/dead-code (record `verification: exempt (<reason>)`). Failures
   route back to Phase I1 before review tokens are spent.
3. **Review — delta by construction.** Because the baseline was already fully
   fan-out-reviewed, the default is a single fresh `reviewer` over the iteration
   diff, seeded with the carried Should-fix list as a checklist and scanning newly
   changed lines for new large bugs only — this is exactly the **iterations-2+
   delta re-review** of the Review loop conventions, applied from iteration 1.
   **Exception:** if the route escalated to high-stakes (step 1, or Phase I0 step 4),
   run the FULL Phase 6 fan-out — Channel A + Channel C lens reviewers +
   consolidator + the default-refute skeptic pass — with the high-stakes tier
   escalations. Verdict is COMPUTED, never judged:
   **PASS ⇔ tests green AND zero Must-fix remain AND behavioral verification passed
   (or exempt).**
4. FAIL → route numbered Must-fix issues to `coder` (fix proven per `verify-fix`) →
   re-review per the Review loop conventions. Exit ⇔ the verdict computes PASS.
   Same issue rejected twice → Escalation ladder; different issue each iteration →
   the delta plan is wrong, back to Phase I1 with a failure digest. Cap exhausted →
   HALT with a failure digest at the gate.

## GATE I

Gate summary (four sections). **Auto-approve iff** the route was not escalated
above the manifest's floor AND tests are green AND zero Must-fix remain AND
behavioral verification passed (or exempt) AND zero scope deviations — emit the
summary marked `auto-approved`. Any criterion missed → normal human GATE I. Results
must carry: the inherited route + any escalation (with its trigger), the delta files
changed, test status, behavioral-verification result, review tier (delta vs full,
with why), and consolidated Must-fix/Should-fix counts.

On approval: run `new-task.md` Phase 6 step 9's **artifact-hygiene check** first
— no `docs/superpowers/` path tracked or in the outgoing diff — then invoke
`superpowers:finishing-a-development-branch` (or push to the
existing PR named in the manifest). If the outcome is or remains a PR, run CI
verification exactly per `new-task.md` **Phase 6.5** (event-driven wait, `ci-triage`
skill, same ladder + fable budget) before the retro step.

## Retro — deferred and batched

Do NOT run a full Phase 7 per iteration — that per-tweak retrospective tax is the
whole reason `/iterate` exists.

1. **Every iteration:** append a compact entry to the manifest's **iteration log** —
   what changed, iterations used per phase, escalations used and whether they
   helped, gate outcome — and update the manifest's `HEAD_SHA` to the new head
   (the manifest stays untracked — artifact hygiene).
   Carried Should-fix findings that this iteration resolved or newly opened are
   updated in place.
2. **At session end** (the human signals done, or `/iterate` is invoked with
   `--finish`, or a single iteration the human declares final): run `new-task.md`
   **Phase 7 ONCE** over the whole session — one retrospective covering all logged
   iterations, distilled durable lessons, the GATE 4 per-item decision table, and
   `capture.sh` versioning. Lessons are keyed to the batch, not to each tweak, so a
   five-tweak session produces one curated GATE 4, not five.

## Token hygiene

Same as `new-task.md`: never ingest raw subagent transcripts (capped structured
summaries only); pass artifacts by path, never inlined (coders get plan path +
step numbers; reviewers Read the plan themselves); never Read back a file you
just wrote; independent subagents in parallel in one message; test execution
always through `test-runner`; substantive work never done inline (the
Delegation floor above — small deltas included); failure digests are compact; the manifest's
iteration log keeps the binding state current, so history older than the last
gate is compaction-safe; never switch your own model or effort mid-run.
