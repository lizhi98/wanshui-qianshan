@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --editor --path "%~dp0."
