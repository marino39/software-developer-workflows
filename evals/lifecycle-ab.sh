#!/bin/sh
# Layer-2 lifecycle A/B runner — LIVE tier (dispatches models; NOT deterministic).
#
# Runs the /new-task driver headlessly via `claude -p`. The key fact: a TOP-LEVEL
# `claude -p` session has the Agent tool, while `claude -p --agent <name>` does
# not — so the driver really fans out to architect/coder/reviewer and the traces
# read a genuine orchestrator transcript. In harnesses where in-session subagents
# cannot dispatch, this is how Layer 2 runs at all.
#
# Usage: evals/lifecycle-ab.sh <arm-label> <run-index> [variant-name]
#   variant-name -> prepends the Delta block of evals/variants/<name>.md
#
# Notes:
# - `--permission-mode acceptEdits --allowedTools Bash Agent` is required; the
#   default headless posture denies writes, builds AND dispatch.
# - The fixture copy is git-initialized: Phase 0 takes a worktree and Phase 6
#   computes BASE_SHA/HEAD_SHA from a merge-base.
# - Route varies run to run on the same task (scoped vs standard). Compare within
#   route or raise n — see the 2026-07-29 lifecycle scorecard.
set -u
ARM="$1"; IDX="$2"; VARIANT="${3:-}"; TASKID="${4:-23}"
# ROUTE_FLOOR=standard pins the route via the workflow's own triage-manifest
# floor mechanism (new-task.md Phase 0 step 5: floors are monotonic, inherit and
# escalate only). Set it in BOTH arms of an A/B — identical text both sides —
# so routing stops being a variable. Added after the 2026-08-10 readiness A/B,
# where route confounded arm perfectly.
ROUTE_FLOOR="${ROUTE_FLOOR:-}"
SCRATCH="${EVAL_SCRATCH:-/tmp/workflow-eval}"
mkdir -p "$SCRATCH"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
case "$TASKID" in
    24) FIXTURE="$REPO/evals/fixtures/svc" ;;
    *)  FIXTURE="$REPO/evals/fixtures/base" ;;
esac
OUT="$SCRATCH/lc-out/$ARM"; mkdir -p "$OUT"
d="$SCRATCH/lc-work/$ARM-$IDX"
rm -rf "$d"; mkdir -p "$d"
cp -r "$FIXTURE"/. "$d"/

# The fixture copy must be a git repo: Phase 0 takes a worktree and Phase 6
# computes BASE_SHA/HEAD_SHA from a merge-base.
( cd "$d" && git init -q -b main && git add -A \
  && git -c user.email=eval@local -c user.name=eval commit -qm "base fixture" )

if [ "$TASKID" = "24" ]; then
    # task 24 — cross-slice contract; routes standard, so it reaches Phase 4
    TASK='In the `evalsvc` module, make failures distinguishable to callers of `api.Lookup`: a caller must be able to tell an invalid id from an id that simply is not stored. Today both collapse to "". Change `store.Get` and `validate.ID` to report failures as errors, and have `api.Lookup` return the name plus an HTTP status - 200, 400 for an invalid id, 404 for a missing item, 500 otherwise.'
else
    TASK='In the `evalfixture` module'"'"'s `calc` package, add a public function `Mode(xs []int) int` that returns the most frequently occurring element of the slice. Add a `TestMode`.'
fi

DELTA=""
if [ -n "$VARIANT" ]; then
    # the Delta block from evals/variants/<name>.md, verbatim
    DELTA="$(awk '/^> VARIANT/,/^$/' "$REPO/evals/variants/$VARIANT.md")
"
fi

FLOOR=""
if [ -n "$ROUTE_FLOOR" ]; then
    FLOOR="A triage manifest for this task supplies the route floor: **$ROUTE_FLOOR** (per new-task.md Phase 0 step 5, the floor is monotonic — inherit it and escalate only, never de-escalate below it; state the inherited floor at the first touchpoint).

"
fi

PROMPT="${DELTA}${FLOOR}You are running under the eval harness. You are the approver: at every human gate, AUTO-APPROVE and log the gate summary verbatim; NEVER call AskUserQuestion or ask the human anything.

Follow the workflow in /root/.claude/commands/new-task.md VERBATIM for the task below. Read that file first; it is the command definition.

Operate ONLY on the copied fixture at $d (already a git repo, branch main, one commit). Do NOT read or modify anything under $REPO — that is the workflow repo, not your working tree.

There is no git remote and no CI in this environment: finish locally (merge the branch or keep it), NEVER attempt to open a PR or push, and SKIP Phase 6.5 entirely.

Task: $TASK

