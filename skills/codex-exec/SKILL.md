---
name: codex-exec
description: Run codex non-interactively as the out-of-model second opinion — design lens, adversarial design review, code review, root-cause digest, or batched claim verification. Pinned model + effort per pass, stdin closed, generous timeout, read-only sandbox, output captured, exit codes classified (including quota). Use whenever the workflow shells out to codex (new-task Phases 1/2/6/6.5, review-pr, triage-issue, address-review).
---

# Codex exec (the out-of-model second opinion)

Codex is the workflow's **second head**. Where a pass needs two independent
perspectives, the second one is codex rather than another Claude subagent: the
diversity is better (different model, different training) and the tokens are not on
the Claude bill — though not off *every* bill, which is what §0 is about. Five passes
use it:

| Pass | Where | Recipe | Model (default → escalated) | If codex is unavailable |
|---|---|---|---|---|
| **Design lens** | new-task Phase 1.2 | §5.1 | `gpt-5.6-terra` → `gpt-5.6-sol` | fall back to a second `architect` on the alternate lens |
| **Adversarial design review** | new-task Phase 2.1 | §5.2 | `gpt-5.6-sol` → `gpt-6-astra` (high-stakes only) | fall back to a fresh `architect` (opus) |
| **Code review (Channel B)** | new-task Phase 6.3; review-pr R1; iterate I2 | §5.3 | `gpt-5.6-sol` → **`gpt-6-astra` @ `xhigh`** | degrades free — the Claude channel still runs |
| **Root-cause digest** | new-task Phase 6.5 / debugger rung; triage-issue T2 | §5.4 | `gpt-6-astra` @ `xhigh` | ladder continues to the fable `debugger` |
| **Batched claim verification** | address-review A3 | §5.5 | `gpt-5.6-sol` | fall back to the per-item Claude `reviewer` fan-out |

**Degrade policy differs by pass, and that difference is the point.** In review,
codex is one of two channels, so a skip costs a perspective and nothing else. In
Phases 1 and 2 codex is the *only* agent staffing that slot, so a skip must be
**backfilled by the named Claude fallback** — never silently dropped. Record the
outcome either way (`codex: ok (<model>)` / `codex: skipped (<reason>) → <fallback>`).

Flag names track the installed `codex`; the principles below — stdin closed, pinned
model, generous timeout, read-only sandbox, captured output, classified exit — are what
actually matter, so adapt a flag if a version renamed it rather than dropping the
principle.

## 0. Off the Claude bill is not free — pin the model, spend the budget deliberately

Two corrections to the 2026-08-11 framing, applied 2026-09-07
(`docs/proposals/2026-09-07-codex-astra-model-allocation.md`):

- **Codex is quota-metered, not free.** A plan-billed CLI meters the flagship at a
  reported 5–45 messages per 5-hour window on Plus/Business Standard (more on Pro),
  and a standard `/new-task` run spends 3–5 codex invocations. An API-billed
  `gpt-6-astra` costs $10/$50 per MTok with **$1.00** cache reads — 2× Opus 5's and
  **4× Fable 5.1's**, i.e. more than any model in the Claude fleet on cached context.
  Codex is off the *Claude* bill; it is not off *a* bill.
- **The CLI's default model is not the workflow's choice.** When the bundled default
  moved to `gpt-6-astra`, every pass here changed model, cost tier, latency profile
  and quota bucket silently. **Always pass `--model`.** The pass chooses; the CLI
  does not.

Hence the ladder in the table above, and its budget: **AT MOST ONE `gpt-6-astra` pass
per run.** It is spent on the pass with the largest measured Astra delta — the code
review channel on a cross-file or high-stakes diff — unless a root-cause escalation
(§5.4) claims it first. Every other pass runs a cheaper tier. The evidence behind the
split: `gpt-6-astra` leads `gpt-5.6-sol` by ~2 points on ordinary review but by ~20%
on **cross-file** review, so cross-file-ness (not diff size) is the escalation
trigger.

## 1. Invoke non-interactively, with stdin closed

Use the `exec` (automation) subcommand, pass the prompt as the positional
**argument**, and **redirect stdin from `/dev/null`** so codex never blocks waiting
on a TTY/pipe that will never deliver:

