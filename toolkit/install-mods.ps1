# Install the shared agent mods into Claude Code, on Windows.
#
#   ~/.minimax-tools/mods/agent-toolkit   the bundle: rules, hooks, themes
#   ~/.minimax-tools/skills                the shared skill store
#
# The skills are copied into ~/.agents/skills, the store every agent on the
# machine reads, and linked into Claude Code's own skills directory. The
# bundle carries both plugin manifests, so the same folder works for Claude
# Code and for MiniMax Code.
#
# Directories are linked with junctions, which Windows allows without admin
# rights, so a skill written once is shared by every agent on the machine.
#
# Running it again is safe: every step replaces what it wrote before.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Tools = Join-Path $HOME '.minimax-tools'
$Bundle = Join-Path $Tools 'mods\agent-toolkit'
if ($env:CLAUDE_CONFIG_DIR) {
  $ClaudeDir = $env:CLAUDE_CONFIG_DIR
} else {
  $ClaudeDir = Join-Path $HOME '.claude'
}
$Store = Join-Path $HOME '.agents\skills'

if (-not (Test-Path $Bundle)) {
  throw "no bundle at $Bundle"
}

function Remove-Link([string]$Path) {
  # rmdir on a junction takes the link off and leaves the target alone.
  if (Test-Path $Path) {
    cmd /c rmdir "$Path" 2>$null | Out-Null
    if (Test-Path $Path) {
      Remove-Item -Force -Recurse $Path -ErrorAction SilentlyContinue
    }
  }
}

# --- the shared skill store
New-Item -ItemType Directory -Force -Path $Store | Out-Null
$ToolkitSkills = Join-Path $Tools 'skills'
if (Test-Path $ToolkitSkills) {
  foreach ($skill in Get-ChildItem -Directory $ToolkitSkills) {
    $target = Join-Path $Store $skill.Name
    if (-not (Test-Path $target)) {
      Copy-Item -Recurse $skill.FullName $target
    }
  }
}

# --- Claude Code reads its own skills directory
$ClaudeSkills = Join-Path $ClaudeDir 'skills'
New-Item -ItemType Directory -Force -Path $ClaudeSkills | Out-Null
foreach ($skill in Get-ChildItem -Directory $Store -ErrorAction SilentlyContinue) {
  $target = Join-Path $ClaudeSkills $skill.Name
  if (-not (Test-Path $target)) {
    New-Item -ItemType Junction -Path $target -Target $skill.FullName | Out-Null
  }
}

# --- the bundle itself, as a skills-dir plugin
Remove-Link (Join-Path $ClaudeSkills 'agent-toolkit')
New-Item -ItemType Junction -Path (Join-Path $ClaudeSkills 'agent-toolkit') -Target $Bundle | Out-Null

# --- the themes, so /theme lists them next to the built-in ones
$ThemeDir = Join-Path $ClaudeDir 'themes'
$BundleThemes = Join-Path $Bundle 'themes'
if (Test-Path $BundleThemes) {
  New-Item -ItemType Directory -Force -Path $ThemeDir | Out-Null
  foreach ($theme in Get-ChildItem -Filter '*.json' $BundleThemes) {
    Copy-Item -Force $theme.FullName (Join-Path $ThemeDir $theme.Name)
  }
}

# --- the hooks, with the Windows commands in them
$HookDir = Join-Path $Bundle 'hooks'
$HookConfig = Join-Path $HookDir 'hooks.json'
if (Test-Path $HookDir) {
  $python = (Get-Command python -ErrorAction SilentlyContinue).Source
  $node = (Get-Command node -ErrorAction SilentlyContinue).Source
  $hook = @{
    hooks = @{
      SessionStart = @(
        @{
          matcher = 'startup|resume|clear|compact|fork'
          hooks = @(
            @{
              type = 'command'
              command = "python `"$($HookDir -replace '\\','/')/session-context.py`""
              timeout = 10
              statusMessage = 'Loading file index...'
            }
          )
        }
      )
      PostToolUse = @(
        @{
          hooks = @(
            @{
              type = 'command'
              command = "node `"$($HookDir -replace '\\','/')/clauditor-post-tool-use.mjs`""
            }
          )
        }
      )
    }
  }
  if ($python) {
    $hook | ConvertTo-Json -Depth 10 | Set-Content -Path $HookConfig -Encoding utf8
  }
}

Write-Output 'installed:'
Write-Output "  claude  $ClaudeSkills\agent-toolkit"
Write-Output "  themes  $ThemeDir"
$count = (Get-ChildItem -Directory $Store -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Output "  skills  $Store (shared store, $count skills)"
