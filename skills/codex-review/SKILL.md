---
name: codex-review
description: Run the Channel B codex review reliably — non-interactive, stdin closed, a generous diff-scaled timeout, read-only sandbox, output captured and degrade-only. Use whenever a review fan-out shells out to codex (new-task Phase 6 / review-pr Channel B).
---

# Codex review (Channel B)

Codex is the out-of-model review perspective. It **degrades free** — a codex that
fails to run is a lost perspective, never a failed run — but the failures worth
preventing here are the *avoidable* ones: a hang on stdin, or a timeout so short it
kills a review that would have finished. Run it so the only skips are genuine (CLI
absent, real error), never self-inflicted.

Flag names track the installed `codex`; the principles below — stdin closed,
generous scaled timeout, read-only sandbox, captured output, degrade-only — are
what actually matter, so adapt a flag if a version renamed it rather than dropping
the principle.

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
    "Review the diff between $BASE_SHA and HEAD in this repo for bugs, edge cases, and design issues. Return numbered findings with file:line." \
    < /dev/null > "$OUT" 2>&1
code=$?
```

- `< /dev/null` is the stdin fix — the single most common cause of a codex "hang"
  in an agent/CI context is the process waiting on stdin that never arrives.
- Pass the prompt as an ARGUMENT, never piped on stdin — stdin stays closed.
- `--sandbox read-only` — a review writes nothing and needs no network; read-only
  also removes any write-approval prompt that could stall the run.
- `--ask-for-approval never` — never pause for interactive approval (harmless if
  the installed `exec` already defaults to it; explicit is version-safe).
- `--cd "$REPO"` — pin the working dir so the diff resolves regardless of caller cwd.

## 2. Give it enough time — scale the budget, don't clip it

The reported failures were a flat ~5 min ceiling killing real reviews. Budget
generously and scale with the diff; a review that needs twelve minutes and is given
five is a **false** skip, not a real one.

- Floor **10 min**. Add time for large diffs (≈ +1 min per 200 changed lines) up to
  a **~20 min** hard ceiling.
- Wrap in `timeout` with a **`--kill-after`** grace (above) so a genuinely hung
  process is actually reaped instead of orphaned.

Never drop the budget below the 10 min floor to "save time": the channel degrades
free, so a slow codex costs nothing, but a fast-but-clipped one silently loses the
whole out-of-model perspective.

## 3. Capture, classify, degrade — never block the barrier

Codex output goes to a scratch file, never raw into the orchestrator context;
`test-runner` digests anything longer than ~100 lines. Classify the exit code and
record a precise reason — that is what makes a skip auditable rather than mysterious:

- `0` → findings captured; digest (if long) and feed to consolidation.
- `124` (from `timeout`) → `codex: skipped (timeout after <BUDGET>)`.
- `127`, or `command -v codex` fails → `codex: skipped (not installed)`.
- any other nonzero → `codex: skipped (exit <code>: <first stderr line>)` — auth,
  quota, and config errors land here.

In every skip case the fan-out continues immediately: codex **never holds the
consolidation barrier and never counts as a failure.**

## 4. Preconditions worth one check first

Before spending the budget, confirm two things so the timeout is never wasted on a
run that could not have produced findings:

1. `command -v codex` succeeds (else `codex: skipped (not installed)`).
2. `$BASE_SHA` and `HEAD` both resolve — `git rev-parse --verify "$BASE_SHA^{commit}"`
   and `HEAD` — else `codex: skipped (unresolved diff range)`. A codex run over an
   unresolved range burns the entire budget to produce nothing.
