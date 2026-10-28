#!/usr/bin/env bash
# MiniMax Code setup, for Linux and macOS.
#
#   ./install.sh
#
# Installs Claude Code if it is missing, asks for a MiniMax key, wires
# Claude Code up to MiniMax's API, puts the launcher on your PATH, installs
# the shared mods and schedules a daily model sync.
#
# Nothing here touches the Claude Code binary.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$HOME/.minimax-tools"
PROFILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
KEYFILE="$HOME/.config/minimax/api_key"
SCHEDULE_TAG="# minimax-sync"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }

# --- 1. prerequisites -----------------------------------------------------
say "Checking what is already here"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required (3.9 or newer)" >&2
  exit 1
fi
info "python3 $(python3 --version 2>&1 | cut -d' ' -f2)"

if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
  say "Claude Code is not installed"
  info "It installs with: curl -fsSL https://claude.ai/install.sh | bash"
  read -r -p "Install it now? [y/N] " answer
  case "$answer" in
    [Yy]*) curl -fsSL https://claude.ai/install.sh | bash ;;
    *) echo "Install Claude Code first, then run this again." >&2; exit 1 ;;
  esac
fi
info "claude $(command -v claude || echo "$HOME/.local/bin/claude")"

# --- 2. the MiniMax key ---------------------------------------------------
say "The MiniMax key"

if [ ! -s "$KEYFILE" ] && [ -z "${MINIMAX_API_KEY:-}" ]; then
  read -r -p "MiniMax API key (platform.minimax.io -> API keys): " key
  if [ -z "$key" ]; then
    echo "no key given, stopping" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$KEYFILE")"
  chmod 700 "$(dirname "$KEYFILE")"
  printf '%s' "$key" > "$KEYFILE"
  chmod 600 "$KEYFILE"
  info "stored in $KEYFILE (mode 600)"
fi

if [ ! -s "$KEYFILE" ] && [ -n "${MINIMAX_API_KEY:-}" ]; then
  mkdir -p "$(dirname "$KEYFILE")"
  chmod 700 "$(dirname "$KEYFILE")"
  printf '%s' "$MINIMAX_API_KEY" > "$KEYFILE"
  chmod 600 "$KEYFILE"
  info "stored in $KEYFILE (mode 600)"
fi

if command -v security >/dev/null 2>&1 && [ -s "$KEYFILE" ]; then
  security add-generic-password -a "${USER:-$(id -un)}" -s minimax-api-key \
    -w "$(cat "$KEYFILE")" -U >/dev/null 2>&1 && info "also stored in the macOS keychain" || true
fi

# --- 3. the toolkit and the profile ---------------------------------------
say "Installing the toolkit"

mkdir -p "$TOOLS"
cp -R "$HERE/toolkit/." "$TOOLS/"
chmod +x "$TOOLS/minimax-sync" "$TOOLS/install-mods.sh"
info "$TOOLS"

mkdir -p "$PROFILE"
stamp=$(date +%Y%m%d-%H%M%S)
for file in CLAUDE.md api-key.sh statusline.sh statusline.py; do
  if [ -f "$PROFILE/$file" ]; then
    cp "$PROFILE/$file" "$PROFILE/$file.$stamp.bak"
  fi
  cp "$HERE/profile/$file" "$PROFILE/$file"
done
chmod +x "$PROFILE/api-key.sh" "$PROFILE/statusline.sh" "$PROFILE/statusline.py"
info "$PROFILE (previous files kept as .bak)"

mkdir -p "$HOME/.local/bin"
cp "$HERE/profile/mm" "$HOME/.local/bin/mm"
chmod +x "$HOME/.local/bin/mm"
info "$HOME/.local/bin/mm"

# --- 4. the settings ------------------------------------------------------
say "Pointing Claude Code at MiniMax"

python3 "$HERE/setup/patch-settings.py" "$PROFILE/settings.json" "$TOOLS/models-policy.json"

# --- 5. the shared mods ---------------------------------------------------
say "Installing the shared mods"
"$TOOLS/install-mods.sh"

# --- 6. the daily sync ----------------------------------------------------
say "Scheduling the daily model sync"

if [ "$(uname -s)" = "Darwin" ] && [ "${MINIMAX_SCHEDULE:-launchd}" != "cron" ]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s#/Users/REPLACE_ME#$TOOLS#g" "$HERE/setup/local.minimax-sync.plist" \
    > "$HOME/Library/LaunchAgents/local.minimax-sync.plist"
  launchctl bootout "gui/$(id -u)/local.minimax-sync" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/local.minimax-sync.plist"
  info "launchd job, every morning at 07:23"
else
  cron_line="23 7 * * * $TOOLS/minimax-sync >> $TOOLS/sync.log 2>&1 $SCHEDULE_TAG"
  (crontab -l 2>/dev/null | grep -vF "$SCHEDULE_TAG" || true; echo "$cron_line") | crontab -
  info "cron job, every morning at 07:23"
fi

# --- 7. one sync now, so everything is right from the first minute ---------
say "Reading the model list from MiniMax"
"$TOOLS/minimax-sync" || warn "the sync could not reach MiniMax; run it again later"

say "Done"
info "start it with:  mm"
info "check it with:  mm -p 'who are you?' --output-format json"
info "keep it current: ~/.minimax-tools/minimax-sync"
info "read more:      $TOOLS/README.md"
