# Re-tuning the workflow for Claude Opus 5 and Claude Fable 5.1

**Date:** 2026-09-07 · **Status:** M1–M4 applied same day; M5–M6 ablation-queued
**Sources:** Anthropic model-migration guidance for Claude Opus 5 and Claude Fable 5.1
(`claude-api` skill, `shared/model-migration.md` §§ *Migrating to Claude Opus 5*,
*Migrating to Claude Fable 5.1*, *Migrating to Claude Fable 5.1 from Claude Fable 5*;
`shared/prompt-caching.md` § Economics), plus `shared/prompt-audit.md` on dated
prompting patterns.

## Why this pass exists

The workflow's model assignments and prompt text were tuned against the previous
Opus generation. Two things changed underneath it:

1. **Opus 5 is the orchestrator's model, and several of its behavioral defaults
   inverted.** It delegates to subagents *more* readily than its predecessor (which
   under-delegated), it self-verifies without being asked, and prior-generation
   `effort` defaults do not transfer — `low`/`medium` are unusually strong and
   `xhigh`/`max` are described as "for measured wins, not a starting point."
2. **Fable 5.1's economics are not the flat 2× the command files assert**, and its
   prompting guidance actively contradicts Opus 5's on two axes (delegation and
   verification).

The single most important structural point: **this repo runs a heterogeneous fleet
under one set of prompts.** Commands are read by the Opus orchestrator; each
`agents/*.md` is read by whatever model that agent is pinned to (haiku, sonnet, opus)
and by whatever rung the escalation ladder overrides it to. Model-specific prompting
guidance therefore applies **per file, by the model that reads it** — not repo-wide.
Applying Opus 5's "delete your verification instructions" to `agents/coder.md`
(Sonnet) or to the Fable escalation rung would be a straight misapplication; the
Fable 5.1 guidance says the opposite in as many words ("the Claude Opus 5 guidance to
delete verification instructions doesn't apply here").

## Findings

### F1 — The delegation floor is now one-sided (Opus 5 inverted the default)

`commands/new-task.md:7` reads *"you only do trivial work yourself. All substantive
work goes to subagents"*, backed by the **Delegation floor** construct that was A/B'd
into the workflow on 2026-07-22 (user report + `2026-07-22-delegation-floor-ab`
scorecard).

Opus 5 guidance: *"Delegates to subagents more readily — the opposite of Opus 4.8.
This is a direction change worth flagging... any 'delegate more' guidance you added
for Opus 4.8 should come out, and you likely want an explicit cap."* Its recommended
block explicitly bars subagents for *"work you could finish yourself in a handful of
tool calls"* and for *"review, verification, or to double check your work."*

Two honest caveats against simply deleting the floor:

- The floor's evidence is **real and workflow-specific** — it was measured on this
  suite, against under-delegation in `/iterate` and the sibling seams. It also
  serves a second purpose the model guidance doesn't address: orchestrator **context
  hygiene** (the orchestrator's context is the most expensive one in the system, per
  the 2026-07-20 compaction proposal).
- That evidence **predates the model change**. A floor measured against a model that
  under-delegated is not evidence about a model that over-delegates.

So the floor stays, and the missing half gets added: an explicit **cap**. The floor
prevents substantive work being absorbed inline; the cap prevents trivial work being
fanned out. They bound the same quantity from opposite sides.

### F2 — `xhigh` on architect/debugger is a carried-over default

`agents/architect.md` and `agents/debugger.md` pin `effort: xhigh`. Opus 5 guidance:
*"Start at `high` (the API default), then sweep down... Effort defaults carried over
from a prior model are usually not the right setting here; run a fresh sweep,"* and
*"`xhigh` and `max` are for measured wins, not a starting point... it can show
diminishing returns and overthink simpler tasks."*

The repo already made exactly this move for the orchestrator on 2026-08-11 (P1,
`xhigh`→`high`) and left the two agents behind, with the ledger's own effort row
carrying the caveat that the setting is **inert in the eval harness** — so the
measurement that would justify `xhigh` cannot be produced by `/workflow-eval`, and
never has been. `xhigh` here is an unmeasured default that contradicts the vendor
default, on the two most expensive agents in the fleet.

Applied as `high` (the API default) with the restore variant authored. Validation is
owed in a **real CLI run**, not the harness.

### F3 — Fable's "doubles the price of every context token" is wrong for cached context

Four command headers assert Fable *"doubles the price of every context token."* On
fresh input that is exact (Fable 5.1 $10/MTok vs Opus 5 $5/MTok). On **cache reads it
inverts**: Fable 5.1 cache reads are $0.25/MTok — 0.025× its base input price, versus
the usual 0.1× — while Opus 5 cache reads run ~$0.50/MTok. Fable 5.1 cache reads are
therefore about **half** Opus 5's.

This matters specifically here because the orchestrator context is long-lived and
overwhelmingly cache-read-dominated (the 2026-07-20 context trace measured a ~27.4k
fixed first-turn floor re-read every turn). The blanket 2× framing overstates the
cost of the one seat where the workflow's own caching discipline is strongest. It is
a claim in the prompt text, so it is a correctness fix, not a behavior change.

Fable 5.1 also carries constraints the ladder should not trip over: **thinking blocks
are bound to the producing model** (a different model drops them from the prompt,
unbilled) and **editing earlier turns invalidates thinking blocks**. The ladder is
safe as written — subagent `model` overrides are separate contexts — but the
orchestrator's existing "never switch your own model mid-run" rule now has a second,
harder reason than cache invalidation, and should say so.

### F4 — Opus 5 cache floor drops to 512 tokens

The minimum cacheable prefix on Opus 5 is **512 tokens**, down from 1024. Short
dispatch prompts previously below the floor now cache with no code change. Relevant
to a workflow whose Token-hygiene section is built around caching; recorded as a note.

### F5 — Severity self-filtering depresses reviewer recall (partial; mostly already right)

Opus 5 guidance (carried from 4.7/4.8): *"Severity filters still depress measured
recall... Ask it to report everything with confidence and severity, and filter in a
separate pass."*

The workflow is **already structurally correct** — Phase 6 step 4 consolidates with
0–100 confidence scoring and drops <50 in a separate orchestrator-side pass. The gap
is in `agents/reviewer.md`, which asks the reviewer to self-suppress before reporting
(*"Don't nitpick style the linter would catch"*) and gives it no confidence field to
report with, so the consolidation pass scores findings it did not see graded. Fixed
by having the reviewer report what it finds with severity **and** confidence, and
leaving the filtering where it already lives.

### F6 — Verification scaffolding: genuinely contested, so ablation-gated

Opus 5: *"Claude Opus 5 verifies its own work without being asked. Instructions that
tell it to verify now cause over-verification. Removing them reduces over-verification
with no capability regression — this is a delete, not a rewrite,"* including
harness-level steps carried over from prior models, and explicitly *"do not use
subagents to verify."*

Against that, three reasons not to cut anything today:

- The workflow's verification layers (`verify-feature` before review spend, the
  `verify-fix` revert-discriminate proof, the batched skeptic) are **gate evidence for
  a human**, not self-check nudges to a model. Opus 5's finding is about a model
  redundantly re-checking itself, which is a different failure.
