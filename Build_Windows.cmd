@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --editor --import
if errorlevel 1 exit /b 1
if not exist "%~dp0..\Windows" mkdir "%~dp0..\Windows"
"%DEMO_ENGINE%" --headless --path "%~dp0." --export-release "Windows Desktop" "%~dp0..\Windows\WanShuiQianShan_V4_1_5.exe"
