@echo off
set "DEMO_ENGINE="
if defined GODOT_PATH if exist "%GODOT_PATH%" set "DEMO_ENGINE=%GODOT_PATH%"
if not defined DEMO_ENGINE if exist "%~dp0..\..\Godot_4.6\Godot_v4.6-stable_win64_console.exe" set "DEMO_ENGINE=%~dp0..\..\Godot_4.6\Godot_v4.6-stable_win64_console.exe"
if not defined DEMO_ENGINE for %%G in (godot.exe godot4.exe Godot_v4.6-stable_win64_console.exe) do for /f "delims=" %%P in ('where %%G 2^>nul') do if not defined DEMO_ENGINE set "DEMO_ENGINE=%%P"
if not defined DEMO_ENGINE (
 echo Godot 4.6 not found. Set GODOT_PATH to your Godot executable.
 exit /b 1
)
exit /b 0
