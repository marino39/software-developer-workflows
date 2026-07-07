#!/bin/sh
# Deterministic workflow lint (Layer 1 of /workflow-eval). No LLM, no network —
# safe to run from a git hook or CI on every workflow modification.
#
# Checks the instruction files (commands/, agents/, skills/) for internal
# consistency. Exits 0 if all checks pass, 1 if any fail. Prints one line per
# check plus offending refs on failure.
#
# Repo root is derived from this script's location (evals/lint.sh -> repo root).
set -eu

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

fail=0
pass() { printf 'PASS  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }

# --- Check 1: reference integrity ------------------------------------------
# Every non-superpowers skill referenced in commands/ or agents/ must exist as
# skills/<name>/SKILL.md. (superpowers:* are external and carry a ':', so the
# patterns below never capture them.)
missing_skills=""
refs="$(grep -rhoE '`[a-z][a-z0-9-]+` skill|skills/[a-z][a-z0-9-]+' commands agents 2>/dev/null \
        | grep -oE '[a-z][a-z0-9-]+' \
        | grep -vxE 'skill|skills' \
        | sort -u || true)"
for name in $refs; do
    [ -f "skills/$name/SKILL.md" ] || missing_skills="$missing_skills $name"
done
if [ -n "$missing_skills" ]; then
    bad "reference integrity: skill(s) referenced but not found:$missing_skills"
else
    pass "reference integrity (skills referenced all exist)"
fi

# Every agent file referenced by name must exist. Agents are a closed set; this
# guards against deleting an agent file while a command/agent still names it.
missing_agents=""
agent_refs="$(grep -rhoE '`(architect|coder|debugger|researcher|reviewer|searcher|test-runner)`' \
              commands agents 2>/dev/null | tr -d '`' | sort -u || true)"
for name in $agent_refs; do
    [ -f "agents/$name.md" ] || missing_agents="$missing_agents $name"
done
if [ -n "$missing_agents" ]; then
    bad "reference integrity: agent(s) referenced but not found:$missing_agents"
else
    pass "reference integrity (agents referenced all exist)"
fi

# --- Check 2: route/tier consistency (commands/new-task.md) -----------------
# The Proposition #4 invariants: an escalated route must void auto-approval and
# be barred from the reduced tier, and the route must be declared monotonic.
NT="commands/new-task.md"
c2=0
grep -qiE 'monotonic|may only escalate' "$NT" || { c2=1; }
# reduced tier must exclude a route escalated after Phase 0
grep -E 'reduced' "$NT" | grep -qiE 'not escalated' || { c2=1; }
# GATE 3 auto-approve must be gated on the route not being escalated
grep -E 'auto-approve' "$NT" | grep -qiE 'route (was )?not escalated' || { c2=1; }
if [ "$c2" -eq 0 ]; then
    pass "route/tier consistency (monotonic route; escalation voids auto-approve & reduced tier)"
else
    bad "route/tier consistency: a Proposition #4 guard is missing in $NT"
fi

# --- Check 3: phase completeness -------------------------------------------
# Review phases must carry an iteration cap, and the escalation ladder must exist.
caps="$(grep -cE 'max [0-9]+ iterations' "$NT" || true)"
c3=0
[ "${caps:-0}" -ge 4 ] || c3=1                       # Phases 2, 4, 6, 6.5
grep -qE '^## Escalation ladder' "$NT" || c3=1
if [ "$c3" -eq 0 ]; then
    pass "phase completeness (iteration caps present; escalation ladder present)"
else
    bad "phase completeness: expected >=4 iteration caps (found ${caps:-0}) and an Escalation ladder section in $NT"
fi

# --- Check 4: gate-format consistency --------------------------------------
# The four-section gate summary contract must be defined.
c4=0
for section in 'Results' 'Key decisions' 'Deviations' 'Next'; do
    grep -qE "\*\*$section" "$NT" || c4=1
done
if [ "$c4" -eq 0 ]; then
    pass "gate-format consistency (Results / Key decisions / Deviations / Next all defined)"
else
    bad "gate-format consistency: a gate summary section is missing in $NT"
fi

# --- Check 5: agent contracts (ACI) ----------------------------------------
# Every agent is a tool: it must declare an Input contract and an Output
# contract, and the Output contract must list >=1 backticked field and a Role.
bad_contracts=""
for f in agents/*.md; do
    [ -e "$f" ] || continue
    grep -qE '^## Input contract'  "$f" || { bad_contracts="$bad_contracts ${f}(no-input)"; continue; }
    grep -qE '^## Output contract' "$f" || { bad_contracts="$bad_contracts ${f}(no-output)"; continue; }
    # within the Output contract section: at least one `field` bullet and a Role line
    out="$(awk '/^## Output contract/{c=1;next} /^## /{c=0} c' "$f")"
    printf '%s' "$out" | grep -qE '^- `[a-z][a-z0-9_]*`' || { bad_contracts="$bad_contracts ${f}(no-field)"; continue; }
    printf '%s' "$out" | grep -qE '^Role:' || bad_contracts="$bad_contracts ${f}(no-role)"
done
if [ -n "$bad_contracts" ]; then
    bad "agent contracts: malformed/missing:$bad_contracts"
else
    pass "agent contracts (all agents declare Input + Output contract, fields, Role)"
fi

# --- Check 6: complexity ledger well-formed --------------------------------
# The complexity budget: every accreted construct must name the failure it
# prevents and its source. Enforce that each ledger table row has a non-empty
# Prevents (col 2) and Source (col 3). Completeness is a review discipline, not
# lintable.
LEDGER="evals/complexity-ledger.md"
if [ ! -f "$LEDGER" ]; then
    bad "complexity ledger: $LEDGER missing"
else
    bad_rows="$(awk -F'|' '
        /^\|/ && !/Construct/ && !/---/ {
            p=$3; s=$4;
            gsub(/^[ \t]+|[ \t]+$/, "", p); gsub(/^[ \t]+|[ \t]+$/, "", s);
            if (p !~ /[A-Za-z0-9]/ || s !~ /[A-Za-z0-9]/) c++;
        }
        END { print c+0 }
    ' "$LEDGER")"
    if [ "$bad_rows" -eq 0 ]; then
        pass "complexity ledger (every row has Prevents + Source)"
    else
        bad "complexity ledger: $bad_rows row(s) missing Prevents or Source in $LEDGER"
    fi
fi

# --- Check 7: learnings bullets tagged + evidence-linked --------------------
# Every lesson bullet (date-prefixed; the header "Rules" bullets are not) must
# carry >=1 trigger tag `[tag]` and a `src:` evidence ref, so Phase 0 retrieval
# is tag-scoped and overrides are auditable.
bad_bullets=""
for f in new-task/LEARNINGS.md new-task/learnings/*.md; do
    [ -e "$f" ] || continue
    n="$(awk '
        /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ {
            if ($0 !~ /\[[a-z][a-z0-9-]*\]/ || $0 !~ /src:/) c++;
        }
        END { print c+0 }
    ' "$f")"
    [ "$n" -eq 0 ] || bad_bullets="$bad_bullets ${f}($n)"
done
if [ -z "$bad_bullets" ]; then
    pass "learnings bullets (every dated bullet has a tag + src:)"
else
    bad "learnings bullets: malformed (missing tag or src:):$bad_bullets"
fi

# ---------------------------------------------------------------------------
if [ "$fail" -eq 0 ]; then
    printf 'workflow-lint: all checks passed\n'
else
    printf 'workflow-lint: FAILURES above\n'
fi
exit "$fail"
