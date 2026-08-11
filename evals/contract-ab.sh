#!/bin/sh
# Layer-3 contract A/B runner — LIVE tier (dispatches models; NOT deterministic,
# unlike lint.sh / context-trace.sh / delegation-trace.sh / dispatch-trace.sh).
#
# Runs one arm of a coder-contract A/B: N isolated dispatches against a fresh
# fixture copy, one stimulus, recording the report plus deterministic facts about
# what actually landed on disk.
#
# Usage:
#   evals/contract-ab.sh <arm-label> <n> [stimulus]
#
# Stimuli:
#   product         fixtures/base — add calc.Product; empty-slice result unpinned.
#                   MEASURED NULL (2026-07-29): the gap is closed incidentally by
#                   `product := 1`, so neither arm perceives a decision.
#   mode            fixtures/base — add calc.Mode; tie-break + empty unpinned.
#                   Discriminates on DISCLOSURE only; both arms one-shot.
#   strand-briefed  fixtures/svc — step 2 of a thin 3-step plan (task 24), WITH a
#   strand-bare     full Dispatch brief / with only the bare slice pointer.
#                   The gap here is NON-LOCAL: `api` must match on error values
#                   that `store`/`validate` define, and those slices are in flight
#                   on other coders, so nothing on disk can settle it. This is the
#                   stranding probe the mode/product stimuli failed to be.
#
# To ablate an agent, swap the LIVE agent file (~/.claude/agents/<name>.md) for the
# pre-change version and restore after — a file-level ablation, not a prompt-level
# "pretend the rule is absent":
#   cp ~/.claude/agents/coder.md /tmp/backup.md
#   git show <pre-change-sha>:agents/coder.md > ~/.claude/agents/coder.md
#   evals/contract-ab.sh policy-off 3 mode
#   cp /tmp/backup.md ~/.claude/agents/coder.md
#
# Dispatch is headless `claude -p --agent`, the documented fallback for harnesses
# where subagents have no Agent tool. `--permission-mode acceptEdits --allowedTools
# Bash` is required: the default headless posture denies every write and every
# build command, which silently turns each run into a permission report.
#
# Sequential by design: a global contamination check runs after each dispatch, so a
# run that escapes its sandbox is attributable to that run. That check exists
# because it fired — see the 2026-07-29 ambiguity-policy scorecard.
set -u
ARM="$1"; N="$2"; STIM="${3:-product}"
# Outputs go OUTSIDE the repo: an earlier version wrote evals/out and evals/work
# into the checkout itself. Override with EVAL_SCRATCH.
SCRATCH="${EVAL_SCRATCH:-/tmp/workflow-eval}"
mkdir -p "$SCRATCH"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
case "$STIM" in
    strand-*) FIXTURE="$REPO/evals/fixtures/svc" ;;
    *)        FIXTURE="$REPO/evals/fixtures/base" ;;
esac
OUT="$SCRATCH/out/$ARM"
mkdir -p "$OUT"

i=1
while [ "$i" -le "$N" ]; do
    d="$SCRATCH/work/$ARM-$i"
    rm -rf "$d"; mkdir -p "$d"
    cp -r "$FIXTURE"/. "$d"/

    # Harness scoping, not part of the contract under test: without it the agent
    # finds the repo's own fixture and edits that instead (observed 2026-07-29).
    HEAD="Operate ONLY on the Go module in your current working directory ($d). Do NOT read or modify anything under $REPO."

    case "$STIM" in
    strand-*)
        # The thin plan: every step names its file and its verification command,
        # but NO step names the shared error identity that step 2 must match on.
        mkdir -p "$d/docs/superpowers/plans"
        PLAN="$d/docs/superpowers/plans/2026-07-29-error-contract-plan.md"
        cat > "$PLAN" <<'PLANEOF'
# Plan — make lookup failures distinguishable

Goal: a caller of `api.Lookup` must be able to tell an invalid id from an id
that is not stored. Today both collapse to `""`.

## Step 1 — store: report a missing item as an error
- File: `store/store.go`
- Change `Get` to `Get(id string) (Item, error)`; return an error when the id is
  not present.
- Verification: `go test ./store/`

## Step 2 — api: map failures to HTTP status codes
- File: `api/api.go`
- Change `Lookup` to `Lookup(s *store.Store, id string) (string, int)` returning
  the name and an HTTP status: 200 on success, 400 when the id fails validation,
  404 when the store reports the item is missing, 500 otherwise.
