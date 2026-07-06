#!/bin/sh
# Capture the live ~/.claude workflow state back into this repo, so
# self-improvement edits (GATE 4) and appended learnings can be reviewed
# and committed. Review `git diff` after running; nothing is committed for you.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

for f in "$REPO_DIR"/agents/*.md; do
    cp "$CLAUDE_DIR/agents/$(basename "$f")" "$f"
done
for f in "$REPO_DIR"/commands/*.md; do
    cp "$CLAUDE_DIR/commands/$(basename "$f")" "$f"
done
cp "$CLAUDE_DIR/new-task/LEARNINGS.md" "$REPO_DIR/new-task/LEARNINGS.md"
mkdir -p "$REPO_DIR/new-task/learnings"
for f in "$CLAUDE_DIR"/new-task/learnings/*.md; do
    [ -e "$f" ] || continue
    cp "$f" "$REPO_DIR/new-task/learnings/$(basename "$f")"
done

cd "$REPO_DIR"
git status --short
