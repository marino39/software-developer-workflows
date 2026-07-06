#!/bin/sh
# Install workflow files from this repo into the live ~/.claude locations.
# Learnings files (LEARNINGS.md + learnings/*.md) are runtime state owned by
# /new-task runs: seeded only if missing, never overwritten. Use capture.sh
# to bring live changes back here.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/new-task/learnings"

cp "$REPO_DIR"/agents/*.md "$CLAUDE_DIR/agents/"
cp "$REPO_DIR"/commands/*.md "$CLAUDE_DIR/commands/"

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

echo "installed: $(ls "$REPO_DIR"/agents/*.md "$REPO_DIR"/commands/*.md | wc -l | tr -d ' ') files -> $CLAUDE_DIR"
