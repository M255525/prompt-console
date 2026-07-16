@echo off
title Prompt Console - CRISPE
rem PromptConsole.exe blocked by Smart App Control? Use this instead.
cd /d "%~dp0.."
python launcher.py
if errorlevel 1 (
  echo.
  echo Python launch failed.
  echo Alternative: open index.html in the Prompt folder with your browser.
  echo.
  pause
)
