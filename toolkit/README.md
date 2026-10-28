# MiniMax Code

Claude Code's terminal agent, running on MiniMax's models, wearing MiniMax's
name. Nothing here touches the Claude Code binary.

## What runs

| Command | What it is |
|---|---|
| `mm` | Claude Code pointed at MiniMax, with the profile and the key wired |
| `claude` | The same program; the profile in `~/.claude` already does this |
| `~/.minimax-tools/minimax-sync` | Keeps every agent's model list current |

The key lives in the macOS keychain under the service `minimax-api-key`, with
`~/.config/minimax/api_key` (mode 600) as the fallback. Claude Code reads it
through `~/.claude/api-key.sh`, so no settings file carries a secret.

## The model wiring

Claude Code talks to `https://api.minimax.io/anthropic`, MiniMax's
Anthropic-compatible endpoint. Two things bite otherwise:

- **Use the exact model id.** MiniMax answers an unknown id with
  `MiniMax-M3.1-Flash`. An alias such as `MiniMax-M3[1m]` is not a MiniMax id,
  so the request quietly lands on the Flash model.
- **Declare the context window.** Claude Code assumes 200,000 tokens for a
  model it does not know and compacts early. `CLAUDE_CODE_MAX_CONTEXT_TOKENS`
  (1,000,000) and `CLAUDE_CODE_AUTO_COMPACT_WINDOW` (800,000) give the
  session the window MiniMax actually serves — both models were measured at
  900,000 input tokens.

## The sync tool

```bash
minimax-sync              # apply the list MiniMax serves
minimax-sync --check      # exit 1 when something has drifted
minimax-sync --dry-run    # show the changes
minimax-sync --verify     # ask the API for a token on every model
minimax-sync --only mcode # pick the targets: mcode, claude, grok
```

It reads the model list from MiniMax and writes it into:

- `~/.claude/settings.json` — the model, the role mappings, the picker, the
  context window
- `~/.minimax/config.yaml` — MiniMax Code's provider block, model order and
  whitelist
- `~/.grok/config.toml` — the model blocks (opt in with `--only grok`)

`models-policy.json` beside it decides which models are offered, which one is
the default, and which role each one fills. Models matching the legacy pattern
(MiniMax-M2 and older) are still served by MiniMax, but the profile does not
offer them.

A launchd job runs the sync every morning at 07:23:
`launchctl kickstart -k gui/$(id -u)/local.minimax-sync`.

## The importable bundle

`mods/agent-toolkit` holds the shared setup: the global rules, the
session-context hook, the clauditor hook and the skill store. It carries both
plugin manifests, so the same directory loads in Claude Code
(`.claude-plugin`) and in MiniMax Code (`.minimax-plugin`).

```bash
install-mods.sh           # link it into Claude Code as agent-toolkit@skills-dir
```

The skills inside are links into `~/.agents/skills`, the store every agent on
this machine reads, so a skill written once shows up in all of them.

## The identity and the row

`~/.claude/CLAUDE.md` tells the agent who it is, so it introduces itself as
MiniMax Code. `~/.claude/statusline.sh` prints the bottom row: the MiniMax
label and the model name in MiniMax coral, the context share and the cost in
the terminal's own colours. Claude Code keeps its own theme; only the row is
painted.

## Files

```
~/.minimax-tools/
  minimax-sync          the model sync tool
  models-policy.json    which models to offer, and what fills each role
  install-mods.sh       install the bundle
  mods/agent-toolkit/   the importable bundle
~/.claude/CLAUDE.md         the identity
~/.claude/statusline.sh     the row
~/.claude/statusline.py     the row's contents
~/.claude/api-key.sh        the key, for Claude Code
~/.local/bin/mm             the launcher
```
