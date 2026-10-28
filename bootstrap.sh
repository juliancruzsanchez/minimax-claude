#!/usr/bin/env bash
# MiniMax Code, installed in one line.
#
#   curl -fsSL https://raw.githubusercontent.com/juliancruzsanchez/minimax-code-setup/main/bootstrap.sh | bash
#
# Fetches the repository, then runs its installer. Safe to run twice.
set -euo pipefail

REPO="juliancruzsanchez/minimax-code-setup"
BRANCH="main"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

echo "MiniMax Code: fetching $REPO"
if ! curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
  | tar -xz -C "$workdir"; then
  echo "could not download $REPO" >&2
  exit 1
fi

exec bash "$workdir/$REPO/install.sh" "$@"
