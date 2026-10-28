#!/bin/sh
# Install the shared agent mods into Claude Code.
#
#   ~/.minimax-tools/mods/agent-toolkit   the bundle: rules, hooks, themes
#   ~/.minimax-tools/skills                the shared skill store
#
# The skills are copied into ~/.agents/skills, the store every agent on the
# machine reads, and linked into Claude Code's own skills directory. The
# bundle carries both plugin manifests, so the same folder works for Claude
# Code and for MiniMax Code.
#
# Running it again is safe: every step replaces what it wrote before.
set -eu

TOOLS="$HOME/.minimax-tools"
BUNDLE="$TOOLS/mods/agent-toolkit"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STORE="$HOME/.agents/skills"

[ -d "$BUNDLE" ] || { echo "no bundle at $BUNDLE" >&2; exit 1; }

# --- the shared skill store
mkdir -p "$STORE"
if [ -d "$TOOLS/skills" ]; then
  for skill in "$TOOLS"/skills/*/; do
    [ -d "$skill" ] || continue
    name=$(basename "$skill")
    [ -e "$STORE/$name" ] || cp -R "$skill" "$STORE/$name"
  done
fi

# --- Claude Code reads its own skills directory
mkdir -p "$CLAUDE_DIR/skills"
for skill in "$STORE"/*/; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  [ -e "$CLAUDE_DIR/skills/$name" ] || ln -s "$skill" "$CLAUDE_DIR/skills/$name"
done

# --- the bundle itself, as a skills-dir plugin
ln -sfn "$BUNDLE" "$CLAUDE_DIR/skills/agent-toolkit"

# --- the themes, so /theme lists them next to the built-in ones
if [ -d "$BUNDLE/themes" ]; then
  mkdir -p "$CLAUDE_DIR/themes"
  for theme in "$BUNDLE"/themes/*.json; do
    [ -f "$theme" ] || continue
    cp "$theme" "$CLAUDE_DIR/themes/$(basename "$theme")"
  done
fi

echo "installed:"
echo "  claude  $CLAUDE_DIR/skills/agent-toolkit"
echo "  themes  $CLAUDE_DIR/themes"
echo "  skills  $STORE (shared store, $(ls -1 "$STORE" | wc -l | tr -d ' ') skills)"
