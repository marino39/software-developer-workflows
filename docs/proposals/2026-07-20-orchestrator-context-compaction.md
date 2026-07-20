# Research: orchestrator context compaction

Date: 2026-07-20. Status: research only — nothing here is implemented. Stated
ledger-style where a change would owe protocol cost (per `CLAUDE.md`), so a
follow-up can pick an item and go straight to `/new-task`.

## Problem

The `/new-task` (and `/iterate`) orchestrator runs on the most expensive seat in
the workflow — Opus or Fable at `xhigh` — and its conversation context regularly
reaches ~200k tokens, peaking ~400k. Every orchestrator turn re-sends that
entire context. With prompt caching, cached tokens re-read at ~0.1× input price
and each turn's new content is written once at 1.25×; **but any gap longer than
the cache TTL re-pays the full input price for the whole context**. The
workflow's own design maximizes exactly those gaps: every gate ends the turn and
waits for a human, and Phase 6.5 ends the turn and waits for CI webhooks. On
Fable ($10/MTok input) a single cold re-entry at 400k context is ~$4 of input
before the model does anything; at four gates plus a handful of CI wakes, the
cold re-reads alone can dominate the run's cost. Context size is therefore a
*multiplier* on the workflow's most structurally unavoidable events, not just a
per-turn tax.

Secondary costs of a fat context: long-context quality degradation in the
judge/router role (the one role we pay top tier for), and exposure to the
harness's automatic compaction at unpredictable moments instead of at safe
phase boundaries.

## Where the tokens actually go (token-flow map)

Walking `commands/new-task.md` phase by phase, orchestrator context grows from
six mechanisms:

1. **Fixed resident overhead.** The command file itself (~32KB ≈ 8–9k tokens),
   CLAUDE.md, the tag-matching learnings bullets, and — the quiet one — every
   `superpowers:*` skill invoked inline (`using-git-worktrees`, `brainstorming`,
   `writing-plans`, `subagent-driven-development`,
   `dispatching-parallel-agents`, `requesting-code-review`,
   `finishing-a-development-branch`). Each Skill invocation loads its full text
   into the session, and by Phase 6 most of the catalog is resident for the rest
   of the run. Estimate 25–45k tokens of permanent floor before any work happens.

2. **Artifacts transiting the orchestrator multiple times.** The design doc and
   plan each pass through orchestrator context repeatedly:
   - Phase 1: three architect approach digests **in** → synthesizer ranking
     **in** → orchestrator `Write`s the full design doc **out** (the entire
     document passes through context as tool input).
   - Phase 3: architect returns the full plan inline (the `architect` Output
     contract is the **only agent contract with no word cap**) → orchestrator
     `Write`s it to the spec location → Phase 5 excerpts plan slices into every
     coder spawn prompt → Phase 6 references it again for Channel A and the
     consolidator.
   A 4k-token plan crossing context five times is 20k tokens — and every one of
   those copies is then re-read (cached or cold) on **every subsequent turn**
   for the rest of the run. Phase 7 repeats the pattern: the orchestrator
   `Write`s the full retro and manifest.

3. **Fan-out round trips.** Phase 6 full tier, iteration 1: behavioral
   verification report + Channel A report + codex digest + 3 lens reviewer
   reports + consolidated list + one skeptic report per Must-fix. Each is capped
   (≤300 words ≈ 400 tokens), so a single fan-out is only ~3–5k tokens of
   results — but the orchestrator also *composes* each spawn prompt, and channel
   reports transit twice (in from channels, back out to the consolidator's spawn
   prompt). Phases 1/2/4 add their own round trips. Individually small;
   collectively, with prompts, ~10–20k per review cycle.

4. **The orchestrator's own tool calls.** git commands, `Read`s of manifests /
   learnings / design docs, `Write`s of gate summaries and artifacts. Each tool
   result is context that never leaves.

5. **Iteration loops.** Each re-review iteration re-feeds the prior findings as
   a checklist and returns a new report. The delta-re-review convention already
   bounds this well (it exists precisely to prevent re-review token blowup — see
   the ledger row), but iterations still only ever add.

6. **Nothing is ever dropped.** The workflow has no phase-boundary discard
   point: Phase 1's three rejected-approach digests are still in context during
   Phase 6.5 CI triage, months of learnings bullets ride along after Phase 0 has
   extracted what applies, and every gate summary persists after the human
   approved it.

The 400k peaks are the compound case: a standard/high-stakes route with review
iterations, a PR outcome, and a Phase 6.5 loop — i.e. the runs with the most
post-gate wakes, which is also when cold re-reads are at their most expensive.

## Cost model (why gates and CI waits dominate)

