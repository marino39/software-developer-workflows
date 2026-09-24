# Workflow leanness — verification of the cost-tiering handoff — 2026-09-20

**Trigger:** user directive — "I need our workflows lean and clean", attached to a
handoff document proposing model tiering (Opus planning / Sonnet orchestrator /
Haiku explorers), compressed subagent returns, cache-prefix stability, and a draft
replacement `commands/new-task.md`.

This document does three things: **verifies** the handoff's factual claims against
the shipped Claude Code model catalog; **audits** its recommendations against what
this repo already does; and **re-derives the cost model** from this repo's own
measured context trace so the remaining levers are ranked by evidence rather than
by intuition.

Short version: the handoff is a reasonable generic cost-tiering playbook, it is
**already implemented here in a more evidence-backed form**, two of its numbers are
stale, and three of its recommendations would be **regressions** against decisions
this repo made on measurement. The genuinely open lever is one the handoff does not
mention: **orchestrator turn count**.

---

## 1. Verified facts (source: shipped CLI model catalog)

All figures below are read from the hand-maintained model catalog baked into the
installed `claude` binary (`pricing_tiers` + per-model `capabilities`), not from
recall. USD per megatoken.

| Model | Alias | Input | Output | Cache read | Cache write 5m | Cache write 1h |
|---|---|---|---|---|---|---|
| Haiku 4.5 | `haiku` | 1 | 5 | 0.10 | 1.25 | 2 |
| Sonnet 5 | `sonnet` | 2 | 10 | 0.20 | 2.50 | 4 |
| Opus 5 | `opus` | 5 | 25 | 0.50 | 6.25 | 10 |
| Fable 5.1 | `fable` | 10 | 50 | **0.25** | 12.50 | 20 |

Derived, and load-bearing below:

- **Cache read is uniformly 0.1× input; 5m cache write 1.25× input; 1h cache write
  2× input.** The handoff's "reads ~10%, writes ~125%" is **correct** (for the 5m TTL).
- **Fable 5.1's cache read ($0.25) is half Opus 5's ($0.50)** — the one place the
  most expensive model is the cheaper one. Confirms the existing **Model-tuning
  notes** claim; that claim was previously asserted, now it is sourced.
- **Effort capability is not universal.** `claude-haiku-4-5` lists
  `capabilities:["context_management"]` — **no `effort`**. Opus 5, Sonnet 5 and
  Fable 5.1 all carry `effort` + `xhigh_effort` and `default_effort:"high"`.
- Valid subagent model aliases are exactly `sonnet` `opus` `haiku` `fable`, so the
  escalation ladder's `fable` rung is valid. `opusplan` is a **session** model
  setting, not a subagent one.

---

## 2. Handoff audit

### 2.1 Stale or wrong

| Claim | Verdict |
|---|---|
| Haiku gives "bulk input tokens at a fraction of Sonnet's price" | **Overstated.** Haiku 4.5 is exactly **2×** cheaper than Sonnet 5 ($1 vs $2 in). The claim was true against Sonnet 4.6 ($3 in, a 3× gap); Sonnet 5's price cut halved the advantage. Haiku still wins on mechanical work, by less than advertised. |
| "Match reasoning effort to role — low effort for Haiku explorers" | **Not implementable.** Haiku 4.5 exposes no effort control at all. This repo had already written `effort: low` into both haiku agents and documented a cost rationale for it — that rationale was false. Corrected in this change; see §4. |
| "Opus-everywhere → tiered often cuts spend 3–5×" | **Not supported by current prices.** The full Opus→Sonnet orchestrator move is 2.5×; Sonnet→Haiku is 2×. 3–5× is only reachable by *also* cutting dispatches and turns — which is where this repo's savings actually came from (17+K dispatches → 10 on 2026-08-11), not from tiering. |

### 2.2 Already implemented here, usually better

- **Model tiering by role** — the escalation ladder (`new-task.md` § Escalation
  ladder) already pins every seat and defines *when* each may escalate, with a
  one-fable-per-run budget. The handoff's static table has no budget and no ladder.
- **Compress subagent returns (≤300 tokens)** — every agent caps at ~200–400 **words**
  and declares an `## Output contract`, enforced by `evals/lint.sh` Check 6 and
  testable via `/workflow-eval --contracts`. Strictly stronger than a prose request.
- **Escalate by trigger, not default** — the ladder's "same error twice" rule, plus
  the distinction the handoff lacks: *different* error each time means the upstream
  artifact is wrong, so go back a phase rather than escalate a model.
- **Fresh session per task with lessons loaded** — Phase 0 does **tag-scoped**
  retrieval (subject vs activity tags), not the handoff's "read LESSONS.md in full".
  Reading a growing lessons file in full on every run is the cost bug the tag scoping
  exists to prevent.
