<#
.SYNOPSIS
  MiniMax Code setup, for Windows.

.DESCRIPTION
  Installs the MiniMax profile into Claude Code, points Claude Code at
  MiniMax's API, puts the launcher on your PATH, installs the shared mods
  and schedules a daily model sync.

  Nothing here touches the Claude Code binary. Everything already in
  ~/.claude/settings.json is kept: hooks, permissions and plugins stay as
  they are, and the files this setup replaces are kept as .bak copies.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
  .\install.ps1 -ApiKey "sk-..." -NonInteractive
#>

[CmdletBinding()]
param(
  # The MiniMax API key. When it is left out the installer looks at
  # MINIMAX_API_KEY, then at the key Claude Code already uses, then asks.
  [string]$ApiKey,

  # Never prompt. Everything has to come from the environment or a parameter.
  [switch]$NonInteractive,

  # Do not run the model sync at the end.
  [switch]$SkipSync,

  # Do not schedule the daily model sync.
  [switch]$SkipSchedule
)

$ErrorActionPreference = 'Stop'

$Here = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Tools = Join-Path $HOME '.minimax-tools'
$KeyFile = Join-Path $HOME '.config\minimax\api_key'
$BinDir = Join-Path $HOME '.local\bin'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if ($env:CLAUDE_CONFIG_DIR) {
  $ClaudeDir = $env:CLAUDE_CONFIG_DIR
} else {
  $ClaudeDir = Join-Path $HOME '.claude'
}

function Say($text) { Write-Host ''; Write-Host $text }
function Info($text) { Write-Host "  $text" }
function Warn($text) { Write-Host "  ! $text" -ForegroundColor Yellow }

# --- 1. prerequisites ------------------------------------------------------

Say 'Checking what is already here'

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
  $python = (Get-Command py -ErrorAction SilentlyContinue).Source
  if ($python) { $python = "$python -3" }
}
if (-not $python) {
  Write-Error 'python 3.9 or newer is required. Install it from python.org and run this again.'
  exit 1
}
Info "python $python"

$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) {
  $found = cmd /c 'where claude.cmd 2>nul'
  if ($found) { $claude = ($found -split "`r?`n")[0].Trim() }
}
if (-not $claude) {
  Say 'Claude Code is not installed'
  Info 'It installs with: npm install -g @anthropic-ai/claude-code'
  if (-not $NonInteractive) {
    $answer = Read-Host 'Install it now? [y/N]'
    if ($answer -match '^[Yy]') {
      npm install -g @anthropic-ai/claude-code
      $claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
    }
  }
}
if (-not $claude) {
  Write-Error 'Install Claude Code first, then run this again.'
  exit 1
}
Info "claude $claude"

# --- 2. the MiniMax key ----------------------------------------------------

Say 'The MiniMax key'

function Get-KeyFromSettings {
  # The key Claude Code already uses, when there is one.
  $settings = Join-Path $ClaudeDir 'settings.json'
  if (-not (Test-Path $settings)) { return '' }
  try {
    $json = Get-Content -Raw -Path $settings | ConvertFrom-Json
    if ($json.env.ANTHROPIC_AUTH_TOKEN) { return $json.env.ANTHROPIC_AUTH_TOKEN }
    if ($json.env.ANTHROPIC_API_KEY) { return $json.env.ANTHROPIC_API_KEY }
  } catch {
    return ''
  }
  return ''
}

$key = $ApiKey
if (-not $key) { $key = $env:MINIMAX_API_KEY }
if (-not $key) { $key = Get-KeyFromSettings }

if (-not $key) {
  if ($NonInteractive) {
    Write-Error 'no MiniMax key given. Pass -ApiKey or set MINIMAX_API_KEY.'
    exit 1
  }
  $key = Read-Host 'MiniMax API key (platform.minimax.io -> API keys)'
}

if (-not $key) {
  Write-Error 'no key given, stopping'
  exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $KeyFile) | Out-Null
# no trailing newline: the file holds the key and nothing else
[System.IO.File]::WriteAllText($KeyFile, $key.Trim())
Info "stored in $KeyFile"

# --- 3. the toolkit and the profile ---------------------------------------

Say 'Installing the toolkit'

New-Item -ItemType Directory -Force -Path $Tools | Out-Null
Copy-Item -Recurse -Force (Join-Path $Here 'toolkit\*') $Tools
Info $Tools

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
foreach ($file in @('CLAUDE.md', 'api-key.py', 'api-key.sh', 'statusline.py', 'statusline.sh', 'statusline.cmd')) {
  $source = Join-Path $Here "profile\$file"
  if (-not (Test-Path $source)) { continue }
  $target = Join-Path $ClaudeDir $file
  if (Test-Path $target) {
    Copy-Item $target "$target.$Stamp.bak"
  }
  Copy-Item -Force $source $target
}
Info "$ClaudeDir (previous files kept as .bak)"

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
Copy-Item -Force (Join-Path $Here 'profile\mm.cmd') (Join-Path $BinDir 'mm.cmd')
if (Test-Path (Join-Path $Here 'profile\mm')) {
  Copy-Item -Force (Join-Path $Here 'profile\mm') (Join-Path $BinDir 'mm')
}
Info (Join-Path $BinDir 'mm.cmd')

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
if ($userPath -notlike "*$BinDir*") {
  $newPath = if ($userPath) { "$BinDir;$userPath" } else { $BinDir }
  [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
  Info "added $BinDir to your PATH"
}
if ($env:Path -notlike "*$BinDir*") { $env:Path = "$BinDir;$env:Path" }

# --- 4. the shared mods (rules, hooks, skills, themes) ---------------------

Say 'Installing the shared mods'
& (Join-Path $Here 'toolkit\install-mods.ps1')

# --- 5. the settings -------------------------------------------------------

Say 'Pointing Claude Code at MiniMax'

$settingsPath = Join-Path $ClaudeDir 'settings.json'
if (Test-Path $settingsPath) {
  Copy-Item $settingsPath "$settingsPath.$Stamp.bak"
  Info "settings kept as $settingsPath.$Stamp.bak"
}

$patch = Join-Path $Here 'setup\patch-settings.py'
& python $patch $settingsPath (Join-Path $Tools 'models-policy.json')
if ($LASTEXITCODE -ne 0) {
  Write-Error 'the settings could not be patched'
  exit 1
}

# --- 6. the daily sync -----------------------------------------------------

if (-not $SkipSchedule) {
  Say 'Scheduling the daily model sync'
  $taskName = 'MiniMax Code Model Sync'
  $daily = Join-Path $Tools 'minimax-sync-daily.cmd'
  $taskRun = if ($daily -match '\s') { '"' + $daily + '"' } else { $daily }
  & schtasks /Create /TN $taskName /TR $taskRun /SC DAILY /ST 07:23 /F | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Info "scheduled task '$taskName', every morning at 07:23"
  } else {
    Warn "the scheduled task could not be created; run the sync by hand with $Tools\minimax-sync.cmd"
  }
}

# --- 7. one sync now, so everything is right from the first minute ---------

if (-not $SkipSync) {
  Say 'Reading the model list from MiniMax'
  & (Join-Path $Tools 'minimax-sync.cmd')
  if ($LASTEXITCODE -ne 0) {
    Warn 'the sync could not reach MiniMax; run it again later'
  }
}

Say 'Done'
Info 'start it with:   mm'
Info 'check it with:   mm -p "who are you?" --output-format json'
Info 'keep it current: %USERPROFILE%\.minimax-tools\minimax-sync.cmd'
Info 'read more:       %USERPROFILE%\.minimax-tools\README.md'
