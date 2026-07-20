#!/bin/sh
# Install workflow files from this repo into the live ~/.claude locations.
# Learnings files (LEARNINGS.md + learnings/*.md) are runtime state owned by
# /new-task runs: seeded only if missing, never overwritten. Use capture.sh
# to bring live changes back here.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/new-task/learnings"

cp "$REPO_DIR"/agents/*.md "$CLAUDE_DIR/agents/"
cp "$REPO_DIR"/commands/*.md "$CLAUDE_DIR/commands/"
# Skills are source-of-truth like agents/commands: always overwritten.
for d in "$REPO_DIR"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    mkdir -p "$CLAUDE_DIR/skills/$name"
    cp "$d"* "$CLAUDE_DIR/skills/$name/"
done

seed() {
    src="$1" dest="$2"
    if [ ! -f "$dest" ]; then
        cp "$src" "$dest"
        echo "seeded: $dest"
    else
        echo "skipped: $dest exists (runtime state; use capture.sh to version it)"
    fi
}

seed "$REPO_DIR/new-task/LEARNINGS.md" "$CLAUDE_DIR/new-task/LEARNINGS.md"
for f in "$REPO_DIR"/new-task/learnings/*.md; do
    [ -e "$f" ] || continue
    seed "$f" "$CLAUDE_DIR/new-task/learnings/$(basename "$f")"
done

# Automated context measurement (2026-07-20 context-compaction proposal,
# measurement items 2+3): a Claude Code Stop hook samples the orchestrator's
# context size + cache state once per turn (gates end turns, so gate
# boundaries are sampled by construction) into ~/.claude/metrics/. Also sets
# the 1h prompt-cache TTL env (no-op on subscription billing; on API keys it
# keeps gate waits under an hour cache-warm) and seeds a `## Compact
# Instructions` block in ~/.claude/CLAUDE.md if none exists — all idempotent.
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/metrics"
cp "$REPO_DIR/hooks/context-metrics.py" "$CLAUDE_DIR/hooks/context-metrics.py"
cp "$REPO_DIR/hooks/context-report.sh"  "$CLAUDE_DIR/hooks/context-report.sh"
chmod +x "$CLAUDE_DIR/hooks/context-metrics.py" "$CLAUDE_DIR/hooks/context-report.sh"

if command -v python3 >/dev/null 2>&1; then
    python3 - "$CLAUDE_DIR" <<'PY' || echo "WARN: settings.json not updated (see above) — register the Stop hook manually"
import json, os, sys
claude_dir = sys.argv[1]
path = os.path.join(claude_dir, "settings.json")
settings = {}
if os.path.isfile(path):
    try:
        settings = json.load(open(path))
    except Exception:
        sys.exit("settings.json is not valid JSON — refusing to touch it")
cmd = os.path.join(claude_dir, "hooks", "context-metrics.py")
changed = []
stop = settings.setdefault("hooks", {}).setdefault("Stop", [])
present = any(h.get("command") == cmd for m in stop for h in m.get("hooks", []))
if not present:
    stop.append({"hooks": [{"type": "command", "command": cmd}]})
    changed.append("Stop hook (context-metrics)")
env = settings.setdefault("env", {})
if "ENABLE_PROMPT_CACHING_1H" not in env:
    env["ENABLE_PROMPT_CACHING_1H"] = "1"
    changed.append("env ENABLE_PROMPT_CACHING_1H=1")
if changed:
    json.dump(settings, open(path, "w"), indent=2)
    print("registered: " + ", ".join(changed) + " -> " + path)
else:
    print("skipped: settings.json already configured (hook + env present)")
PY
else
    echo "skipped: Stop-hook registration (python3 not found)"
fi

if ! grep -q '^## Compact Instructions' "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
    cat >> "$CLAUDE_DIR/CLAUDE.md" <<'EOF'

## Compact Instructions

When compacting, preserve: the run ledger/manifest path and its latest state,
the final route and any escalations, artifact paths (design doc, plan, retro),
the open Must-fix/Should-fix findings, and the current phase + iteration count.
Drop file contents and superseded review reports — they are reconstructible
from the artifacts.
EOF
    echo "seeded: Compact Instructions block -> $CLAUDE_DIR/CLAUDE.md"
else
    echo "skipped: Compact Instructions block exists in $CLAUDE_DIR/CLAUDE.md"
fi

# Install the repo's own pre-commit hook so a commit touching workflow files
# runs the deterministic lint (evals/lint.sh). Only when run inside the repo's
# git checkout; harmless to skip otherwise.
if hooks_dir="$(git -C "$REPO_DIR" rev-parse --git-path hooks 2>/dev/null)"; then
    case "$hooks_dir" in /*) : ;; *) hooks_dir="$REPO_DIR/$hooks_dir" ;; esac
    mkdir -p "$hooks_dir"
    cp "$REPO_DIR/hooks/pre-commit" "$hooks_dir/pre-commit"
    chmod +x "$hooks_dir/pre-commit"
    echo "installed: pre-commit hook -> $hooks_dir/pre-commit"
else
    echo "skipped: pre-commit hook (not a git checkout)"
fi

echo "installed: $(ls "$REPO_DIR"/agents/*.md "$REPO_DIR"/commands/*.md "$REPO_DIR"/skills/*/*.md | wc -l | tr -d ' ') files -> $CLAUDE_DIR"
