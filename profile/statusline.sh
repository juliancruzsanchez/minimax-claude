#!/bin/sh
# The status line Claude Code runs.
#
# Orca's bridge runs first when it is installed, so anything watching the
# Claude Code row keeps working. Then our own row prints.
payload=$(cat)

if [ -x "$HOME/.orca/agent-hooks/claude-statusline.sh" ]; then
  printf '%s' "$payload" | "$HOME/.orca/agent-hooks/claude-statusline.sh" >/dev/null 2>&1 || :
fi

printf '%s' "$payload" | python3 "$HOME/.claude/statusline.py"
