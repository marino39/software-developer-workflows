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