```sh
timeout --kill-after=30s "$BUDGET" \
  codex exec \
    --cd "$REPO" \
    --model "$MODEL" \
    -c model_reasoning_effort="$EFFORT" \
    --sandbox read-only \
    --ask-for-approval never \
    --color never \
    "$PROMPT" \
    < /dev/null > "$OUT" 2>&1
code=$?
```

- `< /dev/null` is the stdin fix — the single most common cause of a codex "hang"
  in an agent/CI context is the process waiting on stdin that never arrives.
- Pass the prompt as an ARGUMENT, never piped on stdin — stdin stays closed.
- `--sandbox read-only` — every pass here reads and reasons; none of them writes.
  Read-only also removes any write-approval prompt that could stall the run.
- `--ask-for-approval never` — never pause for interactive approval (harmless if
  the installed `exec` already defaults to it; explicit is version-safe).
- `--cd "$REPO"` — pin the working dir so paths and the diff resolve regardless of
  caller cwd.
- `--model` / `-c model_reasoning_effort=` — pin BOTH per §0's table; never inherit
  the CLI default. `high` is the coding default, `xhigh` for an escalated pass; `max`
  is not used here — every pass sits on a barrier and `max` buys latency, not recall.

## 2. Give it enough time — scale the budget, don't clip it

The reported failures were a flat ~5 min ceiling killing real reviews. Budget
generously; a pass that needs twelve minutes and is given five is a **false** skip.

- Floor **10 min** for every pass. For code review, add time for large diffs
  (≈ +1 min per 200 changed lines) up to a **~20 min** hard ceiling.
- Wrap in `timeout` with a **`--kill-after`** grace (above) so a genuinely hung
  process is reaped instead of orphaned.

Never drop below the 10 min floor to "save time": a clipped pass burns a **whole
quota message** and returns nothing, which is strictly worse than not running it — and
in Phases 1/2 it forces a Claude fallback that costs real tokens on top. The scarce
resource is messages and wall-clock, not seconds; spend the seconds.

## 3. Capture, classify, degrade — never block the barrier

Codex output goes to a scratch file, never raw into the orchestrator context;
`test-runner` digests anything longer than ~100 lines. Classify the exit code and
record a precise reason — that is what makes a skip auditable rather than mysterious:

- `0` → output captured; digest (if long) and feed it to the pass that asked for it.
- `124` (from `timeout`) → `codex: skipped (timeout after <BUDGET>)`.
- `127`, or `command -v codex` fails → `codex: skipped (not installed)`.
- **quota / rate limit** (a 429, or stderr naming a usage limit, quota, or 5-hour
  window) → do NOT skip yet: **downshift one tier** (`gpt-6-astra` → `gpt-5.6-sol` →
  `gpt-5.6-terra`) and retry once, recording `codex: downshifted (quota) → <model>`.
  A different tier is a different quota bucket, so the pass usually survives. Only if
  the downshifted retry also fails does the pass reach its named fallback, recorded as
  `codex: skipped (quota exhausted) → <fallback>`.
- any other nonzero → `codex: skipped (exit <code>: <first stderr line>)` — auth and
  config errors land here.

On any skip the run continues immediately: codex **never holds a barrier and never
counts as a failure** — it either degrades free (review) or hands off to its named
fallback (design passes), per the table above.

## 4. Preconditions worth one check first

Before spending the budget, confirm the pass could produce anything at all:

1. `command -v codex` succeeds (else `codex: skipped (not installed)`). The pinned
   model must be one the installed CLI knows — an unknown `--model` fails fast, which
   is the point of pinning; on that failure downshift per §3 rather than falling back
   to the CLI default, which would silently re-introduce the drift §0 exists to stop.
2. For the code-review pass, `$BASE_SHA` and `HEAD` both resolve —
   `git rev-parse --verify "$BASE_SHA^{commit}"` and `HEAD` — else
   `codex: skipped (unresolved diff range)`. A codex run over an unresolved range
   burns the entire budget to produce nothing.
3. For the design passes, every path handed to codex (design doc, plan) exists —
   else `codex: skipped (missing artifact <path>)`.

## 5. Prompt recipes

