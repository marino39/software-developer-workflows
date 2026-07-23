#!/bin/sh
# Capture the live ~/.claude workflow state back into this repo, so
# self-improvement edits (GATE 4) to agents/commands/skills can be reviewed
# and committed. Review `git diff` after running; nothing is committed for you.
#
# Learnings are intentionally NOT captured: they are local runtime state that
# stays per-machine (everyone starts from the clean seed new-task/LEARNINGS.md).
# See install.sh and README.md.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

for f in "$REPO_DIR"/agents/*.md; do
    cp "$CLAUDE_DIR/agents/$(basename "$f")" "$f"
done
for f in "$REPO_DIR"/commands/*.md; do
    cp "$CLAUDE_DIR/commands/$(basename "$f")" "$f"
done
for f in "$REPO_DIR"/skills/*/*.md; do
    [ -e "$f" ] || continue
    live="$CLAUDE_DIR/skills/$(basename "$(dirname "$f")")/$(basename "$f")"
    if [ -f "$live" ]; then
        cp "$live" "$f"
    fi
done
# Learnings (LEARNINGS.md + learnings/*.md) are deliberately not copied back:
# they are local, per-machine runtime state and must never enter the repo.

cd "$REPO_DIR"
git status --short