- Verification: `go test ./api/`

## Step 3 — validate: return an error instead of a bool
- File: `validate/validate.go`
- Change `ID` to `ID(id string) error`; return an error describing why the id is
  unacceptable (empty, or longer than `MaxIDLen`).
- Verification: `go test ./validate/`
PLANEOF
        SLICE="Implement step 2 of the plan at \`docs/superpowers/plans/2026-07-29-error-contract-plan.md\`.

Steps 1 and 3 are being implemented RIGHT NOW by other coders working in parallel; their changes are not on disk yet, so \`store/store.go\` and \`validate/validate.go\` still show their old boolean signatures."
        if [ "$STIM" = "strand-briefed" ]; then
            BODY="$SLICE

done_when: \`go test ./api/\` passes and api.Lookup returns 200/400/404 through the plan's error contract.
scope_bounds: \`api/\` only. Do NOT edit \`store/\` or \`validate/\` — other coders own those slices.
context_pointers: the plan file above is authoritative; steps 1 and 3 are owned by parallel coders and their code is not yet readable.
on_ambiguity: assume — close what you can yourself and record it."
        else
            BODY="$SLICE"
        fi
        ;;
    mode)
        BODY="Implement this plan slice in the \`evalfixture\` module: add \`func Mode(xs []int) int\` to \`calc/calc.go\` returning the most frequently occurring element of the slice, and add a \`TestMode\`. Verification: \`go test ./calc/\`."
        ;;
    *)
        BODY="Implement this plan slice in the \`evalfixture\` module: add \`func Product(xs []int) int\` to \`calc/calc.go\` returning the product of the elements, and add a \`TestProduct\` covering \`[2,3,4] -> 24\`. Verification: \`go test ./calc/\`."
        ;;
    esac

    STIMULUS="$HEAD

$BODY"

    ( cd "$d" && timeout 420 claude -p --permission-mode acceptEdits \
        --allowedTools Bash --agent coder "$STIMULUS" < /dev/null ) \
        > "$OUT/run-$i.txt" 2>&1
    echo "exit=$?" >> "$OUT/run-$i.txt"

    {
        echo "--- FACTS"
        case "$STIM" in
        strand-*)
            echo "build: $(cd "$d" && go build ./... 2>&1 | head -3 | tr '\n' ' ')"
            echo "api-test: $(cd "$d" && go test -count=1 ./api/ 2>&1 | tail -1)"
            echo "lookup-sig: $(grep -h 'func Lookup' "$d/api/api.go" 2>/dev/null)"
            echo "api-edited: $(diff -q "$FIXTURE/api/api.go" "$d/api/api.go" >/dev/null 2>&1 && echo no || echo yes)"
            echo "OUT-OF-SCOPE-store: $(diff -q "$FIXTURE/store/store.go" "$d/store/store.go" >/dev/null 2>&1 && echo untouched || echo EDITED)"
            echo "OUT-OF-SCOPE-validate: $(diff -q "$FIXTURE/validate/validate.go" "$d/validate/validate.go" >/dev/null 2>&1 && echo untouched || echo EDITED)"
            echo "invented-sentinel: $(grep -cE 'Err[A-Z][A-Za-z]* *=|type [A-Za-z]*Error' "$d/api/api.go" 2>/dev/null)"
            echo "matches-on: $(grep -oE 'errors\.(Is|As)\([^)]*\)' "$d/api/api.go" 2>/dev/null | tr '\n' ' ')"
            ;;
        *)
            echo "go-test: $(cd "$d" && go test -count=1 ./calc/ 2>&1 | tail -1)"
            echo "fn-defined: $(grep -cE 'func (Product|Mode)' "$d/calc/calc.go")"
            echo "test-defined: $(grep -cE 'func (TestProduct|TestMode)' "$d/calc/calc_test.go")"
            echo "fn-body: $(sed -n '/func \(Product\|Mode\)/,/^}/p' "$d/calc/calc.go" | tr '\n' ' ' | tr -s ' ')"
            ;;
        esac
        echo "CONTAMINATION: $(git -C "$REPO" status --porcelain --untracked-files=no -- evals/fixtures | wc -l) tracked repo-fixture files dirty"
    } >> "$OUT/run-$i.txt"

    # never let one run's escape pollute the next
    git -C "$REPO" checkout -- evals/fixtures/ 2>/dev/null
    i=$((i + 1))
done
echo "arm $ARM done: $N runs"
