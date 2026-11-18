@echo off
rem The status line Claude Code runs, on Windows.
rem
rem Reads the Claude Code payload on stdin and prints the MiniMax row.
rem The Orca bridge is called first, from statusline.py, when it is installed.
setlocal
python "%~dp0statusline.py"
endlocal