- **Cache-prefix stability** — `new-task.md` § Token hygiene, Session hygiene bullet.

### 2.3 Would be regressions

1. **`model: opusplan` in the command header.** `opusplan` switches Opus→Sonnet at
   the plan/execute boundary, which is a **mid-session model switch** — it
   invalidates the prompt cache for the whole context, and the next turn re-pays
   full input price for all of it. This **directly contradicts the handoff's own
   cost-hygiene rule #2** ("don't switch models mid-session") and this repo's
   Session hygiene rule. On a 60k-token context that is one 60k re-read at $5/MTok
   ≈ $0.30, plus, on Fable-tier models, silently dropped thinking blocks.
2. **Sonnet orchestrator.** Priced in §3: it saves roughly $0.4–0.6 per run on input, on the one
   seat that does routing, gate decisions, consolidation and human contact. This
   repo already tested the adjacent question and moved the *other* way (Opus
   orchestrator, deep reasoning delegated). The handoff asserts the saving without
   pricing the seat.
3. **Replacing `commands/new-task.md` with the draft.** The draft is a ~50-line
   command targeting a stack (webrpc/pgx/squirrel/goose) and an agent set
   (`webrpc-specialist`, `db-specialist`, `code-reviewer`, `security-auditor`,
   `test-writer`) that **do not exist in this repo** — the real set is `architect`,
   `coder`, `debugger`, `researcher`, `reviewer`, `searcher`, `test-runner`. It also
   drops the gate-decidability contract, the iteration caps, the route monotonicity,
   the agent contracts and the complexity ledger — every one of which is a lint-
   enforced invariant with a dated failure behind it. Adopting it would fail
   `evals/lint.sh` on the first commit.

**Its two open decisions, answered from the repo:**
- *Escalation trigger count* — the handoff's "3 failed iterations" does conflict with
  an existing source of truth. The ladder escalates on **the same error twice**, and
  review loops cap at **3 iterations** (P5, 2026-08-11). Those are different
  mechanisms; the handoff collapses them. Keep the existing pair.
- *Worktree merge step* — already covered: worktrees are handled by the
  `superpowers:using-git-worktrees` skill with the artifact-anchor discipline in
  Phase 0 step 2.

---

## 3. Where the money actually goes (re-derived from this repo's trace)

> **Corrected 2026-09-24.** The first version of this table used the 2026-07-20
> turn counts (71 / 57 / 95). Those came from `evals/context-trace.sh`, which counted
> one turn per *content block* instead of per API response — ~2.6–3.1× too many — so
> every dollar figure here was inflated by roughly 3×. The script is fixed; the table
> below is recounted from the 2026-09-20 transcripts (responses), which are
> confounded by missing delegation but correctly counted.

Orchestrator **input** bill, taking the warm-session approximation that the bulk of
each turn's context is a cache read:

| Task | Turns (responses) | Mean ctx | Read volume | on Opus 5 | on Fable 5.1 | on Sonnet 5 |
|---|---|---|---|---|---|---|
| 01 doc-only | 16 | 80,685 | 1.29 MTok | **$0.65** | $0.32 | $0.26 |
| 02 bugfix | 20 | 87,120 | 1.74 MTok | **$0.87** | $0.44 | $0.35 |
| 03 route-correct | 21 | 91,327 | 1.92 MTok | **$0.96** | $0.48 | $0.38 |

Orchestrator **output** is a co-dominant term the trace does not capture: at a
nominal 1k tokens/turn, 16–21 turns on Opus is ~$0.40–0.53 — the same order as the
input bill. Output is what `effort` and verbosity actually move.

Three conclusions, in order of size:

**L1 — Turn count is the dominant multiplier, and nothing bounds it.** Every lever
in the table is multiplied by turns. A doc-only task on a toy Go fixture took 16
API responses, the route-correctness task 21 — and the turns this item originally
quoted (71, 95) were content-block counts from a since-fixed script, which is itself
a sign nobody had been looking at turns. The workflow caps *review iterations*
(3) and *escalations* (1 fable) but has no notion of a turn budget at all. This is
the lever the handoff never mentions and the repo has never attacked — every prior
cost pass cut **dispatches** (17+K → 10), which is a different quantity.

**L2 — Orchestrator output per turn.** The 2026-08-11 P1 change (`xhigh` → `high`)
targets exactly this and is *still* carrying an explicit OWED: effort is inert in the
eval harness, so it has never been validated in a real CLI run. Per §1, `high` is
also the model's own `default_effort`, so P1 was a move **to** the default, not away
from it — lower risk than the ledger implies, and cheap to validate.

