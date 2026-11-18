#!/usr/bin/env python3
"""Merge the MiniMax settings into ~/.claude/settings.json.

Everything the file already holds is kept: hooks, permissions, plugins, status
line settings the user chose. Only the MiniMax pieces are written.

The model list keeps both the plain model ids MiniMax serves and the
[512k] / [1m] variants, so /model can offer both a pinned window and the
full one.
"""

import json
import os
import re
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
variants = policy.get("variants") or {}
legacy_pattern = policy.get("legacy_pattern") or r"^MiniMax-M2(\.\d+)?(-highspeed)?$"
legacy_re = re.compile(legacy_pattern)

default_model = policy.get("default_model") or next(iter(models), "MiniMax-M3")
opus = policy.get("opus") or default_model
sonnet = policy.get("sonnet") or default_model
haiku = policy.get("haiku") or default_model


def split_variant(model_id):
    """("MiniMax-M3.1-Flash", "[1m]") for a model id that carries a window."""
    match = re.match(r"^(.*?)(\[[^\]]+\])$", model_id or "")
    if match:
        return match.group(1), match.group(2)
    return model_id or "", ""


def base_model(model_id):
    """The plain model id behind a variant id."""
    base, _ = split_variant(model_id)
    return base if base in models else model_id


def windows_for(model_id):
    """The context windows a model id stands for."""
    base, suffix = split_variant(model_id)
    meta = models.get(base) or {}
    windows = [int(w) for w in (meta.get("windows") or [meta.get("context", 512000)])]
    if suffix:
        for entry in variants.get(base) or []:
            if entry.get("suffix") == suffix:
                return [int(entry.get("context") or windows[-1])]
    return windows


def max_window(model_id):
    return max(windows_for(model_id) or [512000])


def model_list():
    """The plain model ids, each followed by its window variants."""
    listed = []
    for base in models:
        if legacy_re.match(base):
            continue
        listed.append(base)
        for entry in variants.get(base) or []:
            listed.append(base + entry.get("suffix", ""))
    return listed


def options_for(model_ids):
    options = []
    for model_id in model_ids:
        base, suffix = split_variant(model_id)
        window = max_window(model_id)
        options.append(
            {
                "model": model_id,
                "label": base.replace("MiniMax-", "") + suffix,
                "description": f"{window // 1000}K context",
            }
        )
    return options


max_window_for_default = max_window(default_model)
compact = policy.get("compact_window") or int(max_window_for_default * 0.8)

env = settings.setdefault("env", {})
env["ANTHROPIC_BASE_URL"] = "https://api.minimax.io/anthropic"
env["ANTHROPIC_MODEL"] = default_model
env["ANTHROPIC_DEFAULT_OPUS_MODEL"] = opus
env["ANTHROPIC_DEFAULT_SONNET_MODEL"] = sonnet
env["ANTHROPIC_DEFAULT_HAIKU_MODEL"] = haiku
env["CLAUDE_CODE_MAX_CONTEXT_TOKENS"] = str(max_window_for_default)
env["CLAUDE_CODE_AUTO_COMPACT_WINDOW"] = str(compact)
env.setdefault("CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC", "1")
env.setdefault("API_TIMEOUT_MS", "3000000")

settings["model"] = default_model
settings["modelPicker"] = {
    "options": options_for(model_list()),
    "replaceBuiltInOptions": True,
}

profile_dir = os.path.dirname(os.path.abspath(settings_path))


def slash(path):
    return os.path.normpath(path).replace("\\", "/")


if os.name == "nt":
    # Claude Code runs these two through a shell, so the path has to survive
    # both cmd.exe and bash: absolute, forward slashes, quoted.
    settings["apiKeyHelper"] = f'python "{slash(os.path.join(profile_dir, "api-key.py"))}"'
    settings["statusLine"] = {
        "type": "command",
        "command": f'python "{slash(os.path.join(profile_dir, "statusline.py"))}"',
    }
else:
    settings["apiKeyHelper"] = os.path.join(profile_dir, "api-key.sh")
    settings["statusLine"] = {"type": "command", "command": "sh ~/.claude/statusline.sh"}

settings["theme"] = "custom:minimax"

with open(settings_path, "w", encoding="utf-8") as fh:
    json.dump(settings, fh, indent=2)
    fh.write("\n")

print(f"settings written: {settings_path}")
