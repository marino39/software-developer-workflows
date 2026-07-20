#!/bin/sh
# Deterministic summary of the context-metrics samples written by the
# context-metrics.py Stop hook. No LLM, no network. Usage:
#   hooks/context-report.sh [--since YYYY-MM-DD] [--top N]
# Reads $CLAUDE_DIR/metrics/context-metrics.jsonl (default ~/.claude/metrics/).
set -eu

SINCE=""
TOP=10
while [ $# -gt 0 ]; do
    case "$1" in
        --since) SINCE="$2"; shift 2 ;;
        --top)   TOP="$2";   shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

METRICS="${CLAUDE_DIR:-$HOME/.claude}/metrics/context-metrics.jsonl"
[ -f "$METRICS" ] || { echo "context: no metrics ($METRICS missing)"; exit 0; }

SINCE="$SINCE" TOP="$TOP" python3 - "$METRICS" <<'PY'
import json, os, sys
from collections import OrderedDict

since = os.environ.get("SINCE") or ""
top = int(os.environ.get("TOP") or 10)
sessions = OrderedDict()
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    line = line.strip()
    if not line:
        continue
    try:
        s = json.loads(line)
    except Exception:
        continue
    if since and (s.get("ts") or "") < since:
        continue
    key = (s.get("session") or "?", s.get("cwd") or "?")
    sessions.setdefault(key, []).append(s)

if not sessions:
    print("context: no samples" + (f" since {since}" if since else ""))
    sys.exit(0)

rows = []
for (sess, cwd), samples in sessions.items():
    ctxs = [s.get("context_tokens") or 0 for s in samples]
    # A session's first sample is naturally cache-cold; only later cold
    # samples are re-entries (a gate/CI wake that re-paid full input price).
    cold_reentries = sum(1 for s in samples[1:] if s.get("cold"))
    rows.append({
        "session": sess,
        "project": os.path.basename(cwd.rstrip("/")) or cwd,
        "turns": len(samples),
        "max_ctx": max(ctxs),
        "mean_ctx": sum(ctxs) // len(ctxs),
        "cold": cold_reentries,
        "last": samples[-1].get("ts") or "?",
    })

rows.sort(key=lambda r: r["max_ctx"], reverse=True)
shown = rows[:top]
fmt = "{:<10} {:<24} {:>6} {:>10} {:>10} {:>6}  {}"
print(fmt.format("session", "project", "turns", "max-ctx", "mean-ctx", "cold", "last-sample"))
for r in shown:
    print(fmt.format(r["session"], r["project"][:24], r["turns"],
                     f"{r['max_ctx']:,}", f"{r['mean_ctx']:,}", r["cold"], r["last"]))
total_cold = sum(r["cold"] for r in rows)
print(f"-- {len(rows)} session(s), showing top {len(shown)} by max-ctx; "
      f"cold re-entries total: {total_cold}; "
      f"high-water overall: {max(r['max_ctx'] for r in rows):,} tokens")
PY
