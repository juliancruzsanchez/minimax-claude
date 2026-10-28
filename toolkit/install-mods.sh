#!/bin/sh
# Install the shared agent mods into Claude Code.
#
#   ~/.minimax-tools/mods/agent-toolkit   the bundle: rules, hooks, skills
#
# The bundle carries both plugin manifests, so the same directory works for
# Claude Code (.claude-plugin) and for MiniMax Code (.minimax-plugin) if it
# is ever installed there. The skills inside point at the shared store in
# ~/.agents/skills, which every agent on this machine already reads.
#
# Running it again is safe: every step replaces what it wrote before.
set -eu

TOOLS="$HOME/.minimax-tools"
BUNDLE="$TOOLS/mods/agent-toolkit"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

[ -d "$BUNDLE" ] || { echo "no bundle at $BUNDLE" >&2; exit 1; }

# --- Claude Code: the bundle as a skills-dir plugin
mkdir -p "$CLAUDE_DIR/skills"
ln -sfn "$BUNDLE" "$CLAUDE_DIR/skills/agent-toolkit"

# --- the shared skill store, so one copy of each skill serves every agent
mkdir -p "$HOME/.agents/skills"
for skill in "$HOME/.agents/skills"/*/; do
  name=$(basename "$skill")
  [ -e "$CLAUDE_DIR/skills/$name" ] || ln -s "$skill" "$CLAUDE_DIR/skills/$name"
done

echo "installed:"
echo "  claude  $CLAUDE_DIR/skills/agent-toolkit"
echo "  skills  $HOME/.agents/skills (shared store)"
