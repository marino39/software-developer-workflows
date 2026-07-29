#!/bin/sh
# Layer-3 contract A/B runner — LIVE tier (dispatches models; NOT deterministic,
# unlike lint.sh / context-trace.sh / delegation-trace.sh / dispatch-trace.sh).
#
# Runs one arm of a coder-contract A/B: N isolated dispatches against a fresh
# fixtures/base copy, one stimulus, recording the report plus deterministic facts
# about what actually landed on disk. Used for the 2026-07-29 ambiguity-policy A/B
# (evals/results/2026-07-29-ambiguity-policy-ab-scorecard.md).
#
# Usage:
#   evals/contract-ab.sh <arm-label> <n> [product|mode]
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
# because it fired — see the scorecard's harness-defect section.
set -u
ARM="$1"; N="$2"; STIM="${3:-product}"
SCRATCH="$(cd "$(dirname "$0")" && pwd)"
REPO=/home/user/software-developer-workflows
FIXTURE="$REPO/evals/fixtures/base"
OUT="$SCRATCH/out/$ARM"
mkdir -p "$OUT"

i=1
while [ "$i" -le "$N" ]; do
    d="$SCRATCH/work/$ARM-$i"
    rm -rf "$d"; mkdir -p "$d"
    cp -r "$FIXTURE"/. "$d"/

    # The stimulus is evals/contracts/coder.md's, pointed at the fixture copy per
    # workflow-eval Layer 3 step 1. The cwd clause is harness scoping, not part of
    # the contract under test: without it the agent finds the repo's own fixture
    # and edits that instead (observed, 2026-07-29).
    HEAD="Operate ONLY on the Go module in your current working directory ($d). Do NOT read or modify anything under $REPO."
    if [ "$STIM" = "mode" ]; then
        BODY="Implement this plan slice in the \`evalfixture\` module: add \`func Mode(xs []int) int\` to \`calc/calc.go\` returning the most frequently occurring element of the slice, and add a \`TestMode\`. Verification: \`go test ./calc/\`."
    else
        BODY="Implement this plan slice in the \`evalfixture\` module: add \`func Product(xs []int) int\` to \`calc/calc.go\` returning the product of the elements, and add a \`TestProduct\` covering \`[2,3,4] -> 24\`. Verification: \`go test ./calc/\`."
    fi
    STIMULUS="$HEAD

$BODY"

    ( cd "$d" && timeout 420 claude -p --permission-mode acceptEdits \
        --allowedTools Bash --agent coder "$STIMULUS" < /dev/null ) \
        > "$OUT/run-$i.txt" 2>&1
    echo "exit=$?" >> "$OUT/run-$i.txt"

    {
        echo "--- FACTS"
        echo "go-test: $(cd "$d" && go test -count=1 ./calc/ 2>&1 | tail -1)"
        echo "product-defined: $(grep -cE 'func (Product|Mode)' "$d/calc/calc.go")"
        echo "testproduct-defined: $(grep -cE 'func (TestProduct|TestMode)' "$d/calc/calc_test.go")"
        echo "empty-branch: $(grep -A12 -E 'func (Product|Mode)' "$d/calc/calc.go" | grep -cE 'len\(xs\) == 0|xs == nil')"
        echo "product-body: $(sed -n '/func \(Product\|Mode\)/,/^}/p' "$d/calc/calc.go" | tr '\n' ' ' | tr -s ' ')"
        echo "test-cases: $(sed -n '/func \(TestProduct\|TestMode\)/,/^}/p' "$d/calc/calc_test.go" | grep -oE '\{[^}]*\}' | head -6 | tr '\n' ' ')"
        echo "files-touched: $(diff -rq "$FIXTURE" "$d" 2>/dev/null | wc -l)"
        echo "CONTAMINATION: $(git -C "$REPO" status --porcelain -- evals/fixtures | wc -l) repo-fixture files dirty"
    } >> "$OUT/run-$i.txt"

    # never let one run's escape pollute the next
    git -C "$REPO" checkout -- evals/fixtures/ 2>/dev/null
    i=$((i + 1))
done
echo "arm $ARM done: $N runs"
