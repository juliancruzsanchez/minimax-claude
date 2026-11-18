@echo off
rem MiniMax Code: Claude Code's terminal agent running on MiniMax models.
rem
rem The Windows port of profile/mm. The same program as `claude`, pointed at
rem MiniMax's API, with the key in %USERPROFILE%\.config\minimax\api_key or
rem in MINIMAX_API_KEY.
setlocal

set "CLAUDE_BIN=%MINIMAX_CLAUDE_BIN%"
if not defined CLAUDE_BIN if exist "%USERPROFILE%\.local\bin\claude.exe" set "CLAUDE_BIN=%USERPROFILE%\.local\bin\claude.exe"
if not defined CLAUDE_BIN for /f "delims=" %%i in ('where claude.cmd 2^>nul') do (if not defined CLAUDE_BIN set "CLAUDE_BIN=%%i")
if not defined CLAUDE_BIN for /f "delims=" %%i in ('where claude.exe 2^>nul') do (if not defined CLAUDE_BIN set "CLAUDE_BIN=%%i")
if not defined CLAUDE_BIN (
  echo Claude Code is not installed. Install it with:
  echo   npm install -g @anthropic-ai/claude-code
  exit /b 1
)

if not defined CLAUDE_CONFIG_DIR set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude"

if not defined ANTHROPIC_BASE_URL set "ANTHROPIC_BASE_URL=https://api.minimax.io/anthropic"
if not defined ANTHROPIC_MODEL set "ANTHROPIC_MODEL=MiniMax-M3.1-Flash[1m]"
if not defined ANTHROPIC_DEFAULT_OPUS_MODEL set "ANTHROPIC_DEFAULT_OPUS_MODEL=MiniMax-M3"
if not defined ANTHROPIC_DEFAULT_SONNET_MODEL set "ANTHROPIC_DEFAULT_SONNET_MODEL=MiniMax-M3.1-Flash[1m]"
if not defined ANTHROPIC_DEFAULT_HAIKU_MODEL set "ANTHROPIC_DEFAULT_HAIKU_MODEL=MiniMax-M3.1-Flash[1m]"
if not defined CLAUDE_CODE_MAX_CONTEXT_TOKENS set "CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000"
if not defined CLAUDE_CODE_AUTO_COMPACT_WINDOW set "CLAUDE_CODE_AUTO_COMPACT_WINDOW=800000"

rem the key, when one is on disk
set "KEYFILE=%USERPROFILE%\.config\minimax\api_key"
if not defined ANTHROPIC_AUTH_TOKEN if exist "%KEYFILE%" set /p ANTHROPIC_AUTH_TOKEN=<"%KEYFILE%"

"%CLAUDE_BIN%" %*
endlocal