Per-turn orchestrator input cost ≈ `context_size × price × (0.1 if cache-warm
else 1.0)`. Two consequences:

- **Warm turns:** halving average context halves the steady-state input cost.
  At Fable prices, a 60-turn run averaging 200k context ≈ $12 in cache reads;
  averaging 100k ≈ $6.
- **Cold turns:** every human-gate approval that takes longer than the cache TTL
  (5 min on API keys by default; 1 h on subscription or with
  `ENABLE_PROMPT_CACHING_1H=1`) and every CI wake after a >TTL build re-pays
  `context_size × full price`. Human gates routinely exceed 5 minutes and CI
  waits routinely exceed an hour. Four gates + three CI wakes at 300k average ≈
  7 × 300k × $10/M ≈ **$21 of pure re-warm** on Fable — more than all the
  subagent work in a typical run (the eval scorecards measured whole warm
  `/iterate` runs at ~68k subagent tokens).

So the highest-value tokens to eliminate are the ones that **survive across
gates and waits** — which is nearly all of them, since nothing is dropped. That
reframes the goal: not "make each phase cheaper" but "make the context that
crosses a gate boundary small".

## Platform facts (what the harness gives us)

Grounded against current Claude Code and API documentation (verified 2026-07-20):

- **Subagent isolation already works for us.** Subagent transcripts never enter
  the parent context; only the final text report (plus a small token-count
  trailer) does. There is **no parent-side mechanism to cap a subagent's
  report** — the per-agent word caps in `agents/*.md` output contracts are the
  only enforcement, which is why the gap matters that they don't cover the
  *architect* (uncapped) or the orchestrator's own artifact writes.
- **Auto-compaction** fires when the session approaches the context limit — no
  published threshold, no setting to disable it. It clears older tool outputs
  first, then summarizes the conversation. It is lossy and fires at an
  arbitrary point mid-phase — unless the run's binding state lives in files, an
  auto-compact can silently drop decision context (open Should-fix list,
  deviation history). Two steering mechanisms exist: `/compact [focus]` run
  deliberately by the human, and a **`## Compact Instructions` section in
  CLAUDE.md** that steers what *any* compaction (including automatic) preserves.
  The orchestrator cannot invoke compaction on itself mid-run, so the design
  goal is compaction that is *safe whenever it happens*, not *scheduled*.
- **`/context` and `/usage`** give the measurement surface: `/context` breaks
  the window down (system prompt, MCP tool definitions, skill descriptions,
  CLAUDE.md files, conversation, recent tool outputs); `/usage` reports input /
  output / cache-read / cache-write tokens with per-model and per-subagent
  attribution.
- **Prompt caching is automatic and prefix-matched.** Reads ~0.1× input price,
  writes 1.25× (5-min TTL) or 2× (1-h TTL). TTL is 5 minutes by default on API
  keys (1 hour by default on Claude subscriptions; API-key sessions can opt in
  with `ENABLE_PROMPT_CACHING_1H=1`). Cache breakers to avoid mid-run: model
  switch, effort change, MCP server or plugin toggles. Compaction invalidates
  the conversation layer but reuses the system-prompt prefix — another reason
  `/compact` beats `/clear`.
- **Skills load lazily but stay resident once invoked.** Only descriptions load
  at startup; a Skill invocation loads the full text into the session for the
  rest of the run. This confirms mechanism 1's floor: each `superpowers:*`
  invocation is a permanent context add.
- **No context-editing surface inside Claude Code.** The API's
  `context_management` edits (tool-result clearing, server-side compaction
  blocks) apply to SDK-driven orchestrators only; inside Claude Code the
  harness owns transcript editing, so the workflow's lever is *what it puts in
  context*, not API flags.

One calibration note: if the session's window is 200k-class, the observed 400k
readings mean auto-compaction has already been firing mid-run — i.e. the
workflow is *already* being lossily compacted at uncontrolled moments, which
makes the compaction-safety work (S4/S5) a correctness fix, not just a cost fix.

## Strategies, ranked

### Tier 1 — hygiene extensions, no new constructs (lint + one eval run)

**S0. Session-level cache hygiene (configuration, not workflow edits).** Before
touching any instruction file: (a) on API-key billing, set
`ENABLE_PROMPT_CACHING_1H=1` so human-gate waits under an hour re-enter warm —
the 2× write premium is repaid after two reads, and a gate-heavy workflow reads
many times; (b) never switch the orchestrator's model or effort mid-run (each
switch invalidates the whole cache — the escalation ladder already confines
model overrides to subagent spawns, which are separate contexts); (c) avoid
MCP/plugin toggles mid-run. Zero protocol cost; immediately shrinks the
cold-re-entry bill that the Cost model section prices.

