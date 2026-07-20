#!/usr/bin/env python3
"""Claude Code Stop hook: sample the orchestrator's context size once per turn.

Registered by install.sh in ~/.claude/settings.json (hooks.Stop). On every
turn end (gates end turns, so gate boundaries are sampled by construction) it
reads the session transcript's LAST main-chain assistant message and appends
one JSONL line to ~/.claude/metrics/context-metrics.jsonl:

  context_tokens  = input + cache_read + cache_creation  (total prompt size)
  cold            = context > 20k and cache_read < 1k    (full-price re-entry)

Subagent (sidechain) turns are excluded — this measures the orchestrator only.
The hook must never block the session: every failure path is silent, exit 0.
"""
import datetime
import json
import os
import sys


def main():
    try:
        hook = json.load(sys.stdin)
    except Exception:
        return
    transcript = hook.get("transcript_path") or ""
    if not transcript or not os.path.isfile(transcript):
        return

    last = None
    try:
        with open(transcript, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except Exception:
                    continue
                if entry.get("isSidechain"):
                    continue
                if entry.get("type") != "assistant":
                    continue
                usage = (entry.get("message") or {}).get("usage") or {}
                if "input_tokens" in usage:
                    last = usage
    except Exception:
        return
    if not last:
        return

    uncached = int(last.get("input_tokens") or 0)
    cache_read = int(last.get("cache_read_input_tokens") or 0)
    cache_creation = int(last.get("cache_creation_input_tokens") or 0)
    output = int(last.get("output_tokens") or 0)
    context = uncached + cache_read + cache_creation

    sample = {
        "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "session": (hook.get("session_id") or "")[:8],
        "cwd": hook.get("cwd") or "",
        "event": hook.get("hook_event_name") or "Stop",
        "context_tokens": context,
        "uncached_input": uncached,
        "cache_read": cache_read,
        "cache_creation": cache_creation,
        "output": output,
        "cold": bool(context > 20000 and cache_read < 1000),
    }

    metrics_dir = os.path.join(
        os.environ.get("CLAUDE_DIR") or os.path.join(os.path.expanduser("~"), ".claude"),
        "metrics",
    )
    try:
        os.makedirs(metrics_dir, exist_ok=True)
        with open(os.path.join(metrics_dir, "context-metrics.jsonl"), "a", encoding="utf-8") as f:
            f.write(json.dumps(sample, separators=(",", ":")) + "\n")
    except Exception:
        return


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