When finished, return: the final route, the per-gate summaries verbatim, the Phase 7 retro, the final \`git diff\`, and the \`go test ./...\` result."

( cd "$d" && timeout 2400 claude -p --allowedTools Bash Agent \
    --permission-mode acceptEdits "$PROMPT" < /dev/null ) \
    > "$OUT/run-$IDX.txt" 2>&1
echo "exit=$?" >> "$OUT/run-$IDX.txt"

# locate this run's driver transcript by its cwd-encoded project dir
enc=$(printf '%s' "$d" | sed 's#/#-#g')
pdir="/root/.claude/projects/$enc"
T=$(ls -t "$pdir"/*.jsonl 2>/dev/null | head -1)
{
    echo "--- TRANSCRIPT: $T"
    [ -n "$T" ] && sh "$REPO/evals/context-trace.sh" "$T"
    [ -n "$T" ] && sh "$REPO/evals/dispatch-trace.sh" --detail "$T"
    echo "--- FACTS"
    echo "build: $(cd "$d" && go build ./... 2>&1 | head -2 | tr '\n' ' ')"
    echo "go-test: $(cd "$d" && go test -count=1 ./... 2>&1 | tail -3 | tr '\n' ' ')"
    # Artifact survival (the 2026-08-11 anchor + rescue-sweep fix): after finish,
    # the plan/design doc must exist in the MAIN dir, every docs/superpowers/ path
    # recorded in the manifest must resolve, and no stray worktree may still hold
    # artifacts. Checked on every run so a green result is evidence, not luck.
    echo "plan-survives: $(ls "$d"/docs/superpowers/plans/*.md 2>/dev/null | wc -l) file(s)"
    echo "design-survives: $(ls "$d"/docs/superpowers/specs/*.md 2>/dev/null | wc -l) file(s)"
    m=$(ls "$d"/docs/superpowers/runs/*-manifest.md 2>/dev/null | head -1)
    if [ -n "$m" ]; then
        dangling=0
        for ap in $(grep -oE '[^ `"'"'"')(]*docs/superpowers/[A-Za-z0-9/._-]*\.md' "$m" | sort -u); do
            case "$ap" in /*) f="$ap" ;; *) f="$d/$ap" ;; esac
            [ -f "$f" ] || dangling=$((dangling + 1))
        done
        echo "manifest-paths-dangling: $dangling"
    else
        echo "manifest-paths-dangling: no-manifest"
    fi
    echo "stray-worktree-artifacts: $(find "$SCRATCH/lc-work" -maxdepth 4 -path "*$ARM-$IDX-wt-*docs/superpowers*" -name '*.md' 2>/dev/null | wc -l)"
    if [ "$TASKID" = "24" ]; then
        # S3's question: did the PLAN pin the cross-slice error contract before dispatch?
        echo "plan-pins-contract: $(grep -rilE 'ErrNotFound|errors\.Is|sentinel' "$d"/docs 2>/dev/null | tr '\n' ' ')"
        echo "lookup-sig: $(grep -h 'func Lookup' "$d"/api/api.go 2>/dev/null)"
        echo "store-sig: $(grep -h 'func (s \*Store) Get' "$d"/store/store.go 2>/dev/null)"
        echo "validate-sig: $(grep -h 'func ID' "$d"/validate/validate.go 2>/dev/null)"
        echo "api-matches-on: $(grep -oE 'errors\.(Is|As)\([^)]*\)' "$d"/api/api.go 2>/dev/null | tr '\n' ' ')"
        echo "store-exports-err: $(grep -oE '(Err[A-Z][A-Za-z]*|type [A-Za-z]*Error)' "$d"/store/store.go 2>/dev/null | sort -u | tr '\n' ' ')"
        echo "validate-exports-err: $(grep -oE '(Err[A-Z][A-Za-z]*|type [A-Za-z]*Error)' "$d"/validate/validate.go 2>/dev/null | sort -u | tr '\n' ' ')"
        # match named constants too — a literal-only grep false-negatived 3 of 4
        # runs on 2026-08-10, which use http.StatusBadRequest rather than 400
        echo "statuses-tested: $(grep -oE 'http\.Status[A-Za-z]+|\b(200|400|404|500)\b' "$d"/api/api_test.go 2>/dev/null | sort -u | tr '\n' ' ')"
    else
        echo "mode-defined: $(grep -rc 'func Mode' "$d"/calc/calc.go 2>/dev/null)"
        echo "empty-tested: $(grep -cE 'Mode\((nil|\[\]int\{\})\)' "$d"/calc/calc_test.go 2>/dev/null)"
    fi
    echo "CONTAMINATION: $(git -C "$REPO" status --porcelain --untracked-files=no | wc -l) tracked repo files dirty"
} >> "$OUT/run-$IDX.txt"
echo "done: $ARM-$IDX"
