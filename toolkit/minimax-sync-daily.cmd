@echo off
rem The daily model sync, as the scheduled task runs it.
rem
rem The output goes to sync.log next to the toolkit, the way the cron job on
rem Linux writes to it.
setlocal
python "%~dp0minimax-sync" >> "%~dp0sync.log" 2>&1
endlocal
