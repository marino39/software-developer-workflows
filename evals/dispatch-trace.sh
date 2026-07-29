#!/bin/sh
# Deterministic dispatch trace over agent transcript JSONL files
# (Layer 2 of /workflow-eval). No LLM, no network — same tier as lint.sh,
# context-trace.sh and delegation-trace.sh.
#
# Measures the ONE-SHOT RATE per agent type: the share of dispatched work units
# that returned without the orchestrator having to dispatch the same unit again.
# A re-dispatch is a roundtrip, and a roundtrip costs an orchestrator turn on
# the most expensive seat in the system — far more than the subagent call it
# re-issues (see docs/proposals/2026-07-29-dispatch-underspecification.md). This
# is deliberately the same quantity the user-side cost dashboard reports as
# "1-shot", so a scorecard number is comparable to live telemetry.
#
# For each transcript, walks the tool_use blocks of the transcript's OWN chain
# (scoped by the first assistant entry's agentId, exactly like context-trace.sh
# and delegation-trace.sh) and, per agent type, reports:
#   units    distinct work units dispatched
#   disp     total dispatches (Agent-tool calls + `claude -p` CLI fallbacks)
#   fanout   dispatches of an already-seen unit in the SAME assistant turn —
#            by-design parallel multiplicity (Phase 6's C1/C2/C3 lens reviewers,
#            per-finding skeptics), NOT a roundtrip
#   redisp   dispatches of a unit already dispatched in an EARLIER turn — the
#            roundtrip signal: the orchestrator absorbed a return, re-decided,
#            and sent the same unit back out
#   bounce   returns whose text carries a bounce signature (non-empty
#            open_questions, blocked, cannot proceed, needs clarification) —
#            the agent-side view of the same failure
#   1-shot   units never re-dispatched / units
#
# Work-unit identity is the agent type plus the file paths and step numbers
# named in the spawn prompt (a re-dispatch restates the same target even though
# its prompt now carries the findings); prompts naming neither fall back to a
# digest of the normalized prompt head. Turn boundaries come from the assistant
# entries themselves, which is what separates a parallel fan-out from a
# sequential roundtrip — the workflow requires independent subagents to go out
# "in parallel in a single message", so same-turn siblings are one fan-out.
#
# Usage:
#   evals/dispatch-trace.sh [--detail] <transcript.jsonl> [more.jsonl ...]
#   --detail   also list each re-dispatched unit with its turn numbers
set -eu

