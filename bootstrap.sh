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
mkdir -p "$workdir/src"
if ! curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
  | tar -xz -C "$workdir/src" --strip-components=1; then
  echo "could not download $REPO" >&2
  exit 1
fi

if [ ! -f "$workdir/src/install.sh" ]; then
  echo "the download did not contain install.sh" >&2
  exit 1
fi

bash "$workdir/src/install.sh" "$@"
