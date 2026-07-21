#!/bin/sh
# Deterministic orchestrator-context trace over agent transcript JSONL files
# (Layer 2 of /workflow-eval). No LLM, no network — same tier as lint.sh.
#
# For each transcript, walks the assistant turns of the transcript's OWN chain
# — scoped by the first assistant entry's agentId, which keeps the orchestrator
# chain in a main-session transcript and the driver's chain in a subagent
# transcript, excluding nested-subagent traffic either way — and reads their
# `usage` blocks:
#   context_tokens = input + cache_read + cache_creation   (total prompt size)
#   cold           = context > 20k and cache_read < 1k     (full-price re-entry)
# Gates end turns, so a driver's per-turn trajectory samples gate boundaries by
# construction. Cold re-entries exclude each transcript's first sample (a
# session's first turn is cache-cold by nature).
#
# Usage:
#   evals/context-trace.sh [--turns] <transcript.jsonl> [more.jsonl ...]
#   --turns   also print the per-turn trajectory, not just the summary
set -eu

TURNS=0
[ "${1:-}" = "--turns" ] && { TURNS=1; shift; }
[ $# -ge 1 ] || { echo "usage: $0 [--turns] <transcript.jsonl> [...]" >&2; exit 2; }

TURNS="$TURNS" python3 - "$@" <<'PY'
import json, os, sys

show_turns = os.environ.get("TURNS") == "1"
fmt = "{:<28} {:>6} {:>12} {:>12} {:>10} {:>6}"
print(fmt.format("transcript", "turns", "ctx-hiwater", "ctx-mean", "ctx-first", "cold"))
for path in sys.argv[1:]:
    traj = []
    chain = None  # agentId of the transcript's own chain (first assistant entry)
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
                if e.get("type") != "assistant":
                    continue
                if chain is None:
                    chain = e.get("agentId")
                if e.get("agentId") != chain:
                    continue
                u = (e.get("message") or {}).get("usage") or {}
                if "input_tokens" not in u:
                    continue
                inp = int(u.get("input_tokens") or 0)
                cr = int(u.get("cache_read_input_tokens") or 0)
                cc = int(u.get("cache_creation_input_tokens") or 0)
                ctx = inp + cr + cc
                traj.append({"ctx": ctx, "cache_read": cr, "uncached": inp,
                             "cold": ctx > 20000 and cr < 1000})
    except OSError as ex:
        print(f"{os.path.basename(path):<28} ERROR: {ex}")
        continue
    name = os.path.basename(path)[:28]
    if not traj:
        print(fmt.format(name, 0, "-", "-", "-", "-"))
        continue
    ctxs = [t["ctx"] for t in traj]
    cold = sum(1 for t in traj[1:] if t["cold"])
    print(fmt.format(name, len(traj), f"{max(ctxs):,}",
                     f"{sum(ctxs)//len(ctxs):,}", f"{ctxs[0]:,}", cold))
    if show_turns:
        for i, t in enumerate(traj, 1):
            mark = "  COLD" if (t["cold"] and i > 1) else ""
            print(f"    turn {i:>3}: ctx {t['ctx']:>9,}  cache_read {t['cache_read']:>9,}  uncached {t['uncached']:>9,}{mark}")
PY
