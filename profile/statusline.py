#!/usr/bin/env python3
"""The Claude Code status line, in MiniMax's colours.

Claude Code keeps its own theme; this only paints the row it prints at the
bottom of the screen. The model name and the MiniMax label wear the brand
coral, everything else stays in the colours the terminal already uses.
"""

import json
import os
import sys

ACCENT = "\033[38;2;255;97;93m"  # MiniMax coral
DIM = "\033[2m"
RESET = "\033[0m"


def load_state(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def save_state(path, state):
    tmp = f"{path}.tmp.{os.getpid()}"
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(state, fh)
        os.replace(tmp, path)
    except OSError:
        pass


def session_tokens(transcript, state_path):
    """Output tokens so far this session, and the tokens the API spent."""
    state = load_state(state_path)
    if state.get("path") != transcript:
        state = {"path": transcript, "offset": 0, "tokens": 0}
    try:
        size = os.path.getsize(transcript)
    except OSError:
        return state.get("tokens", 0)
    offset = int(state.get("offset") or 0)
    if size < offset:
        offset = 0
        state["tokens"] = 0
    if size == offset:
        return state.get("tokens", 0)
    try:
        with open(transcript, "rb") as fh:
            fh.seek(offset)
            blob = fh.read()
    except OSError:
        return state.get("tokens", 0)
    cut = blob.rfind(b"\n")
    if cut < 0:
        return state.get("tokens", 0)
    blob = blob[: cut + 1]
    state["offset"] = offset + len(blob)
    for raw in blob.splitlines():
        if b'"assistant"' not in raw:
            continue
        try:
            record = json.loads(raw)
        except ValueError:
            continue
        usage = (record.get("message") or {}).get("usage") or {}
        state["tokens"] = state.get("tokens", 0) + int(usage.get("output_tokens") or 0)
    save_state(state_path, state)
    return state["tokens"]


def main():
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        return

    model = (payload.get("model") or {}).get("display_name") or "MiniMax"
    model_id = (payload.get("model") or {}).get("id") or ""
    if model_id.startswith("MiniMax-"):
        model = model_id.replace("MiniMax-", "")

    cost = payload.get("cost") or {}
    context = payload.get("context_window") or {}
    used = context.get("used_percentage")
    if used is None and context.get("used_tokens") and context.get("context_window_size"):
        used = round(
            100 * context["used_tokens"] / context["context_window_size"]
        )

    parts = [f"{ACCENT}MiniMax{RESET}", f"{ACCENT}{model}{RESET}"]

    api_ms = int(cost.get("total_api_duration_ms") or 0)
    tokens = 0
    transcript = payload.get("transcript_path")
    if transcript:
        state_path = os.path.join(
            os.path.dirname(transcript), ".minimax-statusline.json"
        )
        tokens = session_tokens(transcript, state_path)
    if tokens and api_ms:
        rate = tokens / (api_ms / 1000.0)
        parts.append(f"{rate:.1f} tok/s" if rate < 10 else f"{rate:.0f} tok/s")

    if used is not None:
        parts.append(f"{DIM}{used}% ctx{RESET}")
    if cost.get("total_cost_usd"):
        parts.append(f"${float(cost['total_cost_usd']):.4f}")

    print(" | ".join(parts))


if __name__ == "__main__":
    main()
