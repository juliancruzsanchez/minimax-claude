@echo off
rem The Windows entry point for minimax-sync.
rem
rem   minimax-sync.cmd --check
rem
rem The sync itself is a Python script; this runs it with the interpreter on
rem PATH and passes every argument through.
setlocal
python "%~dp0minimax-sync" %*
endlocal
