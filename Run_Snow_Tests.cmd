@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
for %%T in (mechanics_checks jump_checks party_climb_checks) do (
 "%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 120 --script res://tests/snow/%%T.gd
 if errorlevel 1 exit /b 1
)
"%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/snow/mechanics_checks.gd -- --restore-fixture
exit /b %errorlevel%
