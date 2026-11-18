#!/usr/bin/env python3
"""The MiniMax key for Claude Code, so no settings file has to carry it.

The Windows port of profile/api-key.sh. macOS keeps the key in the keychain.
Everywhere else it sits in ~/.config/minimax/api_key. MINIMAX_API_KEY wins
over both.
"""

import os
import subprocess
import sys


def keychain_key():
    """The key from the macOS keychain, when that is where we are."""
    if sys.platform != "darwin":
        return ""
    try:
        out = subprocess.run(
            [
                "security",
                "find-generic-password",
                "-a",
                os.environ.get("USER", ""),
                "-s",
                "minimax-api-key",
                "-w",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        return out.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def key_file():
    return os.path.join(os.path.expanduser("~"), ".config", "minimax", "api_key")


def main():
    key = keychain_key()

    if not key:
        path = key_file()
        try:
            with open(path, "r", encoding="utf-8") as fh:
                key = fh.read().strip()
        except OSError:
            key = ""

    if not key:
        key = os.environ.get("MINIMAX_API_KEY", "").strip()

    if not key:
        sys.stderr.write(
            "no MiniMax key found: put it in %s or set MINIMAX_API_KEY\n" % key_file()
        )
        return 1

    sys.stdout.write(key)
    return 0


if __name__ == "__main__":
    sys.exit(main())
