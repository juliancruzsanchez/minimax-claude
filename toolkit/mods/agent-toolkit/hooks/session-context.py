#!/usr/bin/env python3
"""SessionStart: regenerate the file index and inject it as session context.

The Windows port of session-context.sh: same job, without bash and without
jq. Works in any project, respects .gitignore and skips node_modules, .git
and the rest.
"""

import json
import os
import subprocess
import sys

ROOT = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
INSTALL_DIR = os.path.join(os.path.expanduser("~"), ".config", "ai-token-saver")
SCRIPT = os.path.join(INSTALL_DIR, "scripts", "file-index.mjs")


def git_branch(root):
    """The branch the project is on, for the fallback message."""
    try:
        out = subprocess.run(
            ["git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        branch = out.stdout.strip()
        if out.returncode == 0 and branch:
            return branch
    except (OSError, subprocess.SubprocessError):
        pass
    return "unknown"


def index_output():
    """The file index, when the indexer is installed."""
    if not os.path.isfile(SCRIPT):
        return ""
    try:
        out = subprocess.run(
            ["node", SCRIPT, ROOT, "--stdout", "--quiet"],
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return out.stdout.strip() if out.returncode == 0 else ""


def main():
    index = index_output()
    if not index:
        context = f"Branch: {git_branch(ROOT)} - file index generation failed."
    else:
        context = (
            "Use this file index when searching for files. Read .ai/file-index.md "
            "first before using glob/grep to find files, it has brief descriptions "
            "of every file in the project.\n\n" + index
        )

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": context,
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
