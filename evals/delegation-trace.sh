#!/bin/sh
# Deterministic delegation trace over agent transcript JSONL files
# (Layer 2 of /workflow-eval). No LLM, no network — same tier as lint.sh and
# context-trace.sh.
#
# For each transcript, walks the tool_use blocks of the transcript's OWN chain
# (scoped by the first assistant entry's agentId, exactly like
# context-trace.sh) and classifies them:
#   spawns      subagent dispatches: Agent-tool calls (attempts count — a
#               rejected call still shows intent) plus headless-CLI fallback
#               dispatches (`claude -p ...` run via Bash)
#   self-edit   Edit/Write/NotebookEdit performed by the orchestrator itself
#               (workflow artifacts under docs/superpowers/ are excluded —
#               manifests/retros are orchestration mechanics, not delegated work)
#   self-test   Bash commands that run a build/test (go build/test/vet, make,
#               npm/pytest/cargo test) in the orchestrator's own context
#   bash-other  remaining Bash calls (git bookkeeping etc.) — counted only
# The self-edit and self-test columns are the delegation-floor signal: for an
# /iterate or /new-task orchestrator both should be zero (source edits belong
# to coder, build/test execution to test-runner).
#
# Usage:
#   evals/delegation-trace.sh [--detail] <transcript.jsonl> [more.jsonl ...]
#   --detail   also list each spawn type, self-edited path, self-run command
set -eu

DETAIL=0
[ "${1:-}" = "--detail" ] && { DETAIL=1; shift; }
[ $# -ge 1 ] || { echo "usage: $0 [--detail] <transcript.jsonl> [...]" >&2; exit 2; }

DETAIL="$DETAIL" python3 - "$@" <<'PY'
import json, os, re, sys

detail = os.environ.get("DETAIL") == "1"
TEST_RE = re.compile(
    r"\bgo\s+(test|build|vet|run)\b|\bmake\s+(test|check)\b|\bnpm\s+(test|run)\b"
    r"|\bpytest\b|\bcargo\s+(test|build)\b")
CLI_SPAWN_RE = re.compile(r"\bclaude\s+(-p|--print)\b")
ARTIFACT_RE = re.compile(r"docs/superpowers/")
fmt = "{:<28} {:>6} {:>9} {:>9} {:>10}"
print(fmt.format("transcript", "spawns", "self-edit", "self-test", "bash-other"))
for path in sys.argv[1:]:
    spawns, edits, tests, other = [], [], [], 0
    chain = None
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
                for blk in ((e.get("message") or {}).get("content") or []):
                    if not isinstance(blk, dict) or blk.get("type") != "tool_use":
                        continue
                    name = blk.get("name") or ""
                    inp = blk.get("input") or {}
                    if name in ("Agent", "Task"):
                        spawns.append(inp.get("subagent_type")
                                      or inp.get("agentType") or "unspecified")
                    elif name in ("Edit", "Write", "NotebookEdit"):
                        p = inp.get("file_path") or inp.get("notebook_path") or "?"
                        if not ARTIFACT_RE.search(p):
                            edits.append(p)
                    elif name == "Bash":
                        cmd = (inp.get("command") or "").strip()
                        if CLI_SPAWN_RE.search(cmd):
                            spawns.append("cli-fallback")
                        elif TEST_RE.search(cmd):
                            tests.append(cmd[:120])
                        else:
                            other += 1
    except OSError as ex:
        print(f"{os.path.basename(path):<28} ERROR: {ex}")
        continue
    name = os.path.basename(path)[:28]
    print(fmt.format(name, len(spawns), len(edits), len(tests), other))
    if detail:
        for s in spawns:
            print(f"    spawn: {s}")
        for p in edits:
            print(f"    self-edit: {p}")
        for c in tests:
            print(f"    self-test: {c}")
PY