**L3 — Prompt bytes, and they are cheaper than they look.** Measured 2026-09-20: when
the driver's Read of `commands/new-task.md` lands, context jumps **~22.6k tokens**
(the Read result carries line-number prefixes), and it is re-read every turn after —
**25–28% of the orchestrator's mean context**, ~$0.17–0.23 per run on Opus.
Real, worth doing, but an order of magnitude below L1 — because prompt bytes are
cached, and cache reads are 0.1× input. **Byte-cutting is a clarity win first and a
cost win second, and should be argued that way.**

The corollary matters for L2.3 of the handoff: since the orchestrator seat is
cache-read-dominated, **Fable 5.1 costs less to run there than Opus 5** on the input
side ($0.32 vs $0.65 on task 01) and more only on fresh input and output. The
existing Model-tuning note says to weigh Fable on fresh-input volume; the numbers
now back it.

---

## 3b. Measured, 2026-09-20 — what the eval actually said

§3 was built on the 2026-07-20 trace. Tasks 01–03 were re-run
(`evals/results/2026-09-20-baseline-scorecard.md`) and Layer 3 contracts run in
full (`2026-09-20-contracts.md`). Three results change or sharpen the picture.

**L3: the prompt grew unchecked.** `commands/new-task.md` grew **5,236 → 8,544 words
(+63%)** between 2026-07-20 and 2026-09-20, and *every* intervening commit added
words — the 2026-08-11 cost pass, its P2–P6 follow-up, the model tuning, the
cross-vendor allocation. **Every pass that cut dispatches grew the prompt**, and
nothing measured it: the ledger counts constructs, the lint counted consistency,
neither counts words. Once read, the file is ~22.6k tokens and 25–28% of every
later turn's context. Applied in response: lint **Check 9**, a word ratchet (§4 A4).

*Correction (2026-09-24):* the first version of this paragraph also claimed the
orchestrator's first-turn floor grew 27.4k → 41.0k *because of* the file growth. It
did not: the floor is measured before the command file is read, so it is
environment overhead, and the two traces came from different environments. The
file growth and its per-turn share stand on their own measurement above.

**L1 (turn count) is not yet measurable here.** A dispatched subagent has no Agent
tool in this environment, so the drivers could not delegate and ran every named
seat inline. Turn and mean-context deltas are confounded; the floor is not. The
turn-budget proposal (P1) stands, unmeasured.

**A real fast-path defect surfaced.** Task 01 failed its expect block — GATE 3 did
not auto-approve — because the plan-lite set itself a cosmetic `≤15 added lines`
budget and the idiomatic gofmt import needs 18. The product diff was exactly right;
the run bought a human gate with a presentation number. That is ceremony diluting
the auto-approve signal, and it is a leanness fix (P6 below).

**One contract failure — and a first fix that was wrong.** The `reviewer` invented
a severity `Informational`, outside the declared `blocker|minor` enum. Drift, not a
deterministic break (1 of 2 finding-bearing runs). The first fix justified the enum
by claiming Phase 6 consolidation buckets on severity, and told reviewers to file
non-blocking findings as `minor` *at low confidence*. Branch review caught both:
consolidation re-scores and buckets on **confidence** (drop <50) and never reads
severity, so that advice steered real findings into the drop — the "confirming"
re-run had one at confidence 40. Corrected: the enum stays (the reviewer's own
PASS/FAIL turns on it), and severity and confidence are now stated as independent
axes, with certain-but-minor findings at high confidence. Re-verified — see
`evals/results/2026-09-20-contracts.md`.

## 4. Applied in this change

| # | Change | Where |
|---|---|---|
| A1 | **Lint Check 8** — agent `model:`/`effort:` frontmatter must use accepted values (aliases, `inherit`, full `claude-*` IDs; five effort levels), and must agree with the **Effort defaults** table in `new-task.md`, both directions. It does **not** check which models honor effort — the haiku finding came from reading the CLI catalog, not from this check. | `evals/lint.sh` |
| A2 | **Corrected the Effort defaults table.** It claimed `searcher`/`test-runner` were cheap partly because of `effort: low`; haiku exposes no effort control, so that was false. `searcher`'s field is **kept** — it is live on its escalated rung (haiku → sonnet honors effort). `test-runner`'s is **removed**: it never escalates, so it could never bite. | `commands/new-task.md` § Effort defaults |
| A3 | This document: the verified price/capability table, the handoff audit, and the cost model. | `docs/proposals/` |
| A4 | **Lint Check 9** — an instruction-file **word ratchet** (`evals/size-budget.txt`, budgets at 2026-09-20 sizes +2%). Growth stays allowed; it has to be deliberate, because the budget bump lands in the same diff. Verified to fail on both growth and a missing row. | `evals/lint.sh` |
| A5 | **`agents/reviewer.md` severity enum pinned** to `blocker`/`minor`, and severity/confidence stated as independent axes (a first version wrongly claimed consolidation reads severity and advised low confidence for minor findings — corrected after branch review). | `agents/reviewer.md`; `evals/contracts/reviewer.md` |
| A6 | Eval artifacts: baseline scorecard + contract report. | `evals/results/2026-09-20-*` |

