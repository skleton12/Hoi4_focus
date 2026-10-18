@echo off
if not exist "%~dp0Report-ModState.ps1" (
  echo.
  echo [!] Extract the zip first.
  echo     Right-click the zip - Extract All - then run this file from the extracted folder.
  echo.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Report-ModState.ps1"
if exist "%~dp0mod-state.txt" notepad "%~dp0mod-state.txt"
pause
