#!/usr/bin/env python3
"""Merge the MiniMax settings into ~/.claude/settings.json.

Everything the file already holds is kept: hooks, permissions, plugins, status
line settings the user chose. Only the MiniMax pieces are written.
"""

import json
import os
import sys

settings_path = sys.argv[1]
policy_path = sys.argv[2]

with open(policy_path, "r", encoding="utf-8") as fh:
    policy = json.load(fh)

try:
    with open(settings_path, "r", encoding="utf-8") as fh:
        settings = json.load(fh)
except (OSError, ValueError):
    settings = {}

models = policy.get("models") or {}
default_model = policy.get("default_model") or "MiniMax-M3"
opus = policy.get("opus") or default_model
sonnet = policy.get("sonnet") or default_model
haiku = policy.get("haiku") or default_model

meta = models.get(default_model) or {}
max_window = max(meta.get("windows") or [512000])
compact = policy.get("compact_window") or int(max_window * 0.8)

options = []
for model_id, model_meta in models.items():
    context = model_meta.get("context", 512000)
    options.append(
        {
            "model": model_id,
            "label": model_id.replace("MiniMax-", ""),
            "description": f"{context // 1000}K context",
        }
    )

env = settings.setdefault("env", {})
env["ANTHROPIC_BASE_URL"] = "https://api.minimax.io/anthropic"
env["ANTHROPIC_MODEL"] = default_model
env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = opus
env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = sonnet
env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = haiku
env["CLAUDE_CODE_MAX_CONTEXT_TOKENS"] = str(max_window)
env["CLAUDE_CODE_AUTO_COMPACT_WINDOW"] = str(compact)
env.setdefault("CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC", "1")
env.setdefault("API_TIMEOUT_MS", "3000000")

settings["model"] = default_model
settings["modelPicker"] = {"options": options, "replaceBuiltInOptions": True}
settings["apiKeyHelper"] = os.path.join(
    os.path.dirname(settings_path), "api-key.sh"
)
settings["theme"] = "custom:minimax"
settings["statusLine"] = {
    "type": "command",
    "command": "sh ~/.claude/statusline.sh",
}

with open(settings_path, "w", encoding="utf-8") as fh:
    json.dump(settings, fh, indent=2)
    fh.write("\n")

print(f"settings written: {settings_path}")