Each pass asks codex for the **same shape of answer the Claude agent it stands
beside would return**, so consolidation compares like with like. Always demand a
bounded output — codex is verbose by default.

### 5.1 Design lens (new-task Phase 1.2)

Codex is the second brainstorm lens. Give it the task statement, the Phase 0
searcher/researcher digests (inline — they are already capped), and a lens
**distinct from the Claude architect's**:

> `Propose ONE implementation approach for: <task>. Lens: <e.g. simplest thing that
> could work / alternative paradigm or library>. Repo context: <digests>. Do NOT
> write code and do NOT write files. Return under 400 words: goal (1 sentence),
> approach, key interfaces, trade-offs (strengths, costs, risks), and what you would
> reject and why.`

Return shape matches `architect` inline mode, so the synthesizer ranks two
comparable digests.

### 5.2 Adversarial design review (new-task Phase 2.1)

Codex reviews the design doc it did not write:

> `Adversarially review the design document at <path> against this task: <task>.
> Judge soundness, missed alternatives, risks, and scope. Do NOT write files. Return
> numbered BLOCKING issues (each: what is wrong, why it blocks) or the exact text
> "no blocking issues". List non-blocking observations separately — they must not
> appear as blocking.`

The phase exits only on `no blocking issues`, so the literal-string requirement is
load-bearing: a vague pass is treated as blocking-unknown, not as an exit.

### 5.3 Code review (Channel B — new-task Phase 6.3, review-pr R1)

> `Review the diff between <BASE_SHA> and HEAD in this repo for bugs, edge cases,
> and design issues, against this intent: <plan path or intent digest>. Do NOT write
> files. Return numbered findings, each with severity (blocker|minor), file:line, and
> what is wrong — not how to rewrite it. Report at most the 10 highest-severity
> findings; skip style nits a linter would catch.`

The finding shape matches `reviewer`'s Output contract so the consolidation step
dedupes and scores both channels on one scale.

**Lead with correctness.** Channel A (Claude) leads on the repo-context lenses — plan
compliance, `CLAUDE.md`/conventions, git history — which need the plan, the repo rules
and the history that a read-only codex pass given a path does not carry. So this pass
leads on **correctness and cross-file behavior**: append to the recipe
`Prioritise defects that span more than one file — a caller/callee mismatch, a changed
invariant one side still assumes, a contract satisfied locally but broken globally.`
That is the band the escalated model measurably wins; style, conventions and plan
mapping are not this channel's job.

### 5.4 Root-cause digest (new-task Phase 6.5 / the debugger rung; triage-issue T2)

The one pass that runs the flagship by default. It **diagnoses and never fixes** — the
read-only sandbox is what makes it safe as a ladder rung, and a Claude agent carrying
repo context and write access applies whatever it finds:

> `Root-cause this failure in this repo: <failure digest — what was tried, what failed,
> exact error>. Relevant paths: <paths>. Do NOT write files and do NOT propose a diff.
> Return under 400 words: the root cause in one paragraph and the evidence for it
> (file:line), or — if you cannot verify one — ranked hypotheses each with the single
> check that would confirm it. Say explicitly which of the two you are returning.`

The forced either/or is load-bearing: an unverified root cause presented as verified is
worse than none here, because the next agent implements it. A digest that merely
restates the failure is a skip in disguise — record it as `codex: no root cause` and
continue up the ladder.

### 5.5 Batched claim verification (address-review A3)

One pass over ALL candidate items, default-refute — the shape Phase 6's skeptic already
uses, moved out-of-model:

> `For each numbered claim below, verify it against the actual code in this repo and
> try to REFUTE it. Diff range: <BASE_SHA>..HEAD. Do NOT write files. Return one entry
> per claim, in the input order and numbered identically: the literal word "stands" or
> "refuted", the file:line evidence, and one sentence of reasoning. Do not skip a claim;
> if you cannot evaluate one, return "undetermined" with the reason.
> Claims: <numbered list>.`

Identical numbering is the contract — consolidation joins on it, and a pass that
renumbers or reorders is treated as unusable rather than guessed at. Any `undetermined`
entry, and any claim whose truth turns on repo convention, plan intent or `CLAUDE.md`
compliance, routes to a Claude `reviewer` instead: codex cannot judge those without the
repo context the Claude agents read.