DETAIL=0
[ "${1:-}" = "--detail" ] && { DETAIL=1; shift; }
[ $# -ge 1 ] || { echo "usage: $0 [--detail] <transcript.jsonl> [...]" >&2; exit 2; }

DETAIL="$DETAIL" python3 - "$@" <<'PY'
import hashlib, json, os, re, sys

detail = os.environ.get("DETAIL") == "1"
CLI_SPAWN_RE = re.compile(r"\bclaude\s+(-p|--print)\b")
PATH_RE = re.compile(
    r"\b[\w./-]+\.(?:go|md|ts|tsx|js|jsx|py|rs|java|rb|sh|sql|ya?ml|json|toml)\b")
STEP_RE = re.compile(r"\bsteps?\s+(\d+(?:\s*[-–—]\s*\d+)?)", re.I)
# A return that hands work back instead of finishing it. `open_questions: none`
# is the healthy case, so the field's VALUE is inspected rather than pattern-
# matched inline (a lookahead after `\s*` backtracks and matches the `none`).
OQ_RE = re.compile(r"open[_ ]questions?\s*[:\-—]+", re.I)
BOUNCE_RE = re.compile(
    r"\bblocked\b|\bcannot proceed\b|\bneeds? clarification\b"
    r"|\bplan is (?:wrong|blocked)\b",
    re.I)
EMPTY = ("", "none", "n/a", "na", "-", "—")


def is_bounce(text):
    if BOUNCE_RE.search(text):
        return True
    for m in OQ_RE.finditer(text):
        tail = text[m.end():m.end() + 200]
        first = next((ln.strip() for ln in tail.splitlines() if ln.strip()), "")
        if first.lower().strip(".,;:*`_ ") not in EMPTY:
            return True
    return False


def unit_key(agent, prompt):
    """Identity of the work unit a dispatch targets — stable across a re-dispatch
    whose prompt has grown a findings list."""
    paths = sorted(set(PATH_RE.findall(prompt)))
    steps = sorted(set(re.sub(r"\s+", "", s) for s in STEP_RE.findall(prompt)))
    if paths or steps:
        return "%s|%s|%s" % (agent, ",".join(paths), ",".join(steps))
    head = re.sub(r"\s+", " ", prompt.lower()).strip()[:200]
    return "%s|#%s" % (agent, hashlib.sha1(head.encode("utf-8")).hexdigest()[:12])


def text_of(content):
    if isinstance(content, str):
        return content
    out = []
    for blk in content or []:
        if isinstance(blk, dict) and blk.get("type") == "text":
            out.append(blk.get("text") or "")
        elif isinstance(blk, str):
            out.append(blk)
    return "\n".join(out)


fmt = "{:<26} {:<14} {:>5} {:>5} {:>6} {:>6} {:>6} {:>7}"
print(fmt.format("transcript", "agent", "units", "disp", "fanout", "redisp",
                 "bounce", "1-shot"))

for path in sys.argv[1:]:
    turn = 0
    chain = None
    per_agent = {}        # agent -> {"disp","fanout","redisp","bounce"}
    unit_turns = {}       # unit key -> [turn, ...]
    unit_agent = {}       # unit key -> agent
    pending = {}          # tool_use_id -> agent (to attribute a bounce)

    def slot(agent):
        return per_agent.setdefault(
            agent, {"disp": 0, "fanout": 0, "redisp": 0, "bounce": 0})

    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    e = json.loads(line)
                except Exception:
                    continue
                etype = e.get("type")
                if etype not in ("assistant", "user"):
                    continue
                if etype == "assistant":
                    if chain is None:
                        chain = e.get("agentId")
                    if e.get("agentId") != chain:
                        continue
                    turn += 1
                    for blk in ((e.get("message") or {}).get("content") or []):
                        if not isinstance(blk, dict) or blk.get("type") != "tool_use":
                            continue
                        name = blk.get("name") or ""
                        inp = blk.get("input") or {}
                        if name in ("Agent", "Task"):
                            agent = (inp.get("subagent_type")
                                     or inp.get("agentType") or "unspecified")
                            prompt = (inp.get("prompt")
                                      or inp.get("description") or "")
                        elif name == "Bash" and CLI_SPAWN_RE.search(
                                (inp.get("command") or "")):
                            agent = "cli-fallback"
                            prompt = inp.get("command") or ""
                        else:
                            continue
                        key = unit_key(agent, prompt)
                        seen = unit_turns.setdefault(key, [])
                        unit_agent[key] = agent
                        s = slot(agent)
                        s["disp"] += 1
                        if seen:
                            # already dispatched: same turn = by-design fan-out,
                            # earlier turn = roundtrip
                            s["fanout" if seen[-1] == turn else "redisp"] += 1
                        seen.append(turn)
                        if blk.get("id"):
                            pending[blk["id"]] = agent
                else:  # user entry — carries the tool_results
                    if chain is not None and e.get("agentId") not in (None, chain):
                        continue
                    for blk in ((e.get("message") or {}).get("content") or []):
                        if not isinstance(blk, dict) or blk.get("type") != "tool_result":
                            continue
                        agent = pending.pop(blk.get("tool_use_id"), None)
                        if agent and is_bounce(text_of(blk.get("content"))):
                            slot(agent)["bounce"] += 1
    except OSError as ex:
        print("{:<26} ERROR: {}".format(os.path.basename(path)[:26], ex))
        continue

    # a unit is one-shot iff it was never dispatched again in a later turn
    per_agent_units = {}
    for key, turns in unit_turns.items():
        a = unit_agent[key]
        u = per_agent_units.setdefault(a, {"units": 0, "clean": 0})
        u["units"] += 1
        if len(set(turns)) == 1:
            u["clean"] += 1

    base = os.path.basename(path)[:26]
    tot = {"units": 0, "clean": 0, "disp": 0, "fanout": 0, "redisp": 0, "bounce": 0}
    for agent in sorted(per_agent):
        s = per_agent[agent]
        u = per_agent_units.get(agent, {"units": 0, "clean": 0})
        rate = ("{:.0%}".format(u["clean"] / u["units"]) if u["units"] else "-")
        print(fmt.format(base, agent[:14], u["units"], s["disp"], s["fanout"],
                         s["redisp"], s["bounce"], rate))
        base = ""
        for k in ("disp", "fanout", "redisp", "bounce"):
            tot[k] += s[k]
        tot["units"] += u["units"]
        tot["clean"] += u["clean"]
    rate = ("{:.0%}".format(tot["clean"] / tot["units"]) if tot["units"] else "-")
    print(fmt.format(base or "", "TOTAL", tot["units"], tot["disp"], tot["fanout"],
                     tot["redisp"], tot["bounce"], rate))

    if detail:
        for key, turns in sorted(unit_turns.items()):
            if len(set(turns)) > 1:
                print("    redispatched: {} @ turns {}".format(
                    key, ",".join(str(t) for t in turns)))
PY
