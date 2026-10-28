#!/usr/bin/env bash
# SessionStart: regenerate file index and inject it as session context.
# Works in any project — respects .gitignore, skips node_modules/.git/etc.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INSTALL_DIR="${HOME}/.config/ai-token-saver"
SCRIPT="${INSTALL_DIR}/scripts/file-index.mjs"

# Generate the index (quiet mode, stdout)
index_output=$(node "$SCRIPT" "$ROOT" --stdout --quiet 2>/dev/null || true)

if [[ -z "$index_output" ]]; then
  # Fallback: just output git state if generation fails
  branch="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  echo "Branch: $branch — file index generation failed."
  exit 0
fi

context="Use this file index when searching for files. Read .ai/file-index.md first before using glob/grep to find files — it has brief descriptions of every file in the project.

${index_output}"

# JSON output for Claude Code
jq -n \
  --arg ctx "$context" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