**S1. Pass paths, not payloads.** Extend the Token hygiene section from output
discipline ("agents return capped structured summaries") to input discipline:
*spawn prompts reference artifacts by path + slice identifier; they never inline
artifact text that exists on disk.* Every agent that consumes a design doc or
plan has `Read` — coders get "implement steps 3–5 of `docs/…/plan.md`",
reviewers get the plan path, the Phase 2 adversarial architect gets the design
doc path. This eliminates most of mechanism 2's repeat transits. (Phase 0
searcher/researcher digests stay inline — they're small and have no file home.)
- **Prevents:** the same multi-k-token artifact crossing orchestrator context
  3–5×, then being re-read every turn thereafter.
- **Owes:** behavior-affecting edit to `commands/new-task.md` → live eval
  scorecard. No ledger row (removes tokens, adds no construct).

**S2. Close the architect cap gap — the architect writes its own artifacts.**
The architect is the only agent whose Output contract has no word cap, and its
outputs (design doc, plan) are the largest artifacts in the run. Give
`architect` the `Write` tool (scoped by instruction to the project's
`docs/superpowers/**` spec/plan locations), change its Output contract to
`artifact_path` + a ≤200-word summary + the step list, and delete the
orchestrator's `Write` of design/plan. The full text then never enters
orchestrator context at all: architect writes it, reviewers/coders `Read` it.
- **Prevents:** uncapped multi-k inline plans + the orchestrator re-emitting
  the same bytes through `Write`.
- **Owes:** agent contract change → update `evals/contracts/architect.md` in the
  same diff + `/workflow-eval --contracts --agent architect`; behavior-affecting
  → scorecard. Tool-grant is a real risk-surface change (a plans-only agent
  gains write access) — constrain in the agent definition and note it in the
  contract's Role line.

**S3. Never re-read your own writes; write-through summaries only.** Two
micro-rules for the orchestrator: (a) after any `Write`, refer to the artifact
by path — never `Read` it back; (b) gate summaries are composed once, in the
gate message, not drafted in tool calls first. Zero-cost instruction edits that
close the remaining self-inflicted transits (mechanism 4).

### Tier 2 — make compaction safe, then exploit it

**S4. Promote the run manifest to a live run ledger, updated at every gate.**
Today the manifest is written once, at Phase 6 step 10. Move to incremental:
create it at the scope gate / GATE 1 and append at each subsequent gate the
binding state — route + escalations, artifact paths, applied learnings,
deviations to date, open findings, current phase. This is additive (the
`/iterate` iteration log already does exactly this pattern post-run) and it
changes no gate decision.
- **Prevents:** an auto-compaction mid-run (or a session crash) silently
  discarding binding state that existed only in conversation history; also
  makes `/iterate`-style warm re-entry possible from *any* gate, not just after
  Phase 6.
- **Owes:** behavior-affecting → scorecard. Arguably a ledger row (it
  generalizes the existing manifest construct rather than adding one — the
  existing `/iterate` row can absorb it with a note).

**S5. Declare the disposal rule, so compaction is harmless by construction.**
With S4 in place, two edits:
- One Token-hygiene sentence: *everything that binds future phases lives in
  artifacts (design doc, plan, run ledger, retro); conversation history older
  than the last approved gate is reconstructible and disposable.*
- A **`## Compact Instructions` section in CLAUDE.md** (the harness reads it
  for both `/compact` and automatic compaction): *preserve the run ledger path,
  final route + escalations, artifact paths, the open Must-fix/Should-fix list,
  and the current phase + iteration count; drop file contents and superseded
  review reports.* This is the only channel that steers *auto*-compaction,
  which today fires unsteered at 200k-class limits.

Together these make both auto-compact and a human-issued
`/compact focus on the run ledger and open findings` safe at gate boundaries —
the natural ritual becomes "approve the gate, then compact", and the command
file can say so in the gate's **Next** section for long runs. No mechanism lets
the orchestrator compact itself mid-session; safety + opportunism is the
achievable design.

**S6. Treat the post-GATE-3 tail as a separate, cheap context.** The 400k peaks
and the coldest re-reads both live in Phase 6.5: each CI wake re-enters the full
run history even though the loop needs only the manifest (PR #, branch,
verification result, plan path) and the `ci-triage` skill. Once S4/S5 hold,
everything Phase 6.5 needs is in the run ledger — so the guidance can be: after
GATE 3 approval + manifest write, the session may be compacted hard (or the CI
babysit handed to a fresh session seeded from the manifest, exactly like
`/iterate` warm-starts). Phase 7's GATE 4 evidence comes from the retro file and
ledger, not from live memory of Phases 1–5.
- **Prevents:** paying `full_context × full price` per CI wake for context the
  loop never consults.
