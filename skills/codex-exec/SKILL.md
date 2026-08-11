---
name: codex-exec
description: Run codex non-interactively as the out-of-model second opinion — design lens, adversarial design review, or code review. Stdin closed, generous timeout, read-only sandbox, output captured, exit codes classified. Use whenever the workflow shells out to codex (new-task Phases 1/2/6, review-pr).
---

# Codex exec (the out-of-model second opinion)

Codex is the workflow's **second head**. Where a pass needs two independent
perspectives, the second one is codex rather than another Claude subagent: the
diversity is better (different model, different training) and the tokens are not on
the Claude bill. Three passes use it:

| Pass | Where | Prompt recipe | If codex is unavailable |
|---|---|---|---|
| **Design lens** | new-task Phase 1.2 | §5.1 | fall back to a second `architect` on the alternate lens |
| **Adversarial design review** | new-task Phase 2.1 | §5.2 | fall back to a fresh `architect` (opus) |
| **Code review (Channel B)** | new-task Phase 6.3; review-pr R1 | §5.3 | degrades free — the Claude channel still runs |

**Degrade policy differs by pass, and that difference is the point.** In review,
codex is one of two channels, so a skip costs a perspective and nothing else. In
Phases 1 and 2 codex is the *only* agent staffing that slot, so a skip must be
**backfilled by the named Claude fallback** — never silently dropped. Record the
outcome either way (`codex: ok` / `codex: skipped (<reason>) → <fallback>`).

Flag names track the installed `codex`; the principles below — stdin closed,
generous timeout, read-only sandbox, captured output, classified exit — are what
actually matter, so adapt a flag if a version renamed it rather than dropping the
principle.

## 1. Invoke non-interactively, with stdin closed

Use the `exec` (automation) subcommand, pass the prompt as the positional
**argument**, and **redirect stdin from `/dev/null`** so codex never blocks waiting
on a TTY/pipe that will never deliver:

```sh
timeout --kill-after=30s "$BUDGET" \
  codex exec \
    --cd "$REPO" \
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

## 2. Give it enough time — scale the budget, don't clip it

The reported failures were a flat ~5 min ceiling killing real reviews. Budget
generously; a pass that needs twelve minutes and is given five is a **false** skip.

- Floor **10 min** for every pass. For code review, add time for large diffs
  (≈ +1 min per 200 changed lines) up to a **~20 min** hard ceiling.
- Wrap in `timeout` with a **`--kill-after`** grace (above) so a genuinely hung
  process is reaped instead of orphaned.

Never drop below the 10 min floor to "save time": codex time is not Claude spend,
so a slow codex is cheap, while a fast-but-clipped one loses the whole out-of-model
perspective — and in Phases 1/2 forces a Claude fallback that costs real tokens.

## 3. Capture, classify, degrade — never block the barrier

Codex output goes to a scratch file, never raw into the orchestrator context;
`test-runner` digests anything longer than ~100 lines. Classify the exit code and
record a precise reason — that is what makes a skip auditable rather than mysterious:

- `0` → output captured; digest (if long) and feed it to the pass that asked for it.
- `124` (from `timeout`) → `codex: skipped (timeout after <BUDGET>)`.
- `127`, or `command -v codex` fails → `codex: skipped (not installed)`.
- any other nonzero → `codex: skipped (exit <code>: <first stderr line>)` — auth,
  quota, and config errors land here.

On any skip the run continues immediately: codex **never holds a barrier and never
counts as a failure** — it either degrades free (review) or hands off to its named
fallback (design passes), per the table above.

## 4. Preconditions worth one check first

Before spending the budget, confirm the pass could produce anything at all:

1. `command -v codex` succeeds (else `codex: skipped (not installed)`).
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
