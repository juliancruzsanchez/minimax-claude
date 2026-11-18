# MiniMax Code

Claude Code's terminal agent, running on MiniMax's models, under MiniMax's
name. Works on Linux, macOS and Windows. Nothing here patches the Claude Code
binary.

What you get:

- `mm` — Claude Code pointed at MiniMax's API. The agent introduces itself as
  MiniMax Code and runs on `MiniMax-M3.1-Flash` by default (1M tokens of
  context), with `MiniMax-M3` available as the deeper model.
- A choice of context windows: the model list offers `MiniMax-M3.1-Flash`
  (512K) next to `MiniMax-M3.1-Flash[1m]` (1M), so `/model` can pick either.
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

### Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Or, from a download, in a PowerShell window:

```powershell
.\bootstrap.ps1
```

The installer asks for the key, or takes it from `-ApiKey`, from
`MINIMAX_API_KEY`, or from the key Claude Code already uses. It copies the
toolkit to `%USERPROFILE%\.minimax-tools`, the profile files to
`%USERPROFILE%\.claude` (anything already there is kept as a `.bak` file),
merges the MiniMax settings into `%USERPROFILE%\.claude\settings.json`, puts
`mm.cmd` in `%USERPROFILE%\.local\bin` and adds that folder to your PATH,
installs the shared skills and the mod bundle, and schedules the daily sync
as a Windows scheduled task at 07:23.

Then:

```powershell
mm -p "who are you?" --output-format json
```

The toolkit carries the Unix hook file, and `install-mods.ps1` writes the
Windows one into the installed bundle. If you update the toolkit later, run
`install-mods.ps1` again, or the SessionStart hook goes back to calling the
bash script and errors on every start.

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

## Picking a model

The `/model` menu is built from the role models in the `env` block, not from
a list of models in the settings file. Claude Code 2.1 has no `modelPicker`
setting, so writing one changes nothing. The setup therefore points the three
roles at three different models, and the menu offers all of them:

| Role | Model | Window |
|---|---|---|
| default | `MiniMax-M3.1-Flash[1m]` | 1M |
| Opus | `MiniMax-M3[1m]` | 1M |
| Sonnet | `MiniMax-M3.1-Flash[1m]` | 1M |
| Haiku | `MiniMax-M3.1-Flash` | 512K |

Pick the Haiku row for the 512K window, the default or Sonnet row for 1M.
The roles are set in `models-policy.json`.

`availableModels` and `modelOverrides` are the real settings keys, but they
work the other way around: `availableModels` is an allowlist of Claude Code's
own model ids, and `modelOverrides` maps those ids to a provider id, which is
how Bedrock and Vertex are reached. Mapping Claude's ids onto MiniMax ids
would make the menu show Claude names, not MiniMax ones.

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
`MiniMax-M3.1-Flash`. The plain ids are `MiniMax-M3` and `MiniMax-M3.1-Flash`.

**The context window has to be declared.** Claude Code assumes 200,000 tokens
for a model it does not know and starts compacting early. The setup declares
`CLAUDE_CODE_MAX_CONTEXT_TOKENS` (512,000 by default) and compacts at 80% of
it, which is inside what MiniMax actually serves (both models were measured at
900,000 input tokens).

**`[1m]` is a Claude Code convention, `[512k]` is not a thing.** Claude Code
reads a trailing `[1m]` on a model id as "give this one the million token
window", and it sends the plain id to the API. The API never sees the suffix.
So `MiniMax-M3.1-Flash[1m]` is a real choice, and the plain
`MiniMax-M3.1-Flash` runs with the declared window.

The API rejects a `[512k]` suffix outright: `400 invalid params, unknown model
'MiniMax-M3.1-Flash[512k]'`. The 512K window is not a model, it is the number
in `CLAUDE_CODE_MAX_CONTEXT_TOKENS`. That is why the picker offers the plain
id next to the `[1m]` one, and why the declared window is the smaller of the
two: pick the plain id for 512K, pick the `[1m]` id for 1M.

A 1M session still compacts at the declared compaction point, which is set for
the 512K window. Raise `CLAUDE_CODE_AUTO_COMPACT_WINDOW` in
`~/.claude/settings.json` to `800000` if you want a 1M session to run longer
before it compacts.

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

On Windows the same set lives under `%USERPROFILE%`, with `.cmd` and `.py`
where the shell scripts are: `mm.cmd`, `api-key.py`, `statusline.cmd`,
`minimax-sync.cmd` and `minimax-sync-daily.cmd`.

Nothing in `~/.claude/settings.json` holds the key: Claude Code reads it through
`apiKeyHelper`, which calls `~/.claude/api-key.sh` (or `api-key.py` on Windows).

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

On Windows, remove the scheduled task with:

```powershell
schtasks /Delete /TN "MiniMax Code Model Sync" /F
Remove-Item -Recurse -Force $env:USERPROFILE\.minimax-tools
Remove-Item -Force $env:USERPROFILE\.local\bin\mm.cmd
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
