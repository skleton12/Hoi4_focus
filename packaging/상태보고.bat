@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Report-ModState.ps1"
if exist "%~dp0mod-state.txt" notepad "%~dp0mod-state.txt"
pause
