#!/bin/sh
# The MiniMax key for Claude Code, so no settings file has to carry it.
#
# macOS keeps it in the keychain. Everywhere else it sits in
# ~/.config/minimax/api_key with mode 600. MINIMAX_API_KEY wins over both.
set -eu

file="$HOME/.config/minimax/api_key"
key=""

if command -v security >/dev/null 2>&1; then
  key=$(security find-generic-password -a "${USER:-$(id -un)}" -s minimax-api-key -w 2>/dev/null || true)
fi

if [ -z "$key" ] && [ -r "$file" ]; then
  key=$(cat "$file")
fi

if [ -z "$key" ] && [ -n "${MINIMAX_API_KEY:-}" ]; then
  key="$MINIMAX_API_KEY"
fi

if [ -z "$key" ]; then
  echo "no MiniMax key found: put it in $file or set MINIMAX_API_KEY" >&2
  exit 1
fi

printf '%s' "$key"
