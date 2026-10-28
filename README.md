# MiniMax Code

Claude Code's terminal agent, running on MiniMax's models, under MiniMax's
name. Works on Linux and macOS. Nothing here patches the Claude Code binary.

What you get:

- `mm` — Claude Code pointed at MiniMax's API. The agent introduces itself as
  MiniMax Code and runs on `MiniMax-M3.1-Flash` by default (1M tokens of
  context), with `MiniMax-M3` available as the deeper model.
- A status row at the bottom of the screen: `MiniMax | M3.1-Flash | 63 tok/s |
  14% ctx`, with MiniMax's coral on the label and model name and Claude Code's
  own theme for everything else.
- Two extra themes for `/theme`: **MiniMax** (Claude Code's own dark theme with
  the orange swapped for MiniMax's pink/red) and **MCode** (MiniMax Code's
  dark slate and sky blue).
- A daily job that reads MiniMax's model list and keeps your settings current
  with whatever MiniMax is serving.
- A shared skill store, so a skill written once is available to every agent on
  the machine.

## Install

You need a MiniMax API key (platform.minimax.io → API keys) and Claude Code.

### One line

```bash
curl -fsSL https://raw.githubusercontent.com/juliancruzsanchez/minimax-code-setup/main/bootstrap.sh | bash
```

### One line, for an agent

Paste this into Claude Code, Grok Build, Codex or any other agent:

```
Install the MiniMax Code setup on this machine. Run exactly:

  curl -fsSL https://raw.githubusercontent.com/juliancruzsanchez/minimax-code-setup/main/bootstrap.sh | bash

It asks for a MiniMax API key, points Claude Code at MiniMax's API, installs the
shared skills and schedules a daily model sync. Show me what it will change
before running it, never print the key back, and tell me when it is done.
```

### From a download

```bash
unzip minimax-code-setup.zip
cd minimax-code-setup
./install.sh
```

The installer:

1. offers to install Claude Code if it is missing;
2. asks for your MiniMax key and stores it in `~/.config/minimax/api_key` with
   mode 600 (on macOS it also goes in the keychain);
3. copies the toolkit to `~/.minimax-tools` and the profile files to `~/.claude`
   (anything already there is kept as a `.bak` file);
4. merges the MiniMax settings into `~/.claude/settings.json`, leaving your
   hooks, permissions and plugins alone;
5. installs the shared skills and the mod bundle;
6. schedules the daily sync — a launchd job on macOS, a cron entry on Linux;
7. runs one sync straight away.

Then:

```bash
mm -p "who are you?" --output-format json
```

You should see MiniMax Code, and a `MiniMax-M3` model with a 1,000,000 token
window.

If `$HOME/.local/bin` is not on your PATH, add it:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc   # Linux
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc    # macOS
```

## Themes

Claude Code keeps its own theme. Two more come with this setup, both under
`~/.claude/themes`:

| Theme | What it is |
|---|---|
| **MiniMax** | Claude Code's dark theme exactly, with the orange swapped for MiniMax's pink/red (`#ff615d`). The default. |
| **MCode** | MiniMax Code's look: dark slate (`#2a2e3a`) with sky blue accents, sampled from its own splash screen. |

Pick one with `/theme` inside Claude Code, or set it in
`~/.claude/settings.json`:

```json
"theme": "custom:minimax"
```

A theme file is small:

```json
{
  "name": "MiniMax",
  "base": "dark",
  "overrides": { "claude": "rgb(255,97,93)" }
}
```

`base` is one of Claude Code's built-in themes, and `overrides` replaces only
the colours you name.

## Keeping it current

```bash
~/.minimax-tools/minimax-sync            # apply what MiniMax serves
~/.minimax-tools/minimax-sync --check    # exit 1 when something has drifted
~/.minimax-tools/minimax-sync --dry-run  # show what would change
~/.minimax-tools/minimax-sync --verify   # ask the API for a token on every model
```

It writes the model list into `~/.claude/settings.json` and, if you have MiniMax
Code installed, `~/.minimax/config.yaml`. `models-policy.json` beside it decides
which models are offered, which one is the default, and which model fills each
role. Models matching the legacy pattern (MiniMax-M2 and older) are still served
by MiniMax, but the profile does not offer them.

The daily job runs it at 07:23 and writes to `~/.minimax-tools/sync.log`.

## Two things that bite

**Use the exact model id.** MiniMax answers a model name it does not know with
`MiniMax-M3.1-Flash`. An alias such as `MiniMax-M3[1m]` is not a MiniMax id, so
the request quietly lands on the Flash model instead of the one you asked for.

**The context window has to be declared.** Claude Code assumes 200,000 tokens
for a model it does not know and starts compacting early. The setup sets
`CLAUDE_CODE_MAX_CONTEXT_TOKENS` to 1,000,000 and compacts at 800,000, which is
inside what MiniMax actually serves (both models were measured at 900,000 input
tokens).

## Files it touches

```
~/.minimax-tools/
  minimax-sync           the model sync tool
  models-policy.json     which models to offer, and what fills each role
  install-mods.sh        install the shared mods
  skills/                the shared skill store
  mods/agent-toolkit/    the bundle: global rules and hooks
~/.claude/CLAUDE.md          the identity
~/.claude/statusline.sh      the row
~/.claude/statusline.py      the row's contents
~/.claude/api-key.sh         the key, for Claude Code
~/.local/bin/mm              the launcher
~/.config/minimax/api_key    your key, mode 600
```

Nothing in `~/.claude/settings.json` holds the key: Claude Code reads it through
`apiKeyHelper`, which calls `~/.claude/api-key.sh`.

## The mod bundle

`~/.minimax-tools/mods/agent-toolkit` holds the global rules (the browser
automation note and the temp-file policy) and the session-context hook, with
both plugin manifests so the same folder loads in Claude Code and MiniMax Code.
It appears in Claude Code as `agent-toolkit@skills-dir`.

The skills live in `~/.agents/skills`, the store every agent on the machine
reads. Write a skill once and it is available to all of them.

## Removing it

```bash
rm -rf ~/.minimax-tools
rm -f ~/.local/bin/mm ~/.claude/statusline.sh ~/.claude/statusline.py
```

Then take the MiniMax pieces back out of `~/.claude/settings.json` — the `env`
block, `apiKeyHelper`, `modelPicker` and the `statusLine` entry. Files that
were replaced during install are still there as `.bak` files next to them.

On macOS, remove the scheduled job with:

```bash
launchctl bootout gui/$(id -u)/local.minimax-sync
rm ~/Library/LaunchAgents/local.minimax-sync.plist
```

On Linux, remove the cron line with:

```bash
crontab -l | grep -v 'minimax-sync' | crontab -
```

## If something is wrong

- **The key is not found.** `~/.claude/api-key.sh` prints the key or explains
  what is missing. It reads the macOS keychain, then `~/.config/minimax/api_key`,
  then `MINIMAX_API_KEY`.
- **The models look wrong.** `~/.minimax-tools/minimax-sync --check` says what
  has drifted and what it would change.
- **Claude Code still talks to Anthropic.** Check that `ANTHROPIC_BASE_URL` is
  `https://api.minimax.io/anthropic` in `~/.claude/settings.json`, and that
  `mm` is on your PATH.