A1 is a new construct and takes a ledger row. A2 corrects a false factual claim
about the platform (CLAUDE.md rule 2 doc-fix tier); it changes no procedure and the
`effort: low` fields are byte-identical before and after, so no live eval is owed.

---

## 5. Proposed — not applied

Ranked by (saving ÷ risk), each with the A/B that would settle it.

### P1. Give the orchestrator a turn budget (L1 — biggest lever, untried)

**Status: APPLIED 2026-09-24 — harness-side, not as first proposed.** Turns multiply
every other cost and no construct addresses them. As first written, the orchestrator
would report its own turn count at each gate; that was dropped because a model cannot
count its own turns reliably deep into a long context, and the instruction would add
prompt words to the file this change is shrinking. Instead: provisional per-route
**turn bands** in `evals/rubric.md` (Efficiency dimension) and a turns-vs-band column
in the `/workflow-eval` scorecard, fed by `evals/context-trace.sh` — whose turn count
was fixed in the same change (it had been counting content blocks, ~3× responses).
Still an observability step first, not a cap. Caps risk truncating real work; measurement is
free and tells us whether the tail is gate overhead, re-dispatch, or genuine work.
`evals/context-trace.sh` already parses turns, so the scorecard column exists.
**A/B:** none needed for the observability step. A later cap needs `turn-budget-off`.

### P2. Validate P1-of-2026-08-11 (orchestrator `high` vs `xhigh`) in a real CLI run

**Status: NOT APPLIED — cannot be, here.** It is a measurement, not a change, and it
needs a real CLI session (effort is inert in the eval harness).

Owed since 2026-08-11, still open, and §1 shows `high` is the model default — so this
is now a *confirmation* rather than a gamble. It is the cheapest open item on the
board: two real runs, cost read from `/usage`.
**Variant:** `agent-effort-xhigh-restore` (already authored).

### P3. Move maintainer-facing rationale out of the runtime prompt (L3)

**Status: APPLIED 2026-09-24.** The Model-tuning notes and Cross-vendor allocation section (588 words) moved verbatim to `docs/model-tuning-notes.md`, with a preface naming where each operative piece still lives. The one list an instruction file acts on — the must-not-move seats — is inlined in `skills/codex-exec/SKILL.md`; the five command headers lose their now-dangling pointer (their inline Fable cost note stays). `new-task.md` 8,544 → 7,992 words with P6; budget lowered to match under the two-way ratchet.

`commands/new-task.md` carries ~3.9 KB of **Model-tuning notes** plus its
**Cross-vendor allocation** subsection. Reading them, most is a design record aimed
at whoever edits the workflow next — "recorded so a future pass does not re-derive
it", "a change justified by one model's guidance must name which files it touches" —
not instruction the orchestrator acts on during a run. One operative line
(*never switch your own model mid-run*) is **already duplicated** in the Session
hygiene bullet. Proposal: move the record to `docs/`, keep the operative lines, leave
a one-line pointer. ~1.1k tokens off every turn, and the file gets easier to read.
**A/B:** `model-tuning-notes-inline` (restore variant) — cheap, but the prior is that
a pure relocation of non-operative prose is behavior-neutral, so this may qualify as
a doc change. Decide when writing it, not now.

### P4. Price the 1h cache TTL recommendation

**Status: APPLIED 2026-09-24** — README session-hygiene line.

`ENABLE_PROMPT_CACHING_1H=1` is recommended in the README and the 2026-07-20 proposal
without its price. Per §1 it costs **2× input on write vs 1.25× for 5m** — i.e. an
extra 0.75× input per cached prefix — and pays for itself the moment it saves one
re-write. This workflow's gates are **human approval points**, which routinely idle
past 5 minutes and rarely past an hour, so the recommendation is sound; it should
just carry the number. Doc-only.

### P6. Drop cosmetic size caps from plan-lite (new, from task 01)

**Status: APPLIED 2026-09-24** — one sentence in fast-path step 3, phrased as something the orchestrator tells the `architect` (which never reads `new-task.md`). Validation: task 01 re-run — see `evals/results/2026-09-20-baseline-scorecard.md`.

Plan-lite should state **content** contracts, never cosmetic line budgets. A
self-imposed `≤15 added lines` cost task 01 its fast-path auto-approval for a diff
that was otherwise perfect, because meeting the cap meant degrading idiomatic Go.
Auto-approval is a safety signal; diluting it with presentation numbers makes a
human gate mean less, not more. Behavior-affecting (`commands/new-task.md` fast
path) → owes its own scorecard.

### P5. Do NOT adopt the handoff's draft command

Per §2.3. If any of it is wanted, the portable parts are already present; the rest
would need to be re-derived against this repo's agent set and would fail the lint.