- Most of that scaffolding is read by **Sonnet** agents (`coder`, `reviewer`), not by
  Opus 5.
- **Fable 5.1 guidance says to keep verification instructions**, and the ladder can
  put a Fable model in those seats.

Per CLAUDE.md rule 3, cutting a layer needs an A/B. Variant authored
(`verify-scaffold-trim`), nothing cut.

### F7 — Prompt-tunable behaviors the workflow already handles

Recorded so a future pass doesn't re-derive them. Opus 5's named behavioral shifts —
verbosity, task-scope expansion, self-correction narration, inter-tool narration — are
already covered: the ≤25-line gate format and per-agent word caps bound verbosity; the
coder's `<ambiguity-policy>` and the Deviations section bound scope drift; capped
structured summaries bound narration. No change needed. The TTFT instruction
(*"begin your visible answer immediately"*) is deliberately **not** adopted: this is a
background/agentic workload, where the guidance says the pre-answer thinking is worth
keeping.

## Proposals

| # | Change | Status |
|---|---|---|
| **M1** | Add a **delegation cap** beside the existing floor in `new-task.md` (Token hygiene + the orchestrator role line): don't dispatch what finishes in a handful of tool calls; never spawn a subagent purely to double-check your own work; keep parallel spawn counts to genuinely independent tracks. Floor unchanged. | applied |
| **M2** | `architect`/`debugger` `effort: xhigh` → `high` (the API default), per Opus 5's "prior-model effort defaults rarely transfer." Variant `agent-effort-xhigh-restore`; validation owed in a real CLI run (effort is inert in-harness). | applied |
| **M3** | `agents/reviewer.md`: report every finding with severity **and** a 0–100 confidence, no pre-report severity suppression; filtering stays in the Phase 6 consolidation pass that already exists. Contract spec updated. | applied |
| **M4** | New **Model-tuning notes** section in `new-task.md`: per-model prompt divergence (Opus 5 vs Fable 5.1 disagree on delegation and verification), the Fable cache-read correction from F3, the model-bound-thinking reason for the no-mid-run-switch rule, and the 512-token Opus 5 cache floor. | applied |
| **M5** | Trim verification scaffolding per Opus 5's "delete, not rewrite." | **ablation-queued** — variant `verify-scaffold-trim`; contested by Fable guidance (F6) |
| **M6** | Re-A/B the delegation floor itself under Opus 5 — its 2026-07-22 evidence predates the model whose default it corrects. | **ablation-queued** — reuses `delegation-floor-off` |

## What is owed

- M2 cannot be validated by `/workflow-eval` (effort is inert in the harness). Its
  evidence must come from a real CLI run comparing wall-clock, token spend, and
  escaped defects on the same tasks.
- M5 and M6 are the standing backlog rows. M6 is the sharper of the two: the
  delegation floor is the workflow's most explicitly evidence-backed construct, and
  that evidence is now one model generation stale in the direction that matters.
