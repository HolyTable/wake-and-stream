@echo off
rem wake-and-stream - called from the Mac via SSH ("pc release" / menu "End work session").
rem Hands the user session back to the PC screen, unlocked - no matter whether it is still connected
rem via remote desktop or already disconnected. The session is found through explorer.exe, which
rem only runs in the logged-on user's session.
rem Optional: if the file turn-monitors-on.flag exists next to this script, the monitors are switched
rem back on afterwards (by default they stay off until someone touches mouse or keyboard).
set session=
for /f %%s in ('powershell -NoProfile -Command "(Get-Process explorer -ErrorAction SilentlyContinue | Select-Object -First 1).SessionId"') do set session=%%s
if "%session%"=="" (
  echo No user session found.
  exit /b 1
)
%windir%\System32\tscon.exe %session% /dest:console

if exist "%~dp0turn-monitors-on.flag" (
  rem wait 2 seconds (ping instead of timeout: timeout fails when run via SSH without a keyboard)
  ping -n 3 127.0.0.1 >nul
  "%~dp0PsExec64.exe" -accepteula -nobanner -i %session% -s -d powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0monitors-on.ps1" >nul 2>&1
)
exit /b 0