- **Owes:** if implemented as a *separate command/session hand-off*, that is a
  new seam → ledger row + eval task. If implemented as "compact after GATE 3"
  guidance only, it rides S5.

### Tier 3 — structural, ablation-gated (real ledger rows)

**S7. Review-lead sub-orchestrator for the Phase 6 fan-out.** One agent (opus
default) runs Channel A/B/C + consolidation + skeptics inside its own context
and returns only the computed verdict, the surviving numbered list, and
per-channel finding counts (the GATE 3 decision evidence). Nested delegation has
precedent (architect → searcher; coder → test-runner), and it removes ~10–20k
tokens and a dozen round trips per review cycle from the expensive context.
Costs: a new agent + contract, weaker direct oversight of the engine the
workflow trusts most, and interaction with the reduced tier (where the
orchestrator deliberately consolidates directly). **Do not build without an
A/B** — the fan-out's inline cost is capped-report-sized, so this only pays if
measurement (below) shows Phase 6 round trips are a top-3 contributor.
- **Owes:** ledger row + `--variant` ablation + contract spec + scorecard.

**S8. Orchestrator model choice: Opus by default, Fable only when warranted.**
The command permits "Opus or Fable" for the orchestrator. Every context token
costs 2× on Fable vs Opus ($10 vs $5/MTok), and the workflow's own escalation
design already reserves Fable for two by-design slots plus one budgeted
escalation — the orchestrator's judge/route role was designed to not need it.
If the 200–400k contexts are being carried on Fable, the single cheapest change
is recommending Opus as the orchestrator default in the command header. Not a
compaction strategy, but it directly answers "minimize token usage *for the most
expensive model*": the same context at half price, no behavior change to
evaluate beyond a scorecard sanity run.

### Non-strategies (considered, rejected)

- **Trimming the capped subagent reports further** — they are already the small
  part; squeezing 300→150 words risks the decision evidence gates depend on.
- **Skipping skill invocations** — the loop-placement revision deliberately
  moved procedures *into* skills; their token cost is the price of always-in-
  force procedure. Consolidating overlapping skills is a maintenance question,
  not a compaction one.
- **API context-editing flags** — not reachable from inside Claude Code; the
  harness owns transcript editing.

## Measure first (this repo's own rule)

Evidence over intuition applies to cost exactly as to quality. Before Tier 2/3
work, instrument:

1. **Add an orchestrator-context column to `/workflow-eval` scorecards**:
   context high-water mark and per-gate context size (from `/context` snapshots
   or OTEL metrics), alongside the existing subagent-token counts. The
   Efficiency rubric dimension (15%) already scores "token/wall-clock in the
   expected band" — give it real per-phase numbers.
2. **One instrumented live run** of a standard-route task, snapshotting
   `/context` at each gate, to attribute the 200k between fixed overhead
   (mechanism 1), artifact transits (2), fan-out (3), and turn accumulation
   (4–6). That attribution decides whether S7 is worth an ablation at all and
   sizes the S1/S2 win before the eval run.
3. **Track cold re-entries**: `/usage` reports cache-read vs cache-write vs
   uncached input per model; a gate approval or CI wake that lands as full-price
   input rather than cache reads is a cold re-entry. Counting them prices the
   S0/S5/S6 win directly.

## Suggested order

1. **S0** — cache TTL + model/effort stability. Pure configuration, no eval
   owed; shrinks the cold-re-entry bill today.
2. **S1 + S2 + S3** — path-passing, architect writes artifacts, no re-reads.
   Largest guaranteed context reduction, no new constructs. One eval scorecard
   covers all three; S2 additionally updates `evals/contracts/architect.md`.
3. **S8** — orchestrator default Opus. One-line change, halves the price of
   whatever context remains when the user was on Fable.
4. **Measurement (items 1–3 above)** — lands the telemetry the later ablations
   need; near-zero complexity cost.
5. **S4 + S5** — incremental run ledger + disposal rule + Compact Instructions;
   makes compaction (auto or manual) safe and gate-boundary `/compact` a
   documented ritual. If sessions are hitting a 200k-class window, this is a
   correctness fix, not just cost.
6. **S6** — post-GATE-3 tail isolation, guidance-first; promote to a session
   hand-off seam only if the cold-re-entry telemetry says CI wakes dominate.
7. **S7** — review-lead sub-orchestrator, only if measurement implicates the
   Phase 6 round trips; full ablation A/B per the modification protocol.
