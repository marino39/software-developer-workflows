#!/bin/sh
# Install workflow files from this repo into the live ~/.claude locations.
# LEARNINGS.md is runtime state owned by /new-task runs: it is seeded only if
# missing, never overwritten. Use capture.sh to bring live changes back here.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/new-task"

cp "$REPO_DIR"/agents/*.md "$CLAUDE_DIR/agents/"
cp "$REPO_DIR"/commands/*.md "$CLAUDE_DIR/commands/"

if [ ! -f "$CLAUDE_DIR/new-task/LEARNINGS.md" ]; then
    cp "$REPO_DIR/new-task/LEARNINGS.md" "$CLAUDE_DIR/new-task/"
    echo "seeded: $CLAUDE_DIR/new-task/LEARNINGS.md"
else
    echo "skipped: $CLAUDE_DIR/new-task/LEARNINGS.md exists (runtime state; use capture.sh to version it)"
fi

echo "installed: $(ls "$REPO_DIR"/agents/*.md "$REPO_DIR"/commands/*.md | wc -l | tr -d ' ') files -> $CLAUDE_DIR"
