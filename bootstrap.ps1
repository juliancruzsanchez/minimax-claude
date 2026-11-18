<#
.SYNOPSIS
  MiniMax Code, installed in one line, on Windows.

.DESCRIPTION
  Fetches the repository, then runs its installer. Safe to run twice.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
#>

[CmdletBinding()]
param(
  [string]$Repo = 'juliancruzsanchez/minimax-claude',
  [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'

$workdir = Join-Path $env:TEMP ('minimax-code-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $workdir | Out-Null

Write-Host "MiniMax Code: fetching $Repo"
$zip = Join-Path $workdir 'repo.zip'
try {
  Invoke-WebRequest -Uri "https://codeload.github.com/$Repo/zip/refs/heads/$Branch" -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath (Join-Path $workdir 'src') -Force
} catch {
  Write-Error "could not download $Repo"
  exit 1
}

$source = Get-ChildItem -Directory (Join-Path $workdir 'src') | Select-Object -First 1
if (-not $source) {
  Write-Error 'the download did not contain the setup'
  exit 1
}

$installer = Join-Path $source.FullName 'install.ps1'
if (-not (Test-Path $installer)) {
  Write-Error 'the download did not contain install.ps1'
  exit 1
}

& $installer @args
